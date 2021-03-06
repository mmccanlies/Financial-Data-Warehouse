USE [sandbox_mike]
GO
/****** Object:  StoredProcedure [dbo].[sp_xrf_index]    Script Date: 3/7/2017 8:51:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*************************************************************************************************
**                                    sp_xrf_index
** 
** Load sxrf_index table first. This table should not have to be reloaded every time.
**
** dependencies: vw_custom_subscription, vw_salesorder, vw_salesorder_itemlist, 
**               vw_customer, vw_invoice, vw_invoice_itemlist
**
** created:  02/20/2017   mmccanlies     created 
** revised:  03/17/2017      "           Added invoice and sales LineId's and changed names to make clearer
**           03/15/2017      "           Changed JOIN to vw_invoice_itemList to INNER to eliminate dups and commented out UPDATE statement as it is no longer doing anything 
**           03/07/2017      "           Revised to use source views instead of tables i.e. vw_custom_subscription vs. ns_custom_subscription
**           02/27/2017      "           Had to add a join on itemId between invoice_itemlist and salesOrder_ItemList 
**                                       [vw_invoice_itemlist].[item-internalId] = [vw_salesorder_itemlist].[item-internalId]
**                                       to remove some spurious joins causing duplicates.
**************************************************************************************************/
ALTER PROCEDURE [dbo].[sp_xrf_index]
(
    @Rebuild   bit = 1,        -- 1 = Truncate and rebuild
    @Debug     bit = 0         -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_xrf_index '
    DECLARE @ErrMsg   nvarchar(2000) = N'**** Error occurred in '+@ProcName+' - '	
    DECLARE @EntryMsg nvarchar(1000) = N'Starting Procedure '+@ProcName+'  '
    DECLARE @MidMsg   nvarchar(1000) = N'    Procedure '+@ProcName+'  '
    DECLARE @ExitMsg  nvarchar(1000) = N'Exiting Procedure '+@ProcName+'  '
    DECLARE @ExitTxt  nvarchar(1500)
    DECLARE @currentTime nvarchar(100)
    -- log entry
    SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime())
    EXEC [sp_message_handler] @currentTime, @EntryMsg, @ProcName ;

BEGIN TRY
    BEGIN TRANSACTION
        IF @Rebuild = 1
            TRUNCATE TABLE [xrf_index]

 
        INSERT INTO [xrf_index] 
        ( baseSubscriptionId, subscriptionId, subsLine, salesOrderToSubsLine, creditMemoId, creditMemoNo, isBase, salesOrderId, invoiceId
        , salesOrderItemLineId, invItemLineId, salesOutId, salesOutLineId, classId, itemId, salesOrderItemId, invItemId, salesOrgId, billCustomerId, endCustomerId, resellerId )
       SELECT DISTINCT 
          CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_base_subscription]) AS 'baseSubscriptionId'
        , CONVERT(int,[vw_custom_subscription].[internalId]) AS 'subscriptionId'
        , TRY_CAST(ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_transaction_line],1) AS numeric)  AS 'subsLine'
        , [vw_salesorder_itemlist].[line] AS 'salesOrderToSubsLine'
        , [vw_creditmemo].[internalId] AS 'creditMemoId'
        , [vw_custom_subscription].[customFieldList-custrecord_credit_memo] AS 'creditMemoNo' 
        , CAST([customFieldList-custrecord_base_subscription_flag] AS int) AS 'isBase'
        , ISNULL(CAST([vw_custom_subscription].[customFieldList-custrecord_subscription_transaction] AS int),-1)  AS 'salesOrderId'
        , ISNULL(TRY_CAST(ISNULL([vw_invoice].[internalId],[xrf_legacy_invoice_salesorder].[invoiceInternalId]) AS int),-1) AS 'invoiceId'
        , TRY_CAST(ISNULL([vw_salesorder_itemlist].[customFieldList-custcol_line_id],1) AS numeric) AS 'salesOrderItemLineId'
        , TRY_CAST(ISNULL([vw_invoice_itemlist].[customFieldList-custcol_line_id],1) AS numeric) AS 'invItemLineId' 

        , ISNULL(CAST([vw_custom_sales_out].[internalId] AS int),-1) AS 'salesOutId'
        , ISNULL(TRY_CAST([vw_custom_sales_out].[customFieldList-custrecord_sales_out_original_line_num] AS int),1) AS 'salesOutLineId'
        , ISNULL(CAST([vw_salesorder_itemlist].[class-internalId] AS int),-1) AS 'classId'
        , ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_subscription_item]),-1) AS 'itemId'
        , ISNULL(CAST([vw_salesorder_itemlist].[item-internalId] AS int),-1) AS 'salesOrderItemId'
        , ISNULL(CAST([vw_invoice_itemlist].[item-internalId] AS int),-1) AS 'invItemId'

        , ISNULL([vw_salesOrder].[customFieldList-custbody_om_salesperson],-1) AS 'salesOrgId'
        , ISNULL(CAST([vw_salesorder].[customFieldList-custbody_bill_customer] AS int),-1) AS 'billCustomerId'
        , ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_subscription_end_customer]),-1) AS 'endCustomerId'
        , -1 AS 'resellerId'
        --INTO all_index_xrf
        FROM [vw_custom_subscription] 
        JOIN [vw_nonInventorySaleItem] ON [vw_nonInventorySaleItem].[internalId] = [vw_custom_subscription].[customFieldList-custrecord_subscription_item] 
        LEFT OUTER JOIN [vw_creditmemo] ON [vw_custom_subscription].[customFieldList-custrecord_credit_memo] = [vw_creditmemo].[tranId]
        LEFT OUTER JOIN [vw_salesorder] ON [vw_salesorder].[internalId] = [vw_custom_subscription].[customFieldList-custrecord_subscription_transaction]
        LEFT OUTER JOIN [vw_salesorder_itemlist] ON [vw_salesorder_itemlist].[internalId] = [vw_salesorder].[internalId]
                    AND TRY_CAST(ISNULL([vw_salesorder_itemlist].[line],1) AS numeric) = TRY_CAST(ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_transaction_line],1) AS numeric)  -- Added
        LEFT OUTER JOIN [vw_invoice] ON [vw_invoice].[createdFrom-internalId] = [vw_salesorder].[internalId]
        LEFT OUTER JOIN [xrf_legacy_invoice_salesorder] ON [xrf_legacy_invoice_salesorder].[salesOrderInternalId] = [vw_salesorder].[internalId] 
        JOIN [vw_invoice_itemlist] ON [vw_invoice_itemlist].[internalId] = ISNULL([vw_invoice].[internalId],[xrf_legacy_invoice_salesorder].[invoiceInternalId])  --[vw_invoice].[internalId] 
                    AND CAST([vw_invoice_itemlist].[item-internalId] AS int) = CAST([vw_salesorder_itemlist].[item-internalId] AS int)
                    AND TRY_CAST([vw_invoice_itemlist].[customFieldList-custcol_line_id] AS numeric) = TRY_CAST([vw_salesorder_itemlist].[customFieldList-custcol_line_id] AS numeric)   -- Added
        LEFT OUTER JOIN [vw_custom_sales_out] ON [vw_custom_sales_out].[customFieldList-custrecord_original_sales_order] =  [vw_salesorder_itemList].[internalId] 
                    AND [vw_custom_sales_out].[customFieldList-custrecord_sales_out_original_line_num] = [vw_salesorder_itemlist].[customFieldList-custcol_line_id]  -- Added
                    AND [vw_custom_sales_out].[customFieldList-custrecord_sales_out_amount] >= 0
        LEFT OUTER JOIN [vw_customer] bill_cust ON ISNULL(CONVERT(int,bill_cust.[internalId]),-1) = ISNULL(CONVERT(int,[vw_salesorder].[customFieldList-custbody_bill_customer]),-1) 
        LEFT OUTER JOIN [vw_customer] end_cust  ON ISNULL(CONVERT(int, end_cust.[internalId]),-1) = ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_subscription_end_customer]),-1)
        ORDER BY CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_base_subscription])
               , CONVERT(int,[vw_custom_subscription].[internalId])
        ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        -- Update invoiceId and salesorderId fro salesorder and invoice using otherRefNum where salesOrder did not match subscription in first pass
--        UPDATE [xrf_index] SET
--          salesOrderId = ISNULL(CAST([vw_salesorder].[internalId] AS int),-1)
--       , invoiceId =ISNULL(CAST([vw_invoice].[internalId] AS int),-1)
--        FROM [vw_invoice]
--        JOIN [vw_salesOrder] ON [vw_invoice].[otherRefNum] = [vw_salesOrder].[otherRefNum]
--        AND ( CONVERT(date, [vw_salesOrder].[tranDate]) = CONVERT(date,[vw_invoice].[customFieldList-custbody_order_date]) 
--            OR [vw_invoice].[total] = [vw_salesOrder].[total] )
--        JOIN [xrf_index] ON [xrf_index].[salesOrderId] = [vw_salesorder].[internalId]
--        WHERE [xrf_index].[invoiceId] = -1 ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
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
    DECLARE @ErrSeverity int;  
    DECLARE @ErrState    int;  
    SELECT  @ErrMessage  = @ErrMsg+SUBSTRING(ERROR_MESSAGE(),1,1950)+' ',  
            @ErrSeverity = CONVERT(nvarchar, ERROR_SEVERITY())+' ',
            @ErrState    = CONVERT(nvarchar, ERROR_STATE())+' '  ; 
    
    SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
           @ErrMsg = @ErrMessage+@ErrSeverity+@ErrState ;
    EXEC [sp_message_handler] @currentTime, @ErrMsg, @ProcName ;
    ROLLBACK
    RAISERROR ( @ErrMessage, @ErrSeverity, @ErrState );  
END CATCH;  

