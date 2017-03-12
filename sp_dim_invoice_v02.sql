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
** created:  2/27/2017     mmccanlies           
** revised:  3/07/2017      "            Revised to use source views instead of source tables 
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
        ( invoiceId, invoiceLine, xrfIndexId, invoiceNo, invoiceDate, invCustColTerm, serviceStart, serviceEnd, serviceYrs, serviceMos, serviceDays, 
          orderLine, invClassName, skuNo, invDescription, invLocName, invRate, invQty, invUnits, invPriceName, invIncAcct, BillToCustomerId,
          BillToCustomerName, BillToCustomerAddress, billingDate, invAutoSalesOut, invRevRecStartDate, invRevRecEndDate, 
          invRevRecSchedName, subscriptionId, salesOrderId, invItemId )

        SELECT DISTINCT 
          ISNULL(CONVERT(int,[vw_invoice].[internalId]),-1) AS 'invoiceId'
        , ISNULL(CONVERT(int,CONVERT(numeric,[vw_invoice_itemlist].[customFieldList-custcol_line_id])),1) AS 'invoiceLine'
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
        , ISNULL([vw_invoice_ItemList].[rate],0) AS 'invRate'

        --, ISNULL([vw_invoice_ItemList].[quantity],1) AS 'origInvQty'
        --, [vw_invoice_itemlist].[units-name] AS 'origInvUnits'
        , CASE WHEN ISNUMERIC(SUBSTRING([vw_invoice_itemlist].[units-name],1,1)) = 1
            THEN ISNULL(TRY_CAST(SUBSTRING([vw_invoice_itemlist].[units-name],1,1) AS numeric),0)
            ELSE 1
          END * CONVERT(numeric,[vw_invoice_ItemList].[quantity]) AS 'invQty'
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
        --, [vw_invoice_itemlist].[customFieldList-custcol_standard_discount_pct] AS 'invStdDiscPct'
        --, [vw_invoice_itemlist].[customFieldList-custcol_orn_discount_pct] AS 'invOrnDiscPct'
        --, [vw_invoice_itemlist].[customFieldList-custcol_nsd_discount_pct] AS 'invNsdDiscPct'
        , [vw_invoice_itemlist].[customFieldList-custcol_ava_incomeaccount] AS 'invIncAcct'
        , ISNULL([vw_invoice].[customFieldList-custbody_bill_customer],-1) AS 'BillToCustomerId'
        , [vw_invoice].[entity-name] AS 'BillToCustomerName'
        , ISNULL(REPLACE([vw_invoice].[billAddress],'<br>',' '),'NA')  AS 'BillToCustomerAddress'
        , [vw_invoice].[tranDate] AS 'billingDate'

        , ISNULL([vw_invoice_itemlist].[customFieldList-custcol_auto_sales_out],-1) AS 'invAutoSalesOut'
        , [vw_invoice_itemlist].[revRecStartDate] AS 'invRevRecStartDate'
        , [vw_invoice_itemlist].[revRecEndDate] AS 'invRevRecEndDate'
        , [vw_invoice_itemlist].[revRecSchedule-name] AS 'invRevRecSchedName'
        , [xrf_index].[subscriptionId] AS 'subscriptionId'     --ISNULL(CONVERT(int,[vw_invoice_itemlist].[customFieldList-custcol_subscription]),-1) AS 'subscriptionId'
        , ISNULL(CONVERT(int,[vw_invoice].[createdFrom-internalId]),-1) AS 'salesOrderId'
        , ISNULL(CONVERT(int,[vw_invoice_ItemList].[item-internalId]),-1) AS 'invItemId'
        --INTO [dim_invoice]
        FROM [vw_custom_subscription] 
        LEFT OUTER JOIN [vw_salesorder] ON ISNULL([vw_salesorder].[internalId],-1) = ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_transaction],-1)
        LEFT OUTER JOIN [vw_salesorder_itemlist] ON ISNULL([vw_salesorder_itemlist].[internalId],-1) = ISNULL([vw_salesorder].[internalId],-1)
	                AND [vw_salesorder_itemlist].[line] = [vw_custom_subscription].[customFieldList-custrecord_subscription_transaction_line]  -- Added
        LEFT OUTER JOIN [vw_invoice] ON ISNULL([vw_invoice].[createdFrom-internalId],-1) = ISNULL([vw_salesorder].[internalId],-1)
        LEFT OUTER JOIN [vw_invoice_itemlist] ON ISNULL([vw_invoice_itemlist].[internalId],-1) = ISNULL([vw_invoice].[internalId],-1) 
	                AND TRY_CAST(ISNULL([vw_invoice_itemlist].[customFieldList-custcol_line_id],1) AS numeric) = TRY_CAST(ISNULL([vw_salesorder_itemlist].[customFieldList-custcol_line_id],1) AS numeric)   -- Added
        RIGHT JOIN [xrf_index] ON [xrf_index].[invoiceId] = ISNULL([vw_invoice].[internalId],-1)
               AND [xrf_index].[invoiceLine] = TRY_CAST(ISNULL([vw_invoice_itemlist].[customFieldList-custcol_line_id],1) AS numeric)
        ORDER BY [xrf_index].[subscriptionId] --ISNULL(CONVERT(int,[vw_invoice_itemlist].[customFieldList-custcol_subscription]),-1)
        ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        -- Fix subscriptionId's in invoice_dim first
--        UPDATE [dim_invoice] SET 
--          [subscriptionId] = [xrf_index].[subscriptionId]
--        FROM [dim_invoice]
--        JOIN [xrf_index] ON [xrf_index].[invoiceId] = [dim_invoice].[invoiceId]
--         AND [xrf_index].invoiceLine = [dim_invoice].[invoiceLine] ;

        UPDATE [ns_invoice] SET
        [createdFrom-internalId] = oldInvoiceId
        FROM [ns_invoice] 
        JOIN [xrf_legacy_invoice_salesorder] ON [xrf_legacy_invoice_salesorder].[invInternalId] = [ns_invoice].[internalId]
        WHERE [createdFrom-internalId] IS NULL
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

