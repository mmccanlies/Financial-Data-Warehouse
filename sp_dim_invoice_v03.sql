USE [sandbox_mike]
GO
/****** Object:  StoredProcedure [dbo].[sp_dim_invoice]    Script Date: 2/27/2017 11:53:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
**                                     sp_dim_invoice
** 
** dependencies:    xrf_index, ns_custom_subscription, ns_salesorder, 
**                  ns_salesorder_itemlist, ns_invoice, ns_invoice_itemlist
** 
** Load story or task#: description
** created: 02/27/2017     mmccanlies           
** revised: 03/07/2017        "         Revised to use source views instead of source tables 
**          03/18/2017        "         Fixed the invRate and invAmt to sum the values 
**                                      removed numbers in from of billToCustomerName
**************************************************************************************************/
ALTER PROCEDURE [dbo].[sp_dim_invoice] 
(
    @Rebuild   bit = 1,       -- 1 = Truncate and rebuild
    @Debug     bit = 0        -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_dim_invoice '
    DECLARE @ErrMsg   nvarchar(2000) = N'**** Error occurred in '+@ProcName+' - '	
    DECLARE @EntryMsg nvarchar(1000) = N'Starting Procedure '+@ProcName+'  '
    DECLARE @MidMsg   nvarchar(1000) = N'    Procedure '+@ProcName+'  '
    DECLARE @ExitMsg  nvarchar(1000) = N'Exiting Procedure '+@ProcName+'  '
    DECLARE @ExitTxt  nvarchar(1500)
    DECLARE @currentTime nvarchar(100)
    SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime())
    EXEC [sp_message_handler] @currentTime, @EntryMsg, @ProcName ;

BEGIN TRY
        -- Major Code Sections --
    BEGIN TRANSACTION
        IF @Rebuild =1 
            TRUNCATE TABLE [dim_invoice]

        INSERT INTO [dim_invoice] 
        ( invoiceId, invItemLineId, invItemId, xrfIndexId, invoiceNo, invoiceDate, invCustColTerm, serviceStart, serviceEnd, serviceYrs, serviceMos, serviceDays, 
          orderLine, invClassName, skuNo, invDescription, invLocName, invAmt, invRate, invOrigQty, invAltQty, invUnits, invPriceName, invIncAcct, BillToCustomerId,
          BillToCustomerName, BillToCustomerAddress, billingDate, invAutoSalesOut, invRevRecStartDate, invRevRecEndDate, 
          invRevRecSchedName, subscriptionId, salesOrderItemId )

        SELECT DISTINCT 
          ISNULL(CONVERT(int,[vw_invoice].[internalId]),-1) AS 'invoiceId'
        , ISNULL(CONVERT(int,CONVERT(numeric,[vw_invoice_itemlist].[customFieldList-custcol_line_id])),1) AS 'invItemLineId'
        , ISNULL(CONVERT(int,[vw_invoice_ItemList].[item-internalId]),-1) AS 'invItemId'
        , [xrf_index].[xrfIndexId] AS 'xrfIndexId'
        , [vw_invoice].[tranId] AS 'invoiceNo'
        , [vw_invoice].[tranDate] AS 'invoiceDate'
        , [vw_invoice_itemList].[customFieldList-custcol_term] AS 'invCustColTerm'
        , [vw_invoice_itemList].[customFieldList-custcol_service_start_date] AS 'serviceStart'
        , [vw_invoice_itemList].[customFieldList-custcol_service_end_date] AS 'serviceEnd'
        , DATEDIFF(YY, [vw_invoice_itemList].[customFieldList-custcol_service_start_date], [vw_invoice_itemList].[customFieldList-custcol_service_end_date]) AS 'serviceYrs'
        , DATEDIFF(MM, [vw_invoice_itemList].[customFieldList-custcol_service_start_date], [vw_invoice_itemList].[customFieldList-custcol_service_end_date]) AS 'serviceMos'
        , DATEDIFF(DD, [vw_invoice_itemList].[customFieldList-custcol_service_start_date], [vw_invoice_itemList].[customFieldList-custcol_service_end_date]) AS 'serviceDays'

        , [orderLine] AS 'orderLine'
        , [vw_invoice_itemlist].[class-name]     AS 'invClassName'
        , [vw_invoice_itemlist].[item-name]      AS 'skuNo'
        , [vw_invoice_itemlist].[description]    AS 'invDescription'
        , [vw_invoice_ItemList].[location-name]  AS 'invLocName'
        , 0 AS 'invAmt'
        , 0 AS 'invRate'
        , ISNULL(CONVERT(numeric,[vw_invoice_ItemList].[quantity]),0) AS 'invOrigQty'
        , CASE WHEN ISNUMERIC(SUBSTRING([vw_invoice_itemlist].[units-name],1,1)) = 1
            THEN ISNULL(TRY_CAST(SUBSTRING([vw_invoice_itemlist].[units-name],1,1) AS numeric),0)
            ELSE 1
          END * CONVERT(numeric,[vw_invoice_ItemList].[quantity]) AS 'invAltQty'
        , CASE WHEN ISNUMERIC(SUBSTRING([vw_invoice_itemlist].[units-name],1,1)) = 1
            THEN CASE SUBSTRING([vw_invoice_itemlist].[units-name],2,1)
                   WHEN 'Y' THEN 'YR'
                   WHEN 'Q' THEN 'QTR'
                   WHEN 'M' THEN 'MO'
                   ELSE SUBSTRING([vw_invoice_itemlist].[units-name],2,LEN([vw_invoice_itemlist].[units-name]))
                 END
            ELSE [vw_invoice_itemlist].[units-name]
          END AS 'invUnits'
        , [vw_invoice_itemlist].[price-name] AS 'invPriceName'
        , [vw_invoice_itemlist].[customFieldList-custcol_ava_incomeaccount] AS 'invIncAcct'
        , ISNULL([vw_invoice].[customFieldList-custbody_bill_customer],-1) AS 'BillToCustomerId'
        , CASE WHEN ISNUMERIC(SUBSTRING([vw_invoice].[entity-name],1,CHARINDEX(' ',[vw_invoice].[entity-name]))) = 1
            THEN SUBSTRING([vw_invoice].[entity-name],CHARINDEX(' ',[vw_invoice].[entity-name])+1,LEN([vw_invoice].[entity-name]))
            ELSE [vw_invoice].[entity-name]
          END AS 'BillToCustomerName'
        , ISNULL(REPLACE([vw_invoice].[billAddress],'<br>',' '),'NA')  AS 'BillToCustomerAddress'
        , [vw_invoice].[tranDate] AS 'billingDate'

        , ISNULL([vw_invoice_itemlist].[customFieldList-custcol_auto_sales_out],-1) AS 'invAutoSalesOut'
        , [vw_invoice_itemlist].[revRecStartDate] AS 'invRevRecStartDate'
        , [vw_invoice_itemlist].[revRecEndDate] AS 'invRevRecEndDate'
        , [vw_invoice_itemlist].[revRecSchedule-name] AS 'invRevRecSchedName'
        , [xrf_index].[subscriptionId] AS 'subscriptionId'     --ISNULL(CONVERT(int,[vw_invoice_itemlist].[customFieldList-custcol_subscription]),-1) AS 'subscriptionId'
        , ISNULL(CONVERT(int,[vw_invoice].[createdFrom-internalId]),-1) AS 'salesOrderItemId'
        --INTO [dim_invoice]
        FROM [xrf_index] 
        JOIN [vw_invoice] ON [xrf_index].[invoiceId] = ISNULL([vw_invoice].[internalId],-1)
        JOIN [vw_invoice_itemlist] ON [vw_invoice_itemlist].[internalId] = [vw_invoice].[internalId] 
         AND [xrf_index].[invItemLineId] = TRY_CAST([vw_invoice_itemlist].[customFieldList-custcol_line_id] AS numeric)
         AND TRY_CAST([vw_invoice_itemList].[item-internalId] AS numeric) = [xrf_Index].[invItemId]
        WHERE ( PATINDEX('%Cloud%',[vw_invoice_itemlist].[class-name]) > 0 OR [vw_invoice_itemlist].[class-name] = 'DEFAULT PRODUCT CLASS' )
        ORDER BY [xrf_index].[subscriptionId], ISNULL(CONVERT(int,[vw_invoice].[internalId]),-1)
        ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        -- update dim_invoice to set sum(invAmt) and sum(invRate)
        UPDATE inv1 SET
          invRate = x.[invRate]
        , invAmt = (x.[invRate]*x.[invQty]) 
         FROM [dim_invoice] inv1 
        JOIN (
                SELECT
                  TRY_CAST([vw_invoice_itemList].[internalId] AS int) AS 'internalId'
                , TRY_CAST([vw_invoice_itemlist].[customFieldList-custcol_line_id] AS numeric) AS 'customFieldList-custcol_line_id'
                , TRY_CAST([vw_invoice_itemList].[item-internalId] AS numeric) AS 'invItemInternalId'
                , SUM(ISNULL(TRY_CAST([vw_invoice_ItemList].[rate] AS money),0)) AS 'invRate'
                , ISNULL([vw_invoice_ItemList].[quantity],0)  AS 'invQty'
                , SUM(ISNULL(TRY_CAST([vw_invoice_ItemList].[rate] AS money),0)*ISNULL([vw_invoice_ItemList].[quantity],0)) AS 'invAmt'
                FROM [vw_invoice_itemList] 
                GROUP BY [vw_invoice_itemList].[internalId], TRY_CAST([vw_invoice_itemlist].[customFieldList-custcol_line_id] AS numeric) 
                , TRY_CAST([vw_invoice_itemList].[item-internalId] AS numeric), ISNULL([vw_invoice_ItemList].[quantity],0)
             ) x
        ON x.[internalId] = inv1.[invoiceId] 
        AND x.[customFieldList-custcol_line_id] = inv1.[invItemLineId]
        AND x.invItemInternalId = inv1.[invItemId]
        ;

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
    -- Use RAISERROR inside the CATCH block to return error  
    -- information about the original error that caused  
    -- execution to jump to the CATCH block.  
    RAISERROR ( @ErrMessage, @ErrSeverity, @ErrState );  
END CATCH;  

