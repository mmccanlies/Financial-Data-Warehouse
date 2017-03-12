/*************************************************************************************************
**                                     sp_dim_creditmemo
** 
** Load Credit Memo
** created:  2/20/2017   mmccanlies           
** revised:  3/07/2017      "            Revised to use source views instead of source tables 
**************************************************************************************************/
ALTER PROCEDURE [sp_dim_creditmemo] 
(
    @Rebuild   bit = 1,        -- 1 = Truncate and rebuild
    @Debug     bit = 0         -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_dim_creditmemo '
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
            TRUNCATE TABLE [dim_creditmemo]

        -- Major Code Sections --
        INSERT INTO [dim_creditmemo]
        ( creditMemoId, creditMemoLine, creditMemoNo, xrfIndexId, returnAuthId, rmaId, rmaDescr, rmaText, cmSalesOrderId, productClass
        , cmItemId, cmSkuNo, productFamilyPL, priceName, qty, units, rate, amt, incomeAcct, departmentName, locName, cmDate
        , baseSubscriptionId, subscriptionId, baseSubscription, subscription, isBase, refType, refTypeId, refTypeTxt 
        , tierName, tierId, tierLvl, seats, cumSeats, startDate, endDate, isCreditMemo, invoiceAmt, salesOrderId, salesOrderLine, subscriptionStatusId, subscriptionStatus
        )
        SELECT DISTINCT
          ISNULL(CONVERT(int,[vw_creditmemo_ItemList].[internalId]),-1) AS 'creditMemoId'
        , ISNULL(CONVERT(int,[vw_creditmemo_ItemList].[line]),-1) AS 'creditMemoLine'
        , [vw_creditmemo].[tranId] AS 'creditMemoNo'
        , [xrf_index].[xrfIndexId] AS 'xrfIndexId'
        , ISNULL(CONVERT(int,[vw_creditmemo].[createdFrom-internalId]),-1) AS 'returnAuthId'
        , [vw_creditmemo].[createdFrom-internalId] AS 'rmaId'
        , [vw_creditmemo].[createdFrom-name] AS 'rmaDescr'
        , [vw_creditMemo].[createdFrom-name] AS 'rmaText'
        , [vw_creditMemo].[customFieldList-custbody_rma_sales_order] AS 'cmSalesOrderId'
        , [vw_creditmemo_ItemList].[class-name] AS 'productClass'
--2
        , ISNULL(CONVERT(int,[vw_creditmemo_ItemList].[item-internalId]),0) AS 'cmItemId'
        , [vw_creditmemo_ItemList].[item-name] AS 'cmSkuNo'
        , [vw_creditmemo_ItemList].[description] AS 'productFamilyPL'
        , [vw_creditmemo_ItemList].[price-name] AS 'priceName'
        , [vw_creditmemo_ItemList].[quantity] AS 'qty'
        , [vw_creditmemo_ItemList].[units-name] AS 'units'
        , ISNULL(CONVERT(money,[vw_creditmemo_ItemList].[rate]),0) AS 'rate'
        , ISNULL(CONVERT(money,[vw_creditmemo_ItemList].[amount]),0) AS 'amt'
        , [vw_creditmemo_ItemList].[customFieldList-custcol_ava_incomeaccount] AS 'incomeAcct'
        , [vw_creditmemo_ItemList].[department-name] AS 'departmentName'
        , [vw_creditmemo_ItemList].[location-name] AS 'locName'
        , [vw_creditmemo].[tranDate] AS 'cmDate'
--3
        , [dim_subscription].[baseSubscriptionId] AS 'baseSubscriptionId'
        , [dim_subscription].[subscriptionId] AS 'subscriptionId'
--        , [dim_subscription].[parentId] AS 'parentId'
        , [dim_subscription].[BaseSubscription] AS 'baseSubscription'
        , [dim_subscription].[subscription] AS 'subscription'
--        , [dim_subscription].[parentSubscription] AS 'parentSubscription'
        , [dim_subscription].[isBase] AS 'isBase'
        , [dim_subscription].[refType] AS 'refType'
        , [dim_subscription].[refTypeId] AS 'refTypeId'
        , [dim_subscription].[refTypeId] AS 'refTypeTxt'
        , [dim_subscription].[tierName] AS 'tierName'
        , [dim_subscription].[tierId] AS 'tierId'
        , [dim_subscription].[tierLvl] AS 'tierLvl'
        , [dim_subscription].[seats] AS 'seats'
        , 0 AS 'cumSeats'
        , [dim_subscription].[startDate] AS 'startDate'
        , [dim_subscription].[endDate] AS 'endDate'
        , 1 AS 'isCreditMemo'
        , -1.0*ISNULL(CONVERT(money,[vw_creditmemo_ItemList].[amount]),0) AS 'invoiceAmt'
        , [dim_subscription].[salesOrderId] AS 'salesOrderId'
        , [dim_subscription].[salesOrderLine] AS 'salesOrderLine'
        , [dim_subscription].[subscriptionStatusId] AS 'subscriptionStatusId'
        , [dim_subscription].[subscriptionStatus] AS 'subscriptionStatus'
        -- INTO [dim_creditmemo]
        FROM [vw_creditmemo]
        JOIN [vw_creditmemo_ItemList] ON [vw_creditmemo_ItemList].[internalId] = [vw_creditmemo].[internalId]
        JOIN [dim_subscription] ON [dim_subscription].[creditMemoNo] = [vw_creditmemo].[tranId]
        JOIN [xrf_index] ON [xrf_index].creditMemoId = [vw_creditmemo].[internalId]
        ORDER BY [dim_subscription].[baseSubscriptionId], [dim_subscription].[subscriptionId]
        ;
        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

--        UPDATE cm SET
--          cm.[invoiceAmt] = s.[invoiceAmount]
--        , cm.[parentSubscription] = s.[parentSubscription]
--        FROM [dim_creditmemo] cm
--        JOIN [dim_subscription] s ON s.subscriptionId = cm.subscriptionId

        -- log exit
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

