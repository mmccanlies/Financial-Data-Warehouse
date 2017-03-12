USE [sandbox_mike]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
**                                    sp_dim_subscription_details
** 
** Load dim_subscription and do extra updates
** dependencies:        dim_subscription        vw_custom_subscription  -- must be loaded and updated before calling this procedure
**                      fact_arr
**                      dim_salesorder
** 
** created:  3/07/2017   mmccanlies 
** revised:  3/07/2017      "            Revised to use source views instead of source tables 
**************************************************************************************************/
ALTER PROCEDURE [sp_dim_subscription_details]
(
    @Rebuild   bit = 1,        -- 1 = Truncate and rebuild
    @Debug     bit = 0         -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_dim_subscription_details '
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
            TRUNCATE TABLE [dim_subscription_details]

        -- Major Code Sections --
        INSERT INTO [dim_subscription_details]
        ( xrfIndexId, baseSubscriptionId, subscriptionId, prevSubscriptionId, creditMemoNo, refTypeId, refTypeTxt, tierName, tierLvl, prefix, entitlementTerm, priceTerm, seats, totalSeats
        , startDate, endDate, entitledDays, termDays, invoiceAmount, arrAmtPerYr, totalArrAmtPerYr, arrDelta, amplifyQty, extremeQty, vmrsQty, recordingHrs, arrAmtChg
        , entitlementChg, tierChg, seatChg, daysBtwPriorEndAndCurrStart, daysTilExpiration, isCreditMemo, termChg, newBase, updateOrdr, baseIdOrdr
        )
        SELECT 
          [dim_subscription].[xrfIndexId] 
        , [dim_subscription].[baseSubscriptionId]
        , [dim_subscription].[subscriptionId]
        , NULL AS 'prevSubscriptionId'
        , [dim_subscription].[creditMemoNo]
        , [dim_subscription].[refTypeId]
        , [dim_subscription].[refTypeTxt]
        , [dim_subscription].[tierName]
        , [dim_subscription].[tierLvl]
        , '' AS 'prefix'
        , '' AS 'entitlementTerm'
        , '' AS 'priceTerm'

        , [dim_subscription].[seats]
        , [dim_subscription].[seats]
        + CASE WHEN [dim_subscription].[refTypeId] != 10
            THEN (SELECT ISNULL(SUM(s2.seats),0) FROM [dim_subscription] s2 WHERE s2.baseSubscriptionId = [dim_subscription].baseSubscriptionId AND s2.refTypeId = 10 AND s2.startDate BETWEEN [dim_subscription].startDate AND DATEADD(DD,-1,[dim_subscription].endDate) ) 
            ELSE  [dim_subscription].[seats]
          END AS 'totalSeats'
        , [dim_subscription].[startDate]
        , [dim_subscription].[endDate]
        , [dim_subscription].[entitledDays]
        , [dim_salesorder].[soTermDays] AS 'termDays'
        , [dim_subscription].[invoiceAmount]
        , [fact_arr].[arrAmtPerYr]
        , [fact_arr].[arrAmtPerYr]
        + CASE WHEN [dim_subscription].[refTypeId] != 10
            THEN (SELECT ISNULL(SUM(f2.arrAmtPerYr),0) FROM [fact_arr] f2 WHERE f2.baseSubscriptionId = [dim_subscription].baseSubscriptionId AND f2.isAddSeats = 1 AND f2.startDateId BETWEEN [dim_subscription].startDate AND DATEADD(DD,-1,[dim_subscription].endDate) )  
            ELSE  0
          END AS 'totalArrAmtPerYr'
        , 0 AS 'arrDelta'
        , 0 AS 'amplifyQty'
        , 0 AS 'extremeQty'
        , 0 AS 'vmrsQty'
        , 0 AS 'recordingHrs'
        , 0 AS 'arrAmtChg'
        , 0 AS 'entitlementChg'
        , 0 AS 'tierChg'
        , 0 AS 'seatChg'
        , 0 AS 'daysBtwPriorEndAndCurrStart'
        , 0 AS 'daysTilExpiration'
        , [dim_subscription].[isCreditMemo] AS 'isCreditMemo'
        , 0 AS 'termChg'
        , CASE WHEN [dim_subscription].[refTypeId] IN (4,5,6,7,8) AND [dim_subscription].[CreditMemoNo] IS NULL
            THEN 1
            ELSE 0
          END AS 'newBase'
        , CASE WHEN [dim_subscription].[refTypeId] IN (4,5,6,7,8) AND [dim_subscription].[CreditMemoNo] IS NULL  -- [dim_subscription].[isCreditMemo] = 0
            THEN DENSE_RANK() OVER ( PARTITION BY [dim_subscription].[baseSubscriptionId] ORDER BY [dim_subscription].[baseSubscriptionId], [dim_subscription].[startDate] ) 
            ELSE -1
          END AS 'updateOrdr'
        , DENSE_RANK() OVER ( PARTITION BY [dim_subscription].[baseSubscriptionId] ORDER BY [dim_subscription].[startDate], [dim_subscription].[SubscriptionId], [fact_arr].[arrAmtPerYr] ) AS baseIdOrdr
        --  INTO [dim_subscription_details]
        FROM [dim_subscription]
        JOIN [fact_arr] ON [fact_arr].[subscriptionId] = [dim_subscription].[subscriptionId]
         AND [dim_subscription].[isCreditMemo] =  [fact_arr].[isCreditMemo]
        JOIN [dim_salesorder] ON [dim_salesorder].[salesOrderId] = [dim_subscription].[salesOrderId]
         AND [dim_salesorder].[salesOrderLine] = [dim_subscription].[salesOrderLine]
        ORDER BY [dim_subscription].[baseSubscriptionId], [dim_subscription].[startDate] ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

    COMMIT TRANSACTION

    BEGIN TRANSACTION

        -- Set prior subscriptionId for all renewals and upgrades
        UPDATE [dim_subscription_details] SET
          [prevSubscriptionId] = ( SELECT TOP 1 sd2.[subscriptionId] FROM [dim_subscription_details] sd2 WHERE sd2.[baseSubscriptionId] = [dim_subscription_details].[baseSubscriptionId] AND sd2.[updateOrdr] < [dim_subscription_details].[updateOrdr] AND sd2.[newBase] = 1 ORDER BY [updateOrdr] DESC )
        FROM [dim_subscription_details] 
        WHERE [newBase] = 1

        -- Set Entitlement values for Features  -- Could also set a featureOrdr here
        UPDATE [dim_subscription_details] SET
          amplifyQty = CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'Ampl%'
                         THEN ISNULL(CONVERT(int,[vw_custom_subscription].[customFieldList-custrecord_amplify_hours]),0)
                         ELSE 0
                       END 
        , extremeQty = CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'Extr%'
                         THEN ISNULL(CONVERT(int, [vw_custom_subscription].[customFieldList-custrecord_number_of_seats]),0)
                         ELSE 0
                       END
        , vmrsQty =    CASE WHEN [vw_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'VMR%'
                         THEN ISNULL([vw_custom_subscription].[customFieldList-custrecord_vmrs],0)
                         ELSE 0
                       END 
        FROM [dim_subscription_details] 
        JOIN [vw_custom_subscription] ON ISNULL(CONVERT(int, [vw_custom_subscription].[internalId]),-1) = [dim_subscription_details].[subscriptionId]
        AND [dim_subscription_details].[refTypeId] = 9

        -- Set daysTilExpiration on the last subscription
        UPDATE sub1 SET
          sub1.daysTilExpiration = y.daysTilExpiration
        FROM dim_subscription_details sub1
        JOIN
             (  SELECT sub1.baseSubscriptionId, sub2.subscriptionId, MAX(sub1.endDate) AS 'subscriptionEndDate'
                , DATEDIFF(DD, sysdatetime(),MAX(sub1.endDate)) AS 'daysTilExpiration'
                FROM dim_subscription_details sub1
                JOIN dim_subscription_details sub2 ON sub2.baseSubscriptionId = sub1.baseSubscriptionId 
                 AND sub2.refTypeId IN (4,5,7,8)
                GROUP BY sub1.baseSubscriptionId, sub2.endDate, sub2.subscriptionId
                HAVING sub2.endDate = MAX(sub1.endDate)
             ) y ON y.subscriptionId = sub1.subscriptionId 

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;
    COMMIT TRANSACTION

    BEGIN TRANSACTION

        -- Set Chg fields
        UPDATE sd1 SET
          arrDelta = CONVERT(money,sd1.[totalArrAmtPerYr]-sd2.[totalArrAmtPerYr])
        , arrAmtChg = CONVERT(int,SIGN(sd1.[totalArrAmtPerYr]-sd2.[totalArrAmtPerYr]))
        , entitlementChg = 
            CASE WHEN SIGN(sd1.[tierLvl]-sd2.[tierLvl]) != 0 OR SIGN(sd1.[totalSeats]-sd2.[totalSeats]) != 0
              THEN 
                  CASE WHEN sd1.[tierLvl] != sd2.[tierLvl]
                      THEN SIGN(sd1.[tierLvl]-sd2.[tierLvl])
                      ELSE CASE WHEN sd1.[totalSeats] != sd2.[totalSeats]
                               THEN SIGN(sd1.[totalSeats]-sd2.[totalSeats])
                               ELSE 0
                           END
                  END
              ELSE 0
            END
        , tierChg = SIGN(sd1.[tierLvl]-sd2.[tierLvl])
        , seatChg = SIGN(sd1.[totalSeats]-sd2.[totalSeats])
        , daysBtwPriorEndAndCurrStart = DATEDIFF(DD,sd2.endDate,sd1.startDate)
        , termChg = SIGN(sd1.[termDays]-sd2.[termDays])
        FROM [dim_subscription_details] sd1
        JOIN [dim_subscription_details] sd2 ON sd2.subscriptionId = sd1.prevSubscriptionId
        WHERE sd1.newBase = 1  
        ;
        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        -- Set entitlementTerm and priceTerm on Add Seats and Features
        UPDATE [dim_subscription_details] SET
          entitlementTerm = 'Upgrade '
        , priceTerm = 'Expansion' 
        FROM [dim_subscription_details] 
        WHERE refTypeId IN (9,10)
        ;
        -- Set entitlementTerm and priceTerm on New, Renewals and Upgrades
        UPDATE [dim_subscription_details] SET
          prefix =  CASE WHEN baseSubscriptionId = subscriptionId
                         THEN 'New'
                         ELSE ''
                    END 
        , entitlementTerm = 
                              CASE entitlementChg 
                                WHEN  1 THEN 'Upgrade '
                                WHEN  0 THEN 
                                              CASE  
                                                WHEN arrAmtChg > 0  THEN 'Price '
                                                WHEN arrAmtChg < 0  THEN
                                                    CASE  
                                                      WHEN  termChg < 0 THEN 'Price '
                                                      ELSE 'Term Extension '
                                                    END
                                                ELSE ''
                                              END
                                WHEN -1 THEN 'Downgrade '
                              END
        , priceTerm =         CASE WHEN (baseSubscriptionId != subscriptionId) 
                                THEN  CASE arrAmtChg 
                                        WHEN  1 THEN 'Expansion'
                                        WHEN  0 THEN ''
                                        WHEN -1 THEN 'Churn'
                                      END 
                                ELSE ''
                            END
        FROM [dim_subscription_details] 
        WHERE newBase=1
        ;

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
