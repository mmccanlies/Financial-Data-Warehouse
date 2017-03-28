USE [sandbox_mike]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
/*************************************************************************************************
**                                    sp_dim_salesorder
** 
** Load salesorder dimension table
** 
** dependencies:  dim_subscription, dim_salesorder, vw_salesOrder, vw_salesOrder_itemList, xrf_index
** 
** created:  2/26/2017   mmccanlies 
** revised:  3/07/2017      "            Revised to use source views instead of source tables 
**************************************************************************************************/
ALTER PROCEDURE [sp_dim_salesorder]
(
    @Rebuild   bit = 1,         -- 1 = Truncate and rebuild
    @Debug     bit = 0          -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_dim_salesorder '
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
            TRUNCATE TABLE [dim_salesorder] ;

        -- Major Code Sections --
        INSERT INTO [dim_salesorder]
        ( salesOrderId, salesOrderLine, salesOrderNo, xrfIndexId, soTermYrs, soTermMos, soTermDays, soListPrice, soListPricePerYr, soListPricePerMo, soListPricePerDay,
          stdDiscount, stdDiscAmtYrs, stdDiscAmtMos, stdDiscAmtDays, ornDiscount, ornDiscAmtYrs, ornDiscAmtMos, ornDiscAmtDays, nsdDiscount, nsdDiscAmtYrs, nsdDiscAmtMos, nsdDiscAmtDays,
          soItemId, soSkuNo, soLocName, soDescription, soClassName, soClassId, soBookingDate, soCustomerPONo, soServiceStartDate, soServiceEndDate, 
          soServiceYrs, soServiceMos, soServiceDays, soQty, soUnits, soAmount, soPriceType, soCustomerDisc, soRequestDate,  soQtyBilled, soQtyFulfilled, 
          soServiceRenewal, soDeptName, soRevRecStartDate, soRevRecEndDate, soRevRecTermInMonths, soIsClosed, soLineId )

        SELECT DISTINCT 
          ISNULL(CONVERT(int,[vw_salesOrder].[internalId]),-1) AS 'salesOrderId'
        , ISNULL(TRY_CONVERT(int,[vw_salesOrder_itemlist].[line]),1) AS 'salesOrderLine'
        , [vw_salesOrder].[tranId] AS 'salesOrderNo'
        , [xrf_index].[xrfIndexId] AS 'xrfIndexId'
        , ISNULL(CONVERT(int,[vw_salesOrder_itemList].[customFieldList-custcol_term]),0)            AS 'soTermYrs'
        , ISNULL(CONVERT(int,[vw_salesOrder_itemList].[customFieldList-custcol_term]),0)*12         AS 'soTermMos'
        , ISNULL(CONVERT(int,[vw_salesOrder_itemList].[customFieldList-custcol_term]),0)*365        AS 'soTermDays'

        , CONVERT(money,[vw_salesOrder_ItemList].[customFieldList-custcol_custlistprice])   AS 'soListPrice'
        , CASE WHEN CONVERT(int,[vw_salesOrder_itemList].[customFieldList-custcol_term]) = 0
            THEN 0 
          ELSE CONVERT(money,[vw_salesOrder_ItemList].[customFieldList-custcol_custlistprice]/(CONVERT(int,[vw_salesOrder_itemList].[customFieldList-custcol_term])))
          END AS 'soListPricePerYr'
        , CASE WHEN CONVERT(int,[vw_salesOrder_itemList].[customFieldList-custcol_term])*12.0 = 0
            THEN 0 
          ELSE CONVERT(money,[vw_salesOrder_ItemList].[customFieldList-custcol_custlistprice]/(CONVERT(int,[vw_salesOrder_itemList].[customFieldList-custcol_term])*12.0))
          END AS 'soListPricePerMo'
        , CASE WHEN CONVERT(int,[vw_salesOrder_itemList].[customFieldList-custcol_term])*365.0 = 0
            THEN 0 
          ELSE CONVERT(money,[vw_salesOrder_ItemList].[customFieldList-custcol_custlistprice]/(CONVERT(int,[vw_salesOrder_itemList].[customFieldList-custcol_term])*365.0))
          END AS 'soListPricePerDay'

        , NULL AS 'StdDiscount'
        , NULL AS 'StdDiscAmtYrs'
        , NULL AS 'StdDiscAmtMos'
        , NULL AS 'StdDiscAmtDays'
        , NULL AS 'OrnDiscount'
        , NULL AS 'OrnDiscAmtYrs'
        , NULL AS 'OrnDiscAmtMos'
        , NULL AS 'OrnDiscAmtDays'
        , NULL AS 'NsdDiscount'
        , NULL AS 'NsdDiscAmtYrs'
        , NULL AS 'NsdDiscAmtMos'
        , NULL AS 'NsdDiscAmtDays'

        , ISNULL(CONVERT(int,[vw_salesOrder_itemList].[item-internalId]),-1) AS 'soItemId'
        , [vw_salesOrder_itemList].[item-name] AS 'soSkuNo' 
        , [vw_salesOrder_itemList].[location-name] AS 'soLocName' 
        , [vw_salesOrder_itemList].[description] AS 'soDescription' 
        , [vw_salesOrder_ItemList].[class-name] AS 'soClassName'
        , ISNULL(CONVERT(int,[vw_salesOrder_ItemList].[class-internalId]),-1) AS 'soClassId'
        , [vw_salesOrder].[customFieldList-custbody_order_date] AS 'soBookingDate'
        , [vw_salesOrder].[otherRefNum] AS 'soCustomerPONo'
        , [vw_salesOrder_itemList].[customFieldList-custcol_service_start_date] AS 'soServiceStartDate' 
        , [vw_salesOrder_itemList].[customFieldList-custcol_service_end_date] AS 'soServiceEndDate' 
        , DATEDIFF(YY, [customFieldList-custcol_service_start_date], [customFieldList-custcol_service_end_date]) AS 'soServiceYrs'
        , DATEDIFF(MM, [customFieldList-custcol_service_start_date], [customFieldList-custcol_service_end_date]) AS 'soServiceMos'
        , DATEDIFF(DD, [customFieldList-custcol_service_start_date], [customFieldList-custcol_service_end_date]) AS 'soServiceDays'
        , CASE WHEN ISNUMERIC(SUBSTRING([vw_salesOrder_itemList].[units-name],1,1)) = 1
            THEN TRY_CAST(SUBSTRING([vw_salesOrder_itemList].[units-name],1,1) AS numeric)
            ELSE 1
          END * CONVERT(numeric,[vw_salesOrder_itemList].[quantity]) AS 'soQty'
        , CASE WHEN ISNUMERIC(SUBSTRING([vw_salesOrder_itemList].[units-name],1,1)) = 1
            THEN CASE SUBSTRING([vw_salesOrder_itemList].[units-name],2,1)
                   WHEN 'Y' THEN 'YR'
                   WHEN 'Q' THEN 'QTR'
                   WHEN 'M' THEN 'MO'
                   ELSE SUBSTRING([vw_salesOrder_itemList].[units-name],2,LEN([vw_salesOrder_itemList].[units-name]))
                 END
            ELSE [vw_salesOrder_itemList].[units-name]
          END AS 'soUnits'

        , [vw_salesOrder_itemList].[amount] AS 'soAmount' 
        , [vw_salesOrder_itemList].[price-name] AS 'soPriceType' 
        , [vw_salesOrder_itemList].[customFieldList-custcolcustcolcustcol_custactdiscount]/100.0 AS 'soCustomerDisc' 
        , [vw_salesOrder_itemList].[customFieldList-custcol_request_date] AS 'soRequestDate' 
        , [vw_salesOrder_itemList].[quantityBilled] AS 'soQtyBilled' 
        , [vw_salesOrder_itemList].[quantityFulfilled] AS 'soQtyFulfilled' 
        , [vw_salesOrder_itemList].[customFieldList-custcol_service_renewal] AS 'soServiceRenewal' 
        , [vw_salesOrder_itemList].[department-name] AS 'soDeptName' 
        , [vw_salesOrder_itemList].[revRecStartDate] AS 'soRevRecStartDate' 
        , [vw_salesOrder_itemList].[revRecEndDate] AS 'soRevRecEndDate' 
        , [vw_salesOrder_itemList].[revRecTermInMonths] AS 'soRevRecTermInMonths' 
        , [vw_salesOrder_itemList].[isClosed] AS 'soIsClosed' 
        , ISNULL(TRY_CONVERT(numeric,[vw_salesOrder_itemlist].[customFieldList-custcol_line_id]),-1) AS 'soLineId'
        FROM [vw_salesOrder] 
        JOIN [vw_salesOrder_itemList] ON [vw_salesOrder_itemList].[internalId] = [vw_salesOrder].[internalId]
        RIGHT OUTER JOIN [xrf_index] ON [xrf_index].[salesOrderId] = ISNULL([vw_salesOrder].[internalId],-1)
                AND [xrf_index].[salesOrderItemLineId] = ISNULL(TRY_CONVERT(int,[vw_salesOrder_itemlist].[line]),1)
        ORDER BY ISNULL(CONVERT(int,[vw_salesOrder].[internalId]),-1) 
               , ISNULL(TRY_CONVERT(int,[vw_salesOrder_itemlist].[line]),1)  ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

       UPDATE [dim_salesorder] SET
          StdDiscount = [dim_subscription].[StdDiscount] 
        , StdDiscAmtYrs  = CONVERT(money,[dim_salesorder].[soListPricePerMo]*[dim_subscription].[StdDiscount]*12.0) 
        , StdDiscAmtMos  = CONVERT(money,[dim_salesorder].[soListPricePerMo]*[dim_subscription].[StdDiscount])      
        , StdDiscAmtDays = CONVERT(money,[dim_salesorder].[soListPricePerDay]*[dim_subscription].[StdDiscount])     

        , ORNDiscount = [dim_subscription].[ORNDiscount] 
        , ORNDiscAmtYrs  = CONVERT(money,[dim_salesorder].[soListPricePerMo]*[dim_subscription].[ORNDiscount]*12.0) 
        , ORNDiscAmtMos  = CONVERT(money,[dim_salesorder].[soListPricePerMo]*[dim_subscription].[ORNDiscount])      
        , ORNDiscAmtDays = CONVERT(money,[dim_salesorder].[soListPricePerDay]*[dim_subscription].[ORNDiscount])     

        , NSDDiscount = [dim_subscription].[NSDDiscount] 
        , NSDDiscAmtYrs  = CONVERT(money,( 1-[dim_subscription].[StdDiscount]-[dim_subscription].[ORNDiscount])*[dim_salesorder].[soListPricePerMo]*[dim_subscription].[NSDDiscount]*12) 
        , NSDDiscAmtMos  = CONVERT(money,( 1-[dim_subscription].[StdDiscount]-[dim_subscription].[ORNDiscount])*[dim_salesorder].[soListPricePerMo]*[dim_subscription].[NSDDiscount] )   
        , NSDDiscAmtDays = CONVERT(money,( 1-[dim_subscription].[StdDiscount]-[dim_subscription].[ORNDiscount])*[dim_salesorder].[soListPricePerDay]*[dim_subscription].[NSDDiscount])   
        FROM [dim_subscription]
        LEFT JOIN [dim_salesorder] ON [dim_salesorder].[salesOrderId] = [dim_subscription].[salesOrderId] AND [dim_salesorder].[salesOrderLine] = [dim_subscription].[salesOrderLine] ;
 
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
            @ErrState    = CONVERT(nvarchar, ERROR_STATE())+' ' ;  
    
    SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
           @ErrMsg = @ErrMessage+@ErrSeverity+@ErrState ;
    EXEC [sp_message_handler] @currentTime, @ErrMsg, @ProcName ;
    ROLLBACK
    RAISERROR ( @ErrMessage, @ErrSeverity, @ErrState );  
END CATCH;  

