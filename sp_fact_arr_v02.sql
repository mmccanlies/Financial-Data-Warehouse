USE [sandbox_mike]
GO

/****** Object:  StoredProcedure [dbo].[sp_fact_arr]    Script Date: 2/27/2017 11:42:48 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*************************************************************************************************
**                                    sp_fact_arr
** 
** Load fact_arr table. 
** dependencies:    xrf_Index               vw_subscription_list
**                  dim_Subscription        vw_subscription_sequence
** created:  02/20/2017   mmccanlies        created 
** revised:  03/07/2017      "              Revised to use source views instead of source tables 
**           03/17/2017      "              Modified to use vw_custom_subscription and new field names in xrf_index
**************************************************************************************************/
ALTER PROCEDURE [dbo].[sp_fact_arr] 
(
    @Rebuild   bit = 1,        -- 1 = Truncate and rebuild
    @Debug     bit = 0         -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = 'sp_fact_arr'
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
            TRUNCATE TABLE [fact_arr] ;
        -- insert follow on subscriptions like Renewals, Features and Add Seats
        INSERT INTO [fact_arr]
        ( xrfIndexId, baseSubscriptionId, subscriptionId, salesOrderId, salesOrderItemLineId, invoiceId, invItemLineId, invItemId, salesOrderItemId, 
          salesOrgId, salesOutId, salesOutLineId, classId, itemId, billToCustomerId, endCustomerId, resellerId, startDateId, endDateId, 
          invoiceAmt, invoiceAmtPerYr, arrAmtPerYr, creditAmt, seats, amplifyHrs, extremeHrs, vmrs, recordingHrs, 
          totalSeats, totalAmplifyHrs, totalVmrs, totalRecordingHrs, cumArrAmtPerYr, arrAmtChg, tierChg, seatsChg, termDaysChg, vmrsChg, 
          isNew, isRenewal, isLateRenew, renewGapDays, isCreditMemo, isFeature, isUpDngrade, isExpansion, isChurn )

        SELECT DISTINCT
          [xrf_index].[xrfIndexId] AS 'xrfIndexId'
        , [xrf_index].[baseSubscriptionId] AS 'baseSubscriptionId'
        , [xrf_index].[subscriptionId] AS 'subscriptionId'
        , [xrf_index].[salesOrderId]  AS 'salesOrderId'
        , [xrf_index].[salesOrderItemLineId]  AS 'salesOrderLineId'
        , [xrf_index].[invoiceId]  AS 'invoiceId'
        , [xrf_index].[invItemLineId]  AS 'invoiceLineId'
        , [xrf_index].[invItemId]  AS 'invItemId'
        , [xrf_index].[salesOrderItemId]  AS 'soItemId'
--2
        , [xrf_index].[salesOrgId]  AS 'salesOrgId'
        , [xrf_index].[salesOutId]  AS 'salesOutId'
        , [xrf_index].[salesOutLineId]  AS 'salesOutLineId'
        , [xrf_index].[classId]  AS 'classId'
        , [xrf_index].[itemId] AS 'itemId'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_bill_to_customer],-1) AS 'billToCustomerId'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_end_customer],-1) AS 'endCustomerId'
        , -1 AS resellerId   --, ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_end_customer],-1) AS 'resellerId'
        , [vw_custom_subscription].[customFieldList-custrecord_subscription_start_date] AS 'startDateId'
        , [vw_custom_subscription].[customFieldList-custrecord_subscription_end_date] AS 'endDateId'
--3
        , [vw_custom_subscription].[customFieldList-custrecord_subscription_cost] AS 'invoiceAmt'   -- Should we be using invoice_dim.rate???

        , CONVERT(money,
            CASE WHEN sub2.entitledDays > 0 
                  THEN [vw_custom_subscription].[customFieldList-custrecord_subscription_cost]*(365.0/sub2.entitledDays)
                  ELSE 0
           END    ) AS 'invoiceAmtPerYr'

        , CONVERT(money,ISNULL(
          ( CASE 
              WHEN sub2.entitledDays > 0 
                THEN [vw_custom_subscription].[customFieldList-custrecord_subscription_cost]
                ELSE 0
             END 
          + ISNULL(CASE WHEN (sub2.refTypeId < 9) AND (sub2.RefType != 'CreditMemo')
                THEN
                    CASE WHEN DATEDIFF(DD,sub2.startDate,sub1.endDate) > 0   -- CONVERT(int,sub1.endDate-sub2.startDate) > 0
                        THEN ISNULL(CONVERT(money,(1.0*[dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate)/sub1.entitledDays)*sub1.invoiceAmount),0)
                    END
                ELSE 0
             END,0 ) ) * (365.0/sub2.entitledDays)
        ,0) ) AS 'arrAmtPerYr'

        , CONVERT(money,ISNULL(
            CASE WHEN (sub2.refTypeId < 9) AND (sub2.RefType != 'CreditMemo')
              THEN
                  CASE WHEN DATEDIFF(DD,sub2.startDate,sub1.endDate) > 0  --CONVERT(int,sub1.endDate-sub2.startDate)
                      THEN ISNULL(CONVERT(money,(1.0*[dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate)/sub1.entitledDays)*sub1.invoiceAmount),0)
                  END
             END, 0) ) AS 'creditAmt'

--        , [customSubscriptionTierDefault].[tierLvl] AS 'tierLvl'                              -- Not using [customSubscriptionTierDefault].[tierLvl] here
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_number_of_seats_2],0) AS 'seats'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_amplify_hours],0) AS 'amplifyHrs'
        , ISNULL(CONVERT(int, [vw_custom_subscription].[customFieldList-custrecord_number_of_seats]),0) AS 'extremeHrs'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_vmrs],0) AS 'vmrs'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_recording_hours],0) AS 'recordingHrs'
--4
        , 0 AS 'totalSeats'
        , 0 AS 'totalAmplifyHrs'
        , 0 AS 'totalVmrs'
        , 0 AS 'totalRecordingHrs'
        , 0 AS 'cumArrAmtPerYr'
        , CONVERT(int,SIGN(sub2.invoiceAmount-sub1.invoiceAmount)) AS 'arrAmtChg'
        , CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] IS NULL 
            THEN SIGN(sub2.tierLvl-sub1.tierLvl) 
            ELSE 0
          END AS 'tierChg'
        , SIGN(sub2.seats-sub1.seats) AS 'seatsChg'
        , SIGN(sub2.entitledDays-sub1.entitledDays) AS 'termDaysChg' -- Term chg
        , SIGN(sub2.maxVMRs-sub1.maxVMRs) AS 'vmrsChg'
--5
        , 0 AS 'isNew'
        , CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_reference_type] IN (5, 7, 8) 
            THEN 1
            ELSE 0
          END AS 'isRenewal'
        , CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_reference_type] IN (5, 7, 8) AND DATEDIFF(DD,sub2.invoiceDate,sub1.endDate) < 0  -- CONVERT(int,sub1.endDate-sub2.invoiceDate) < 0
              THEN 1
              ELSE 0
          END AS 'isLateRenew'
        , [dbo].[ufn_datediff_365](sub2.invoiceDate, sub1.endDate) AS 'renewGapDays'
        , 0 AS 'isCreditMemo'
        , CASE 
            WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] IS NOT NULL THEN 1
            ELSE 0
          END AS 'isFeature'
        , 0 AS 'isUpDngrade'
        , 0 AS 'isExpansion'
        , 0 AS 'isChurn'
        -- INTO [fact_arr]
        FROM [vw_custom_subscription]
        JOIN [xrf_index] ON [xrf_index].[subscriptionId] = [vw_custom_subscription].[internalId]
        JOIN [vw_subscription_sequence] x ON x.sub2 = [vw_custom_subscription].[internalId]
        JOIN [vw_subscription_list] sub1 ON sub1.baseSubscriptionId = x.Base AND sub1.subscriptionId = x.sub1
        JOIN [vw_subscription_list] sub2 ON sub2.baseSubscriptionId = x.Base AND sub2.subscriptionId = x.sub2
        WHERE [xrf_index].[isBase] != 1
        ORDER BY 1, 2  ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        -- Insert new subscriptions
        INSERT INTO [fact_arr]
        ( xrfIndexId, baseSubscriptionId, subscriptionId, salesOrderId, salesOrderItemLineId, invoiceId, invItemLineId, invItemId, salesOrderItemId, 
          salesOrgId, salesOutId, salesOutLineId, classId, itemId, billToCustomerId, endCustomerId, resellerId, startDateId, endDateId, 
          invoiceAmt, invoiceAmtPerYr, arrAmtPerYr, creditAmt, seats, amplifyHrs, extremeHrs, vmrs, recordingHrs, 
          totalSeats, totalAmplifyHrs, totalVmrs, totalRecordingHrs, cumArrAmtPerYr, arrAmtChg, tierChg, seatsChg, termDaysChg, vmrsChg, 
          isNew, isRenewal, isLateRenew, renewGapDays, isCreditMemo, isFeature, isUpDngrade, isExpansion, isChurn )
        SELECT DISTINCT
          [xrf_index].[xrfIndexId]
        , [xrf_index].[baseSubscriptionId] AS 'baseSubscriptionId' 
        , [xrf_index].[subscriptionId] AS 'subscriptionId'
        , [xrf_index].[salesOrderId]  AS 'salesOrderId'
        , [xrf_index].[salesOrderItemLineId]  AS 'salesOrderLine'
        , [xrf_index].[invoiceId]  AS 'invoiceId'
        , [xrf_index].[invItemLineId]  AS 'invoiceLine'
        , [xrf_index].[invItemId]  AS 'invItemId'
        , [xrf_index].[salesOrderItemId]  AS 'soItemId'
--2
        , [xrf_index].[salesOrgId]  AS 'salesOrgId'
        , [xrf_index].[salesOutId]  AS 'salesOutId'
        , [xrf_index].[salesOutLineId]  AS 'salesOutLine'
        , [xrf_index].[classId]  AS 'classId'
        , [vw_custom_subscription].[customFieldList-custrecord_subscription_item] AS 'itemId'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_bill_to_customer],-1) AS 'billToCustomerId'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_subscription_end_customer],-1) AS 'endCustomerId'
        , [xrf_index].[resellerId] AS 'resellerId'  
        , [vw_custom_subscription].[customFieldList-custrecord_subscription_start_date] AS 'startDateId'
        , [vw_custom_subscription].[customFieldList-custrecord_subscription_end_date] AS 'endDateId'
--3
        , [vw_custom_subscription].[customFieldList-custrecord_subscription_cost] AS 'invoiceAmt'   -- Should we be using invoice_dim.rate???
        , CONVERT(money,
            CASE WHEN  [dbo].[ufn_datediff_365]([vw_custom_subscription].[customFieldList-custrecord_subscription_start_date], [vw_custom_subscription].[customFieldList-custrecord_subscription_end_date]) > 0 
                  THEN [vw_custom_subscription].[customFieldList-custrecord_subscription_cost]*(365.0/[dbo].[ufn_datediff_365]([vw_custom_subscription].[customFieldList-custrecord_subscription_start_date], [vw_custom_subscription].[customFieldList-custrecord_subscription_end_date]))
                  ELSE 0
           END    ) AS 'invoiceAmtPerYr'

        , CONVERT(money,
            ISNULL(
              CASE 
                WHEN [dbo].[ufn_datediff_365]([vw_custom_subscription].[customFieldList-custrecord_subscription_start_date], [vw_custom_subscription].[customFieldList-custrecord_subscription_end_date] ) > 0 
                  THEN [vw_custom_subscription].[customFieldList-custrecord_subscription_cost]
                  ELSE 0
               END  * (365.0/[dbo].[ufn_datediff_365]([vw_custom_subscription].[customFieldList-custrecord_subscription_start_date], [vw_custom_subscription].[customFieldList-custrecord_subscription_end_date] ) )
            ,0) ) AS 'arrAmtPerYr'

        , 0 AS 'CreditAmt'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_number_of_seats_2],0) AS 'seats'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_amplify_hours],0) AS 'amplifyHrs'
        , ISNULL(CONVERT(int, [vw_custom_subscription].[customFieldList-custrecord_number_of_seats]),0) AS 'extremeHrs'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_vmrs],0) AS 'vmrs'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_recording_hours],0) AS 'recordingHrs'
--4  
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_number_of_seats_2],0) AS 'totalSeats'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_amplify_hours],0) AS 'totalAmplifyHrs'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_vmrs],0) AS 'totalVmrs'
        , ISNULL([vw_custom_subscription].[customFieldList-custrecord_recording_hours],0) AS 'totalRecordingHrs'
        , 0 AS 'cumArrAmtPerYr'
        , 0 AS 'arrAmtChg'
        , 0 AS 'tierChg'
        , 0 AS 'seatsChg'
        , 0 AS 'termDaysChg'
        , 0 AS 'vmrsChg'
--5
        , 1 AS 'isNew'
        , 0 AS 'isRenewal'
        , 0 AS 'isLateRenew'
        , 0 AS 'renewGapDays'
        , 0 AS 'iscreditMemo'
        , 0 AS 'isFeature'
        , 0 AS 'isUpDngrade'
        , 0 AS 'isExpansion'
        , 0 AS 'isChurn'
        FROM [vw_custom_subscription]
        JOIN [xrf_index] ON [xrf_index].[subscriptionId] = [vw_custom_subscription].[internalId]
         AND [xrf_index].[isBase] = 1;

         -- log results
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        -- Now insert Credit Memos
        INSERT INTO [fact_arr]
        ( xrfIndexId, baseSubscriptionId, subscriptionId, salesOrderId, salesOrderItemLineId, invoiceId, invItemLineId, invItemId, salesOrderItemId, 
          salesOrgId, salesOutId, salesOutLineId, classId, itemId, billToCustomerId, endCustomerId, resellerId, startDateId, endDateId, 
          invoiceAmt, invoiceAmtPerYr, arrAmtPerYr, creditAmt, seats, amplifyHrs, extremeHrs, vmrs, recordingHrs, 
          totalSeats, totalAmplifyHrs, totalVmrs, totalRecordingHrs, cumArrAmtPerYr, arrAmtChg, tierChg, seatsChg, termDaysChg, vmrsChg, 
          isNew, isRenewal, isLateRenew, renewGapDays, isCreditMemo, isFeature, isUpDngrade, isExpansion, isChurn )
        SELECT DISTINCT
          [fact_arr].[xrfIndexId] AS 'xrfIndexId'
        , [fact_arr].[baseSubscriptionId] AS 'baseSubscriptionId'
        , [fact_arr].[subscriptionId] AS 'subscriptionId'
        , [fact_arr].[salesOrderId] AS 'salesOrderId'
        , [fact_arr].[salesOrderItemLineId] AS 'salesOrderItemLineId'
        , [fact_arr].[invoiceId] AS 'invoiceId'
        , [fact_arr].[invItemLineId] AS 'invItemLineId'
        , [fact_arr].[invItemId] AS 'invItemId'
        , [fact_arr].[salesOrderItemId] AS 'salesOrderItemId'
--2
        , [fact_arr].[salesOrgId] AS 'salesOrgId'
        , [fact_arr].[salesOutId] AS 'salesOutId'
        , [fact_arr].[salesOutLineId] AS 'salesOutLineId'
        , [fact_arr].[classId] AS 'classId'
        , [fact_arr].[itemId] AS 'itemId'
        , [fact_arr].[billToCustomerId] AS 'billToCustomerId'
        , [fact_arr].[endCustomerId] AS 'endCustomerId'
        , [fact_arr].[resellerId] AS 'resellerId'
        , [fact_arr].[startDateId] AS 'startDateId'
        , [fact_arr].[endDateId] AS 'endDateId'
--3
        , -1.0*[dim_creditmemo].[rate] AS 'invoiceAmt'
        , -1.0*[fact_arr].[invoiceAmtPerYr] AS 'invoiceAmtPerYr'
        , -1.0*[fact_arr].[arrAmtPerYr] AS 'arrAmtPerYr'
        , -1.0*[fact_arr].[creditAmt] AS 'creditAmt'
        , [fact_arr].[seats] AS 'seats'
        , [fact_arr].[amplifyHrs] AS 'amplifyHrs'
        , [fact_arr].[vmrs] AS 'extremeHrs'
        , [fact_arr].[vmrs] AS 'vmrs'
        , [fact_arr].[recordingHrs] AS 'recordingHrs'
--4
        , [fact_arr].[totalSeats] AS 'totalSeats'
        , [fact_arr].[totalAmplifyHrs] AS 'totalAmplifyHrs'
        , [fact_arr].[totalVmrs] AS 'totalVmrs'
        , [fact_arr].[totalRecordingHrs] AS 'totalRecordingHrs'
        , [fact_arr].[cumARRAmtPerYr] AS 'cumARRAmtPerYr'
        , [fact_arr].[arrAmtChg] AS 'arrAmtChg'
        , [fact_arr].[tierChg] AS 'tierChg'
        , [fact_arr].[seatsChg] AS 'seatsChg'
        , [fact_arr].[termDaysChg] AS 'termDaysChg'
        , [fact_arr].[vmrsChg] AS 'vmrsChg'
--5
        , [fact_arr].[isNew] AS 'isNew'
        , [fact_arr].[isRenewal] AS 'isRenewal'
        , [fact_arr].[isLateRenew] AS 'isLateRenew'
        , [fact_arr].[renewGapDays] AS 'renewGapDays'
        , 1 AS 'isCreditMemo'
        , [fact_arr].[isFeature] AS 'isFeature'
        , [fact_arr].[isUpDngrade] AS 'isUpDngrade'
        , [fact_arr].[isExpansion] AS 'isExpansion'
        , [fact_arr].[isChurn] AS 'isChurn' 
        FROM [dim_creditmemo] 
        JOIN [fact_arr] ON [fact_arr].[subscriptionId] = [dim_creditmemo].[subscriptionId]
        WHERE [fact_arr].[isCreditMemo] = 0
        ;
         -- log results
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

 
        -- set ARR values invoiceAmtPerYr, arrAmtPerYr and creditAmt
        UPDATE fact_arr SET 

        invoiceAmtPerYr =  CONVERT(money,
            CASE WHEN sub2.entitledDays > 0 
                  THEN [vw_custom_subscription].[customFieldList-custrecord_subscription_cost]*(365.0/sub2.entitledDays)
                  ELSE 0
           END    )

        , arrAmtPerYr = CONVERT(money,ISNULL(
          ( CASE 
              WHEN sub2.entitledDays > 0 
                THEN [vw_custom_subscription].[customFieldList-custrecord_subscription_cost]
                ELSE 0
             END 
          + ISNULL(CASE WHEN (sub2.refTypeId < 9) AND (sub2.RefType != 'CreditMemo')
                THEN
                    CASE WHEN DATEDIFF(DD,sub2.startDate,sub1.endDate) > 0   -- CONVERT(int,sub1.endDate-sub2.startDate) > 0
                        THEN ISNULL(CONVERT(money,(1.0*[dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate)/sub1.entitledDays)*sub1.invoiceAmount),0)
                    END
                ELSE 0
             END,0 ) ) * (365.0/sub2.entitledDays)
        ,0) )

        , creditAmt = CONVERT(money,ISNULL(
            CASE WHEN (sub2.refTypeId < 9) AND (sub2.RefType != 'CreditMemo')
              THEN
                  CASE WHEN DATEDIFF(DD,sub2.startDate,sub1.endDate) > 0  --CONVERT(int,sub1.endDate-sub2.startDate)
                      THEN ISNULL(CONVERT(money,(1.0*[dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate)/sub1.entitledDays)*sub1.invoiceAmount),0)
                  END
             END, 0) )


        -- For Features zero out termDays and vmrs, set AmtChg to sign of invoiceAmt
        -- Still need to set to zero when comparing Feature to next subscription
        UPDATE [fact_arr] SET
          [arrAmtChg] = SIGN(arrAmtChg)
        , [tierChg] = 0
        , [seatsChg] = 0
        , [termDaysChg] = 0
        , [vmrsChg] = 0
        WHERE isFeature = 1 ;

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
    
    RAISERROR ( @ErrMessage, @ErrSeverity, @ErrState );  
END CATCH;  



GO


