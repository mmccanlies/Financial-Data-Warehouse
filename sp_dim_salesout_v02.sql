USE [sandbox_mike]
GO

/****** Object:  StoredProcedure [dbo].[sp_dim_salesout]    Script Date: 2/27/2017 11:32:28 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************************************
**                                    sp_dim_salesout
**
** dependencies:    ns_custom_sales_out, salesout_dim, xrf_index 
**
** Load dim_salesout
** created:  02/26/2017   mmccanlies         
** revised:  3/07/2017      "            Revised to use source views instead of source tables 
**************************************************************************************************/
ALTER PROCEDURE [dbo].[sp_dim_salesout]
(
    @Rebuild   bit = 1,       -- 1 = Truncate and rebuild
    @Debug     bit = 0        -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_dim_salesout '
    DECLARE @ErrMsg   nvarchar(2000) = N'**** Error occurred in '+@ProcName+' - '	
    DECLARE @EntryMsg nvarchar(1000) = N'Starting Procedure '+@ProcName+'  '
    DECLARE @MidMsg   nvarchar(1000) = N'    Procedure '+@ProcName+'  '
    DECLARE @ExitMsg  nvarchar(1000) = N'Exiting Procedure '+@ProcName+'  '
    DECLARE @ExitTxt  nvarchar(1500)
    DECLARE @currentTime nvarchar(100)
    SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime())
    EXEC [sp_message_handler] @currentTime, @EntryMsg, @ProcName ;

BEGIN TRY
    BEGIN TRANSACTION
        IF @Rebuild = 1
            TRUNCATE TABLE [dim_salesout]

        -- Major Code Sections --
        INSERT INTO [dim_salesout]
        ( salesOutId, salesOutLine, outDate, outPurchaseDate, outSerialNo, outStatus, outItemId, outQty, outAmt, outListPrice, 
          outSoldThruReseller, outReseller, outResllerPONo, outCustomerNo, outCompanyName, outAddr1, outAddr2, outAddr3, outAddr4, 
          outCity, outState, outZip, outProvince, outCounty, outCountry, outEmail, outPhone, outSFPartnerNo, outSalesRegion, 
          outSalesOrderNo, outSalesOrder, outExternalId )

        SELECT DISTINCT
          ISNULL(CONVERT(int,[vw_custom_sales_out].[internalId]),-1) AS 'salesOutId'
        , ISNULL(CONVERT(int,CONVERT(numeric,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_original_line_num])),1) AS 'salesOutLine'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_date] AS 'outDate'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_purchasedate] AS 'outPurchaseDate'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_serial_number] AS 'outSerialNo'
        , ISNULL(CONVERT(int,CONVERT(numeric,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_status])),1) AS 'outStatus'
        , ISNULL(CONVERT(int,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_item]),-1) AS 'outItemId'
        , ISNULL(CONVERT(int,CONVERT(numeric,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_quantity])),-1) AS 'outQty'
        , ISNULL(CONVERT(money,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_amount]),0) AS 'outAmt'
        , ISNULL(CONVERT(money,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_list_price]),0) AS 'outListPrice'

        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_sold_thru_reseller] AS 'outSoldThruReseller'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_strategic_reseller] AS 'outReseller'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_reseller_po_number] AS 'outResllerPONo'
        , ISNULL(CONVERT(int,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_customer_number]),-1) AS 'outCustomerNo'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_company_name] AS 'outCompanyName'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_address_1] AS 'outAddr1'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_address_2] AS 'outAddr2'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_address_3] AS 'outAddr3'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_address_4] AS 'outAddr4'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_city] AS 'outCity'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_state] AS 'outState'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_zip] AS 'outZip'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_province] AS 'outProvince'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_county] AS 'outCounty'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_country] AS 'outCountry'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_email] AS 'outEmail'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_phone] AS 'outPhone'
        , [vw_custom_sales_out].[customFieldList-custrecord_sales_out_sf_partner_number] AS 'outSFPartnerNo'

        , ISNULL(CONVERT(int,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_sales_region]),-1) AS 'outSalesRegion'
        , ISNULL(CONVERT(int,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_original_trans]),-1) AS 'outSalesOrderNo'
        , ISNULL(CONVERT(int,[vw_custom_sales_out].[customFieldList-custrecord_original_sales_order]),-1) AS 'outSalesOrder'
        , [vw_custom_sales_out].[externalId] AS 'outExternalId'
        FROM [vw_custom_sales_out]                                                      --268634
        RIGHT OUTER JOIN [xrf_index] ON [xrf_index].[salesOutId] = ISNULL(CONVERT(int,[vw_custom_sales_out].[internalId]),-1)
                     AND [xrf_index].[salesOutLineId] = ISNULL(TRY_CONVERT(int,[vw_custom_sales_out].[customFieldList-custrecord_sales_out_original_line_num]),1)
        ORDER BY 1,2
        ;
        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        --  Update reseller in salesout_dim
        UPDATE [dim_salesout] SET 
          [outReseller]         = [xrf_legacy_reseller].[resellerName]
        , [outResllerPONo]      = [xrf_legacy_reseller].[poNo]
        , [outSoldThruReseller] = 1
        FROM [xrf_index]
        JOIN [xrf_legacy_reseller] ON [xrf_legacy_reseller].[baseSubscriptionId] = [xrf_index].[baseSubscriptionId]
        JOIN [dim_salesout] ON [dim_salesout].[salesOutId] = [xrf_index].[salesOutId];

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @ExitMsg
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        COMMIT TRANSACTION
        -- RETURN SUCCESS --
        RETURN (0) 

END TRY

BEGIN CATCH  
    DECLARE @ErrMessage  nvarchar(2048);  
    DECLARE @ErrSeverity nvarchar(10);  
    DECLARE @ErrState    nvarchar(10);  
    SELECT  @ErrMessage  = @ErrMsg+SUBSTRING(ERROR_MESSAGE(),1,1950)+' ',  
            @ErrSeverity = CONVERT(nvarchar, ERROR_SEVERITY())+' ',
            @ErrState    = CONVERT(nvarchar, ERROR_STATE())+' '  ; 

    SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
           @ErrMsg = @ErrMessage+@ErrSeverity+@ErrState ;
    EXEC [sp_message_handler] @currentTime, @ErrMsg, @ProcName ;
    ROLLBACK
    RAISERROR ( @ErrMessage, @ErrSeverity, @ErrState );  
END CATCH;  


GO


