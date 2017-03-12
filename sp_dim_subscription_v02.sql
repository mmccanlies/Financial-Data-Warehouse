USE [sandbox_mike]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
**                                    sp_dim_subscription
** 
** Load dim_subscription and do extra updates
** dependencies:        xrf_index                                           -- must be loaded and updated before calling this procedure
**                      ns_creditmemo                   ns_creditmemo_ItemList
**                      dim_invoice                     ns_custom_subscription
**                      dim_customer                    customSubscriptionTierDefault
**                      vw_subscription_sequence        vw_subscription_update
**                       
**
** 
** created:  2/20/2017   mmccanlies 
** revised:  3/07/2017      "            Revised to use source views instead of tables i.e. vw_custom_subscription vs. ns_custom_subscription
**           2/20/2017   mmccanlies      major updates for bucket logic
**************************************************************************************************/
ALTER PROCEDURE [sp_dim_subscription]
(
    @Rebuild   bit = 1,        -- 1 = Truncate and rebuild
    @Debug     bit = 0         -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_dim_subscription '
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
            TRUNCATE TABLE [dim_subscription]

        -- Major Code Sections --
        INSERT INTO [dim_subscription] 
        ( xrfIndexId, baseSubscriptionId, subscriptionId, baseSubscription, subscription, isBase, refType, refTypeId, refTypeTxt, tierName, tierId, tierLvl, 
          seats, totalSeats, extraSeats, creditMemoNo, featureOrBase, cloudFeatures, featureType, featureAmt, amplifyQty, extremeQty, 
          vmrsQty, vmrsLicenses, ssoIncl, lyncIncl, maxUsersSet, maxUsersSetUnits, maxMtgParticipants, maxVMRs,  maxVMRsUnits, 
          endPointsAsUsers, recordingEnabled, recordingHrsIncl, backgroundSet, startDate, endDate, entitledYrs, entitledMos, entitledDays, 
          invoiceAmount, invoiceDate, stdDiscount, ornDiscount, nsdDiscount,  nsdApprovalNo, skuNo, endCustomerId, endCustomerName, endCustomerAddr, 
          itemType, itemId, itemTypeId, salesOrderId, salesOrderLine, subscriptionStatusId, subscriptionStatus, isCreditMemo )
        SELECT DISTINCT
          [xrf_index].[xrfIndexId]
        , ISNULL(CONVERT(int, [vw_custom_subscription].[customFieldList-custrecord_base_subscription]),-1) AS 'baseSubscriptionId' 
        , ISNULL(CONVERT(int, [vw_custom_subscription].[internalId]),-1) AS 'subscriptionId'
        , (SELECT customRecordId FROM vw_custom_subscription s WHERE s.internalId = [vw_custom_subscription].[customFieldList-custrecord_base_subscription] ) AS 'BaseSubscription'
        , [vw_custom_subscription].[customRecordId] AS 'subscription'
        , ISNULL(CONVERT(int, [customFieldList-custrecord_base_subscription_flag]),0) AS 'isBase' 
        , CASE [customFieldList-custrecord_reference_type] 
            WHEN 4 THEN 'Cloud - New'
            WHEN 5 THEN 'Cloud - Renewal'
            WHEN 6 THEN 'Cloud - Upgrade'
            WHEN 7 THEN 'Cloud - Upgrade/Renewal'
            WHEN 8 THEN 'Cloud - Upgrade/Renewal Midterm'
            WHEN 9 THEN 'Cloud - Feature'
            WHEN 10 THEN 'Cloud - Add Users'
        END AS 'refType'
        , [vw_custom_subscription].[customFieldList-custrecord_reference_type] AS 'refTypeId' 
        , CASE [customFieldList-custrecord_reference_type] 
            WHEN 4 THEN '4 - New'
            WHEN 5 THEN '5 - Renewal'
            WHEN 6 THEN '6 - Upgrade'
            WHEN 7 THEN '7 - Upgrade/Renewal'
            WHEN 8 THEN '8 - Upgrade/Renewal Midterm'
            WHEN 9 THEN '9 - Feature'
            WHEN 10 THEN '10 - Add Users'
        END AS 'refType'
        , ISNULL([CustomSubscriptionTierDefault].[tierName],'Feature') AS 'tierName'
        , [customSubscriptionTierDefault].[internalId] AS 'tierId'
        , [customSubscriptionTierDefault].[tierLvl] AS 'tierLvl'
        , CASE WHEN [customFieldList-custrecord_reference_type] != 9
            THEN ISNULL(CONVERT(int, [customFieldList-custrecord_number_of_seats_2]),0) 
            ELSE 0
          END AS 'seats' 
        , CASE WHEN [customFieldList-custrecord_reference_type] != 9
            THEN ISNULL(CONVERT(int, [customFieldList-custrecord_number_of_seats]),0) 
            ELSE 0
          END AS 'totalSeats'
        , CASE WHEN [customFieldList-custrecord_reference_type] != 9
            THEN ISNULL(CONVERT(int, [customFieldList-custrecord_number_of_seats_2]),0) 
            ELSE 0
          END AS 'extraSeats'

        , [vw_custom_subscription].[customFieldList-custrecord_credit_memo] AS 'creditMemoNo'
        , CASE 
            WHEN [vw_custom_subscription].[customFieldList-custrecord_base_subscription_flag] = 1 THEN 'Base'
            WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] IS NOT NULL THEN 'Feature'
            ELSE 'Other'
          END AS 'featureOrBase'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_cloud_features],'') AS 'cloudFeatures'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_license_type],'') AS 'featureType'
        , CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'Ampl%'
              THEN ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_amplify_hours]),0)
            WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'Extr%'
              THEN ISNULL(CONVERT(int, [vw_custom_subscription].[customFieldList-custrecord_number_of_seats]),0)
            ELSE 0
          END AS 'featureAmt'

        , CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'Ampl%'
              THEN ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_amplify_hours]),0)
            ELSE 0
          END AS 'amplifyQty'
        , CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'Extr%'
              THEN ISNULL(CONVERT(int, [vw_custom_subscription].[customFieldList-custrecord_number_of_seats]),0)
            ELSE 0
          END AS 'extremeQty'
        , CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'VMR%'
              THEN ISNULL([vw_custom_subscription].[customFieldList-custrecord_vmrs],0)
            ELSE 0
          END AS 'vmrsQty'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_vmrs],0) AS 'vmrsLicenses'

        , [customSubscriptionTierDefault].[ssoIncl]             AS 'ssoIncl'
        , [customSubscriptionTierDefault].[lyncIncl]            AS 'lyncIncl'
        , [customSubscriptionTierDefault].[maxUsersSet]         AS 'maxUsersSet'
        , [customSubscriptionTierDefault].[maxUsersSetUnits]    AS 'maxUsersSetUnits'
        , [customSubscriptionTierDefault].[maxMtgParticipants]  AS 'maxMtgParticipants'
        , [customSubscriptionTierDefault].[maxVMRs]             AS 'maxVMRs'
        , [customSubscriptionTierDefault].[maxVMRsUnits]        AS 'maxVMRsUnits'
        , [customSubscriptionTierDefault].[endPointsAsUsers]    AS 'endPointsAsUsers'
        , [customSubscriptionTierDefault].[recordingEnabled]    AS 'recordingEnabled'
        , [customSubscriptionTierDefault].[recordingHrsIncl]    AS 'recordingHrsIncl'
        , [customSubscriptionTierDefault].[backgroundSet]       AS 'backgroundSet'

        , CONVERT(date,[vw_custom_subscription].[customFieldList-custrecord_subscription_start_date])   AS 'startDate' 
        , CONVERT(date,[vw_custom_subscription].[customFieldList-custrecord_subscription_end_date])     AS 'endDate' 
        , DATEDIFF(YY, [vw_custom_subscription].[customFieldList-custrecord_subscription_start_date], [vw_custom_subscription].[customFieldList-custrecord_subscription_end_date]) AS 'entitledYrs'
        , DATEDIFF(MM, [vw_custom_subscription].[customFieldList-custrecord_subscription_start_date], [vw_custom_subscription].[customFieldList-custrecord_subscription_end_date]) AS 'entitledMos'
        , [dbo].[ufn_datediff_365]([vw_custom_subscription].[customFieldList-custrecord_subscription_start_date], [vw_custom_subscription].[customFieldList-custrecord_subscription_end_date]) AS 'entitledDays'

        , 0 AS 'invoiceAmt'
        , CONVERT(date,NULL) AS 'invoiceDate'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_standard_discount_pct],0)/100.0 AS 'stdDiscount'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_orn_discount_pct],0)/100.0      AS 'ornDiscount'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_nsd_discount_pct],0)/100.0      AS 'nsdDiscount'

        , [vw_custom_subscription].[customFieldList-custrecord_nsd_id] AS 'nsdApprovalNo'
        , [vw_custom_subscription].[customFieldList-custrecord_subscription_item_no] AS 'skuNo' 
        , ISNULL(CONVERT(int,[customFieldList-custrecord_subscription_end_customer]),-1) AS 'endCustomerId' 
        , SUBSTRING([dim_customer].[entityId],CHARINDEX(' ',[dim_customer].[entityId]),LEN([dim_customer].[entityId])) AS 'endCustomerName'
        , REPLACE(REPLACE(addrText,[dim_customer].[entityId]+', ',''),'<br>','') AS 'endCustomerAddr'
        , (SELECT description1 FROM [xrf_lookup] WHERE [refType] = 'ItemType' AND [sourceRefId] = [vw_custom_subscription].[customFieldList-custrecord_item_type]) AS 'itemType'
        , ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_subscription_item]),-1) AS 'itemId'
        , ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_item_type]),-1) AS 'itemTypeId'
        , ISNULL(CONVERT(int,CONVERT(numeric,[vw_custom_subscription].[customFieldList-custrecord_subscription_transaction])),1) AS 'salesOrderId'
        , ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_subscription_transaction_line]),1) AS 'salesOrderLine'
        , ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_subscription_status]),-1) AS 'subscriptionStatusId'
        , (SELECT [description1] FROM [xrf_lookup] WHERE [xrf_lookup].[refType] = 'subStatus' AND [xrf_lookup].[sourceRefId] = [vw_custom_subscription].[customFieldList-custrecord_subscription_status] ) AS 'status'
        , 0 AS 'isCreditMemo'
        --INTO [dim_subscription]
        FROM [vw_custom_subscription] 
        LEFT OUTER JOIN [dim_customer] ON [dim_customer].[internalId] = ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_subscription_end_customer]),-1)
                    AND [dim_customer].[recordType] = 'END'
        JOIN [customSubscriptionTierDefault] ON  [customSubscriptionTierDefault].[internalId] = ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_tier],-1)
        JOIN [xrf_index] ON [xrf_index].subscriptionId = ISNULL(CONVERT(int, [vw_custom_subscription].[internalId]),-1) 
--        JOIN [vw_test_grp] ON  [vw_test_grp].[subscriptionId] = [vw_custom_subscription].[internalId] 
        ORDER BY ISNULL(CONVERT(int, [vw_custom_subscription].[customFieldList-custrecord_base_subscription]),-1) ASC 
               , CONVERT(date,[vw_custom_subscription].[customFieldList-custrecord_subscription_start_date]) 
               , ISNULL(CONVERT(int, [vw_custom_subscription].[internalId]),-1) ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;
    COMMIT TRANSACTION

    BEGIN TRANSACTION

        -- dim_invoice must be loaded and updated before dim_subscription
        -- Set invoiceDates in dim_subscription
        UPDATE dim_subscription SET
          invoiceAmount = [dim_invoice].[invRate]
        , invoiceDate = [dim_invoice].[invoiceDate]
        FROM [dim_subscription]
        JOIN [dim_invoice] ON [dim_invoice].subscriptionId = [dim_subscription].subscriptionId

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;
    COMMIT TRANSACTION

    BEGIN TRANSACTION
/****        -- insert credit memos
        INSERT INTO dim_subscription
        ( xrfIndexId, baseSubscriptionId, subscriptionId, parentId, baseSubscription, subscription, parentSubscription, creditMemoNo, isBase, refType, refTypeId, refTypeTxt, tierName, tierId, tierLvl 
        , seats, totalSeats, extraSeats, startDate, endDate, entitledYrs, entitledMos, entitledDays, invoiceAmount, invoiceDate, stdDiscount, ornDiscount, nsdDiscount, nsdApprovalNo
        , skuNo, endCustomerId, endCustomerName, endCustomerAddr, itemTypeId, itemType, itemId, salesOrderId, salesOrderLine, subscriptionStatusId, subscriptionStatus
        , featureType, featureAmt, amplifyQty, extremeQty, vmrsQty, cloudFeatures, vmrsLicenses, featureOrBase, ssoIncl, lyncIncl, maxUsersSet
        , maxUsersSetUnits, maxMtgParticipants, maxVMRs, maxVMRsUnits, endPointsAsUsers, recordingEnabled, recordingHrsIncl, BackgroundSet, isNew, isRenewal, isMidTerm
        , isUpgrade, isCreditMemo, isAddSeats, isAddFeature 
        )
        SELECT 
          [dim_subscription].[xrfIndexId]
        , [dim_subscription].[baseSubscriptionId] AS 'baseSubscriptionId'
        , [dim_subscription].[subscriptionId] AS 'subscriptionId'
        , [dim_subscription].[parentId] AS 'parentId'
        , [dim_subscription].[BaseSubscription] AS 'baseSubscription'
        , [dim_subscription].[subscription] AS 'subscription'
        , [dim_subscription].[parentSubscription] AS 'parentSubscription'
        , [vw_creditmemo].[tranId] AS 'creditMemoNo'
        , [dim_subscription].[isBase] AS 'isBase'
        , [dim_subscription].[refType] AS 'refType'
        , [dim_subscription].[refTypeId] AS 'refTypeId'
        , CONVERT(nvarchar, [dim_subscription].[refTypeId])+' - Credit Memo' AS 'refTypeTxt'
        , ISNULL([dim_subscription].[tierName],'Feature') AS 'tierName'
        , [dim_subscription].[tierId] AS 'tierId'
        , [dim_subscription].[tierLvl] AS 'tierLvl'
--2
        , [dim_subscription].[seats] AS 'seats'
        , [dim_subscription].[seats] AS 'totalSeats'
        , 0 AS 'extraSeats'
        , [dim_subscription].[startDate] AS 'startDate'
        , [dim_subscription].[endDate] AS 'endDate'
        , [dim_subscription].[entitledYrs] AS 'entitledYrs'
        , [dim_subscription].[entitledMos] AS 'entitledMos'
        , [dim_subscription].[entitledDays] AS 'entitledDays'
        , -1.0*[dim_subscription].[invoiceAmount] AS 'invoiceAmount'
        , [dim_subscription].[invoiceDate] AS 'invoiceDate'
        , [dim_subscription].[stdDiscount] AS 'stdDiscount'
        , [dim_subscription].[ornDiscount] AS 'ornDiscount'
        , [dim_subscription].[nsdDiscount] AS 'nsdDiscount'
        , [dim_subscription].[nsdApprovalNo] AS 'nsdApprovalNo'
--3
        , [dim_subscription].[skuNo] AS 'skuNo'
        , [dim_subscription].[endCustomerId] AS 'endCustomerId'
        , [dim_subscription].[endCustomerName] AS 'endCustomerName'
        , [dim_subscription].[endCustomerAddr] AS 'endCustomerAddr'
        , [dim_subscription].[itemTypeId] AS 'itemTypeId'
        , [dim_subscription].[itemType] AS 'itemType'
        , [dim_subscription].[itemId] AS 'itemId'
        , [dim_subscription].[salesOrderId] AS 'salesOrderId'
        , [dim_subscription].[salesOrderLine] AS 'salesOrderLine'
        , [dim_subscription].[subscriptionStatusId] AS 'subscriptionStatusId'
        , [dim_subscription].[subscriptionStatus] AS 'subscriptionStatus'
--4
        , [dim_subscription].[featureType] AS 'featureType'
        , [dim_subscription].[featureAmt]  AS 'featureAmt'
        , 0 AS 'amplifyQty'
        , 0 AS 'extremeQty'
        , 0 AS 'vmrsQty'
        , [dim_subscription].[cloudFeatures] AS 'cloudFeatures'
        , [dim_subscription].[vmrsLicenses]  AS 'vmrsLicenses'
        , [dim_subscription].[featureOrBase] AS 'featureOrBase'
        , [dim_subscription].[ssoIncl]       AS 'ssoIncl'
        , [dim_subscription].[lyncIncl]      AS 'lyncIncl'
        , [dim_subscription].[maxUsersSet]   AS 'maxUsersSet'
--5
        , [dim_subscription].[maxUsersSetUnits]   AS 'maxUsersSetUnits'
        , [dim_subscription].[maxMtgParticipants] AS 'maxMtgParticipants'
        , [dim_subscription].[maxVMRs]            AS 'maxVMRs'
        , [dim_subscription].[maxVMRsUnits]       AS 'maxVMRsUnits'
        , [dim_subscription].[endPointsAsUsers]   AS 'endPointsAsUsers'
        , [dim_subscription].[recordingEnabled]   AS 'recordingEnabled'
        , [dim_subscription].[recordingHrsIncl]   AS 'recordingHrsIncl'
        , [dim_subscription].[BackgroundSet]      AS 'BackgroundSet'
        , [dim_subscription].[isNew] AS 'isNew'
        , 0 AS 'isRenewal'
        , [dim_subscription].[isMidTerm] AS 'isMidTerm'
--6
        , 0 AS 'isUpgrade'
        , 1 AS 'isCreditMemo'
        , 0 AS 'isAddSeats'
        , 0 AS 'isAddFeature'
        FROM [vw_creditmemo]
        JOIN [vw_creditmemo_ItemList] ON [vw_creditmemo_ItemList].[internalId] = [vw_creditmemo].[internalId]
        JOIN [dim_subscription] ON [dim_subscription].[creditMemoNo] = [vw_creditmemo].[tranId] 
        JOIN [xrf_index] ON [xrf_index].[subscriptionId] = [dim_subscription].[subscriptionId]  ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;
****/
        -- set values across all subscription records
        UPDATE s SET 
          s.[parentId] = x.[parentId]
        , s.[parentSubscription] = ( SELECT TOP 1 s2.subscription FROM dim_subscription s2 WHERE s2.baseSubscriptionId = x.baseSubscriptionId AND  s2.subscriptionId = x.parentId) 
        , s.[isBase] = x.[isBase]
        , s.[overallOrdr] = x.[overallOrdr]
        , s.[renewalOrdr] = x.[renewalOrdr] 
        , s.[totalSeats] = x.[totalSeats]
        , s.[isNew] = x.[isNew]
        , s.[isRenewal] = x.[isRenewal]
        , s.[isUpgrade] = x.[isUpgrade]
        , s.[isCreditMemo] = 0
        , s.[isMidTerm] = x.[isMidTerm]
        , s.[isAddFeature] = x.[isAddFeature]
        , s.[isAddSeats] = x.[isAddSeats]
        FROM [vw_subscription_update] x
        JOIN [dim_subscription] s ON s.baseSubscriptionId = x.baseSubscriptionId AND s.subscriptionId = x.subscriptionId

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        -- set values just for Credit Memos
        UPDATE s SET 
          s.[parentId] = s.[subscriptionId]
        , s.[parentSubscription] = s.[subscription]
        , s.[renewalOrdr] = -1
        , s.[totalSeats] = x.[totalSeats]
        , s.[isNew] = x.[isNew]
        , s.[isRenewal] = 0
        , s.[isUpgrade] = 0
        , s.[isCreditMemo] = 1
        , s.[isMidTerm] = x.[isMidTerm]
        FROM [vw_subscription_update] x
        JOIN [dim_subscription] s ON s.baseSubscriptionId = x.baseSubscriptionId AND s.subscriptionId = x.subscriptionId
        WHERE s.[isCreditMemo] = 1 ;

--> We need an update that sets totalSeats and Totals HERE <--
        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;
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
