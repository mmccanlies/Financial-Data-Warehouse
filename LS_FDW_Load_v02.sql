/***************************************************************************************************************************
**                                          xrf_index
** by: mmccanlies       02/04/2017
** Load xrf_index table
***************************************************************************************************************************/
-- xrf_index
--DROP TABLE [xrf_index]
-- TRUNCATE TABLE [xrf_index]
GO

INSERT INTO [xrf_index] 
( baseSubscriptionId, subscriptionId, isBase, salesOrderId, salesOrderLine, classId, invoiceId, invoiceLine
, soItemId, invItemId, salesOutId, salesOutLine, salesOrgId, billCustomerId, endCustomerId, resellerId )
SELECT DISTINCT 
  CONVERT(int,[ns_custom_subscription].[customFieldList-custrecord_base_subscription]) AS 'baseSubscriptionId'
, CONVERT(int,[ns_custom_subscription].[internalId]) AS 'subscriptionId'
, CAST([customFieldList-custrecord_base_subscription_flag] AS int) AS 'isBase'
, ISNULL(CAST([ns_custom_subscription].[customFieldList-custrecord_subscription_transaction] AS int),-1)  AS 'salesOrderId'
, TRY_CAST(ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_transaction_line],1) AS numeric)  AS 'salesOrderLine'
, ISNULL(CAST([ns_salesorder_itemlist].[class-internalId] AS int),-1) AS 'classId'
, ISNULL(CAST([ns_invoice].[internalId] AS int),-1) AS 'invoiceId'
, TRY_CAST(ISNULL([ns_invoice_itemlist].[customFieldList-custcol_line_id],1) AS numeric) AS 'invoiceLine'      --varchar(50)
, ISNULL(CAST([ns_salesorder_itemlist].[item-internalId] AS int),-1) AS 'soItemId'
, ISNULL(CAST([ns_invoice_itemlist].[item-internalId] AS int),-1) AS 'invItemId'
, ISNULL(CAST([ns_custom_sales_out].[internalId] AS int),-1) AS 'salesOutId'
, ISNULL(TRY_CAST([ns_custom_sales_out].[customFieldList-custrecord_sales_out_original_line_num] AS int),1) AS 'salesOutLine'
, ISNULL([ns_salesOrder].[customFieldList-custbody_om_salesperson],-1) AS 'salesOrgId'
, ISNULL(CAST([ns_salesorder].[customFieldList-custbody_bill_customer] AS int),-1) AS 'billCustomerId'
, ISNULL(CAST([ns_salesorder].[customFieldList-custbody_end_customer] AS int),-1) AS 'endCustomerId'
, -1 AS 'resellerId'
--INTO [xrf_index]
FROM [ns_custom_subscription] 
JOIN [ns_nonInventorySaleItem] ON [ns_nonInventorySaleItem].[internalId] = [ns_custom_subscription].[customFieldList-custrecord_subscription_item] 
LEFT OUTER JOIN [ns_salesorder] ON [ns_salesorder].[internalId] = [ns_custom_subscription].[customFieldList-custrecord_subscription_transaction]
LEFT OUTER JOIN [ns_salesorder_itemlist] ON [ns_salesorder_itemlist].[internalId] = [ns_salesorder].[internalId]
		    AND TRY_CAST(ISNULL([ns_salesorder_itemlist].[line],1) AS numeric) = TRY_CAST(ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_transaction_line],1) AS numeric)  -- Added
LEFT OUTER JOIN [ns_invoice] ON [ns_invoice].[createdFrom-internalId] = [ns_salesorder].[internalId]
LEFT OUTER JOIN [ns_invoice_itemlist] ON [ns_invoice_itemlist].[internalId] = [ns_invoice].[internalId] 
	        AND TRY_CAST(ISNULL([ns_invoice_itemlist].[customFieldList-custcol_line_id],1) AS numeric) = TRY_CAST(ISNULL([ns_salesorder_itemlist].[customFieldList-custcol_line_id],1) AS numeric)   -- Added
LEFT OUTER JOIN [ns_custom_sales_out] ON [ns_custom_sales_out].[customFieldList-custrecord_sales_out_original_trans] = [ns_invoice].[internalId]
            AND [ns_salesorder_itemlist].[customFieldList-custcol_line_id] = [customFieldList-custrecord_sales_out_original_line_num]  -- Added
LEFT OUTER JOIN [ns_customer] bill_cust ON bill_cust.[internalId] = [ns_salesorder].[customFieldList-custbody_bill_customer] 
LEFT OUTER JOIN [ns_customer] end_cust ON end_cust.[internalId] = [ns_salesorder].[customFieldList-custbody_end_customer] 
ORDER BY CONVERT(int,[ns_custom_subscription].[customFieldList-custrecord_base_subscription])
       , CONVERT(int,[ns_custom_subscription].[internalId])
GO

UPDATE [all_index_xrf] SET
  salesOrderId = ISNULL(CAST([ns_salesorder].[internalId] AS int),-1)
, invoiceId =ISNULL(CAST([ns_invoice].[internalId] AS int),-1)
FROM [ns_invoice]
JOIN [ns_salesOrder] ON [ns_invoice].[otherRefNum] = [ns_salesOrder].[otherRefNum]
AND ( CONVERT(date, [ns_salesOrder].[tranDate]) = CONVERT(date,[ns_invoice].[customFieldList-custbody_order_date]) 
    OR [ns_invoice].[total] = [ns_salesOrder].[total] )
JOIN [all_index_xrf] ON [all_index_xrf].[salesOrderId] = [ns_salesorder].[internalId]
WHERE [all_index_xrf].[invoiceId] = -1

SELECT * from invoice_dim

/***************************************************************************************************************************
**                                          fact_arr
** by: mmccanlies       02/05/2017
** Load arr_fact table
***************************************************************************************************************************/
-- DROP TABLE [fact_arr]
-- TRUNCATE TABLE [fact_arr]
-- Insert subscription renewals and changes

INSERT INTO [fact_arr]
( baseSubscriptionId, subscriptionId, salesOrderId, salesOrderLine, invoiceId, invoiceLine, invItemId, soItemId, 
  salesOrgId, salesOutId, salesOutLine, classId, itemId, billToCustomerId, endCustomerId, startDateId, endDateId, 
  arrAmt, invoiceAmt, creditAmt, seats, amplifyHrs, recordingHours, vmrs, arrAmtChg, tierChg, seatsChg, termDaysChg, 
  vmrsChg, isNew, isRenewal, isLateRenew, renewGapDays, creditMemo, isFeature, UpDngrade, isExpansion, isChurn )

SELECT DISTINCT
  [vw_test_grp].[baseSubscriptionId] AS 'baseSubscriptionId'
, [ns_custom_subscription].[internalId] AS 'subscriptionId'
, [vw_test_grp].[salesOrderId]  AS 'salesOrderId'
, [vw_test_grp].[salesOrderLine]  AS 'salesOrderLine'
, [vw_test_grp].[invoiceId]  AS 'invoiceId'
, [vw_test_grp].[invoiceLine]  AS 'invoiceLine'
, [vw_test_grp].[invItemId]  AS 'invItemId'
, [vw_test_grp].[soItemId]  AS 'soItemId'
, [vw_test_grp].[salesOrgId]  AS 'salesOrgId'
, [vw_test_grp].[salesOutId]  AS 'salesOutId'
, [vw_test_grp].[salesOutLine]  AS 'salesOutLine'
, [vw_test_grp].[classId]  AS 'classId'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_item] AS 'itemId'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_bill_to_customer],-1) AS 'billToCustomerId'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_end_customer],-1) AS 'endCustomerId'
--, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_end_customer],-1) AS 'resellerId'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_start_date] AS 'startDateId'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date] AS 'endDateId'

, CONVERT(money,ISNULL(
  ( CASE 
      WHEN sub2.entitledDays > 0 
        THEN [ns_custom_subscription].[customFieldList-custrecord_subscription_cost]
        ELSE 0
     END 
  + ISNULL(CASE WHEN (sub2.refTypeId < 9) AND (sub2.RefType != 'CreditMemo')
        THEN
            CASE WHEN CONVERT(int,sub1.endDate-sub2.startDate) > 0
                THEN ISNULL(CONVERT(money,(1.0*[dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate)/sub1.entitledDays)*sub1.invoiceAmount),0)
            END
        ELSE 0
     END,0 ) ) * (365.0/sub2.entitledDays)
,0) ) AS 'arrAmt'

, CONVERT(money,
    CASE WHEN sub2.entitledDays > 0 
          THEN [ns_custom_subscription].[customFieldList-custrecord_subscription_cost]*(365.0/sub2.entitledDays)
          ELSE 0
   END    ) AS 'invoiceAmt'
, CONVERT(money,ISNULL(
    CASE WHEN (sub2.refTypeId < 9) AND (sub2.RefType != 'CreditMemo')
      THEN
          CASE WHEN CONVERT(int,sub1.endDate-sub2.startDate) > 0
              THEN ISNULL(CONVERT(money,(1.0*[dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate)/sub1.entitledDays)*sub1.invoiceAmount),0)
          END
     END, 0) ) AS 'creditAmt'

, ISNULL([ns_custom_subscription].[customFieldList-custrecord_number_of_seats_2],0) AS 'seats'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_amplify_hours],0) AS 'amplifyHrs'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_recording_hours],0) AS 'recordingHours'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_vmrs],0) AS 'vmrs'
, SIGN(sub2.invoiceAmount-sub1.invoiceAmount) AS 'arrAmtChg'
, CASE WHEN [ns_custom_subscription].[customFieldList-custrecord_license_type] IS NULL 
    THEN SIGN(sub2.tierLvl-sub1.tierLvl) 
    ELSE 0
  END AS 'tierChg'
, SIGN(sub2.seats-sub1.seats) AS seatsChg
, SIGN(sub2.entitledDays-sub1.entitledDays) AS 'termDaysChg' -- Term chg
, SIGN(sub2.maxVMRs-sub1.maxVMRs) AS 'vmrsChg'
, 0 AS 'isNew'
, CASE WHEN [ns_custom_subscription].[customFieldList-custrecord_reference_type] IN (5, 7, 8) 
    THEN 1
    ELSE 0
  END AS 'isRenewal'
, CASE WHEN [ns_custom_subscription].[customFieldList-custrecord_reference_type] IN (5, 7, 8) AND CONVERT(int,sub1.endDate-sub2.invoiceDate) < 0
      THEN 1
      ELSE 0
  END AS 'isLateRenew'
, [dbo].[ufn_datediff_365](sub2.invoiceDate, sub1.endDate) AS 'renewGapDays'
, sub2.isCreditMemo AS 'creditMemo'
, CASE 
    WHEN [ns_custom_subscription].[customFieldList-custrecord_license_type] IS NOT NULL THEN 1
	ELSE 0
  END AS 'isFeature'
, 0 AS 'UpDngrade'
, 0 AS 'isExpansion'
, 0 AS 'isChurn'
INTO [fact_arr]
FROM [ns_custom_subscription]
JOIN [vw_test_grp] ON [vw_test_grp].[subscriptionId] = [ns_custom_subscription].[internalId]
JOIN [vw_subsseq_dim] x ON x.sub2 = [ns_custom_subscription].[internalId]
JOIN [vw_subslist_dim] sub1 ON sub1.baseSubscriptionId = x.Base AND sub1.subscriptionId = x.sub1
JOIN [vw_subslist_dim] sub2 ON sub2.baseSubscriptionId = x.Base AND sub2.subscriptionId = x.sub2
WHERE [vw_test_grp].[isBase] != 1
ORDER BY 2, 1


-- Insert new subscriptions
INSERT INTO [fact_arr]
( baseSubscriptionId, subscriptionId, salesOrderId, salesOrderLine, invoiceId, invoiceLine, invItemId, soItemId, 
  salesOrgId, salesOutId, salesOutLine, classId, itemId, billToCustomerId, endCustomerId, startDateId, endDateId, 
  arrAmt, invoiceAmt, creditAmt, seats, amplifyHrs, recordingHours, vmrs, arrAmtChg, tierChg, seatsChg, termDaysChg, 
  vmrsChg, isNew, isRenewal, isLateRenew, renewGapDays, creditMemo, isFeature, UpDngrade, isExpansion, isChurn )
SELECT DISTINCT
  [vw_test_grp].[baseSubscriptionId] AS 'baseSubscriptionId' 
, [ns_custom_subscription].[internalId] AS 'subscriptionId'
, [vw_test_grp].[salesOrderId]  AS 'salesOrderId'
, [vw_test_grp].[salesOrderLine]  AS 'salesOrderLine'
, [vw_test_grp].[invoiceId]  AS 'invoiceId'
, [vw_test_grp].[invoiceLine]  AS 'invoiceLine'
, [vw_test_grp].[invItemId]  AS 'invItemId'
, [vw_test_grp].[soItemId]  AS 'soItemId'
, [vw_test_grp].[salesOrgId]  AS 'salesOrgId'
, [vw_test_grp].[salesOutId]  AS 'salesOutId'
, [vw_test_grp].[salesOutLine]  AS 'salesOutLine'
, [vw_test_grp].[classId]  AS 'classId'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_item] AS 'itemId'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_bill_to_customer],-1) AS 'billToCustomerId'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_end_customer],-1) AS 'endCustomerId'
--, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_end_customer],-1) AS 'resellerId'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_start_date] AS 'startDateId'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date] AS 'endDateId'

, CONVERT(money,
    ISNULL(
      CASE 
        WHEN [dbo].[ufn_datediff_365]([ns_custom_subscription].[customFieldList-custrecord_subscription_start_date], [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date] ) > 0 
          THEN [ns_custom_subscription].[customFieldList-custrecord_subscription_cost]
          ELSE 0
       END  * (365.0/[dbo].[ufn_datediff_365]([ns_custom_subscription].[customFieldList-custrecord_subscription_start_date], [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date] ) )
    ,0) ) AS 'arrAmt'

, CONVERT(money,
    CASE WHEN  [dbo].[ufn_datediff_365]([ns_custom_subscription].[customFieldList-custrecord_subscription_start_date], [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date]) > 0 
          THEN [ns_custom_subscription].[customFieldList-custrecord_subscription_cost]*(365.0/[dbo].[ufn_datediff_365]([ns_custom_subscription].[customFieldList-custrecord_subscription_start_date], [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date]))
          ELSE 0
   END    ) AS 'invoiceAmt'

, 0 AS 'CreditAmt'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_number_of_seats_2],0) AS 'seats'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_amplify_hours],0) AS 'amplifyHrs'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_recording_hours],0) AS 'recordingHours'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_vmrs],0) AS 'vmrs'
, 0 AS 'arrAmtChg'
, 0 AS 'tierChg'
, 0 AS 'seatsChg'
, 0 AS 'termDaysChg'
, 0 AS 'vmrsChg'
, 1 AS 'isNew'
, 0 AS 'isRenewal'
, 0 AS 'isLateRenew'
, 0 AS 'renewGapDays'
, 0 AS 'creditMemo'
, 0 AS 'isFeature'
, 0 AS 'UpDngrade'
, 0 AS 'isExpansion'
, 0 AS 'isChurn'
FROM [ns_custom_subscription]
JOIN [vw_test_grp] ON [vw_test_grp].[subscriptionId] = [ns_custom_subscription].[internalId]
 AND [vw_test_grp].[isBase] = 1
GO


-- Now Update arrAmtChg, termdaysChg, seatsChg, changes based on Feature
UPDATE f2 SET
  termDaysChg = CONVERT(int,SIGN(so2.soTermDays-so1.soTermDays))
FROM [vw_subsseq_dim] x
JOIN [vw_subslist_dim] sub1 ON sub1.baseSubscriptionId = x.Base AND sub1.subscriptionId = x.sub1
JOIN [vw_subslist_dim] sub2 ON sub2.baseSubscriptionId = x.Base AND sub2.subscriptionId = x.sub2
JOIN [vw_test_grp] tg1 ON tg1.baseSubscriptionId = x.Base AND tg1.subscriptionId = x.sub1
JOIN [vw_test_grp] tg2 ON tg2.baseSubscriptionId = x.Base AND tg2.subscriptionId = x.sub2
JOIN [dim_salesorder] so1 ON so1.salesOrderId = tg1.salesOrderId and so1.salesOrderLine = tg1.salesOrderLine
JOIN [dim_salesorder] so2 ON so2.salesOrderId = tg2.salesOrderId and so2.salesOrderLine = tg2.salesOrderLine
JOIN [fact_arr] f1 ON f1.baseSubscriptionId = x.Base AND f1.subscriptionId = x.sub2
WHERE sub1.isBase != 1 AND isFeature != 1

UPDATE f2 SET
  arrAmtChg = CONVERT(int,SIGN(f2.arrAmt-f1.arrAmt)) 
FROM [vw_subsseq_dim] x
JOIN [fact_arr] f1 ON f1.baseSubscriptionId = x.Base AND f1.subscriptionId = x.sub1
JOIN [fact_arr] f2 ON f2.baseSubscriptionId = x.Base AND f2.subscriptionId = x.sub2
WHERE f1.isNew != 1 AND f1.isFeature != 1 AND f2.isFeature != 1

-- For Features zero out termDays and vmrs, set AmtChg to sign of invoiceAmt
-- Still need to set to zero when comparing Feature to next subscription
UPDATE [fact_arr] SET
  [arrAmtChg] = SIGN(arrAmt)
, [tierChg] = 0
, [seatsChg] = 0
, [termDaysChg] = 0
, [vmrsChg] = 0
WHERE isFeature = 1


SELECT 
  x.base
, x.sub1
, x.sub2
, so1.soTermDays
, so2.soTermDays
, CONVERT(int,SIGN(so2.soTermDays-so1.soTermDays)) AS termDaysChg
FROM [vw_subsseq_dim] x
JOIN [vw_subslist_dim] sub1 ON sub1.baseSubscriptionId = x.Base AND sub1.subscriptionId = x.sub1
JOIN [vw_subslist_dim] sub2 ON sub2.baseSubscriptionId = x.Base AND sub2.subscriptionId = x.sub2
JOIN [vw_test_grp] tg1 ON tg1.baseSubscriptionId = x.Base AND tg1.subscriptionId = x.sub1
JOIN [vw_test_grp] tg2 ON tg2.baseSubscriptionId = x.Base AND tg2.subscriptionId = x.sub2
JOIN [dim_salesorder] so1 ON so1.salesOrderId = tg1.salesOrderId and so1.salesOrderLine = tg1.salesOrderLine
JOIN [dim_salesorder] so2 ON so2.salesOrderId = tg2.salesOrderId and so2.salesOrderLine = tg2.salesOrderLine
ORDER BY x.base, x.sub1


SELECT * 
FROM [fact_arr]
ORDER BY CAST(baseSubscriptionId AS int), CAST(subscriptionId AS int)
WHERE isFeature = 1

SELECT * 
FROM [fact_arr]
WHERE subscriptionId = 4207

SELECT * FROM xrf_index WHERE subscriptionId = 4207

UPDATE xrf_index SET isBase = 0 WHERE subscriptionId = 4207

UPDATE [fact_arr] SET
isFeature = 1
WHERE subscriptionId = 4207

SELECT 
  x.base
, x.sub1
, x.sub2
, f1.arrAmt AS arrAmt1
, f2.arrAmt AS arrAmt2
, CONVERT(int,f2.arrAmtChg) AS dbAmtChg
, CONVERT(int,SIGN(f2.arrAmt-f1.arrAmt)) AS calcAmtChg
FROM [vw_subsseq_dim] x
JOIN [fact_arr] f1 ON f1.baseSubscriptionId = x.Base AND f1.subscriptionId = x.sub1
JOIN [fact_arr] f2 ON f2.baseSubscriptionId = x.Base AND f2.subscriptionId = x.sub2
WHERE f1.isNew != 1 AND f1.isFeature != 1 AND f2.isFeature != 1


/***************************************************************************************************************************
-- Original query
INSERT INTO [arr_fact]
( subscriptionId, baseSubscriptionId, salesOrderId, salesOrderLine, invoiceId, invoiceLine, invItemId, soItemId, salesOrgId, 
  salesOutId, salesOutLine, classId, itemId, billToCustomerId, endCustomerId, startDateId, endDateId, isNew, isRenewal, isFeature, 
  UpDngrade, isExpansion, isChurn, amount, seats, amplifyHrs, recordingHours, vmrs )

SELECT DISTINCT
  [ns_custom_subscription].[internalId] AS 'subscriptionId'
, [vw_test_grp].[baseSubscriptionId] AS 'baseSubscriptionId'
, [vw_test_grp].[salesOrderId]  AS 'salesOrderId'
, [vw_test_grp].[salesOrderLine]  AS 'salesOrderLine'
, [vw_test_grp].[invoiceId]  AS 'invoiceId'
, [vw_test_grp].[invoiceLine]  AS 'invoiceLine'
, [vw_test_grp].[invItemId]  AS 'invItemId'
, [vw_test_grp].[soItemId]  AS 'soItemId'
, [vw_test_grp].[salesOrgId]  AS 'salesOrgId'
, [vw_test_grp].[salesOutId]  AS 'salesOutId'
, [vw_test_grp].[salesOutLine]  AS 'salesOutLine'
, [vw_test_grp].[classId]  AS 'classId'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_item] AS 'itemId'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_bill_to_customer],-1) AS 'billToCustomerId'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_end_customer],-1) AS 'endCustomerId'
--, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_end_customer],-1) AS 'resellerId'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_start_date] AS 'startDateId'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date] AS 'endDateId'
, 0 AS 'isNew'
, 0 AS 'isRenewal'
, 0 AS 'isFeature'
, 0 AS 'UpDngrade'
, 0 AS 'isExpansion'
, 0 AS 'isChurn'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_cost],0) AS 'amount'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_number_of_seats_2],0) AS 'seats'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_amplify_hours],0) AS 'amplifyHrs'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_recording_hours],0) AS 'recordingHours'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_vmrs],0) AS 'vmrs'
FROM [ns_custom_subscription]
JOIN [vw_test_grp] ON [vw_test_grp].[subscriptionId] = [ns_custom_subscription].[internalId]
***************************************************************************************************************************/


/***************************************************************************************************************************
**                                          dim_creditmemo
** by: mmccanlies       02/07/2017
** Load dim_creditmemo table
***************************************************************************************************************************/
-- Credit Memo Dim
-- TRUNCATE TABLE [dim_creditmemo]
GO
INSERT INTO [creditmemo_dim]
( creditMemoId, creditMemoLine, creditMemoNo, returnAuthId, rmaId, rmaDescr, rmaText, cmSalesOrderId, cmSource, sourceId, productClass
, cmItemId, cmSkuNo, productFamilyPL, priceName, Qty, units, rate, amt, incomeAcct, departmentName, locName, cmDate, customerPONo
, baseSubscriptionId, subscriptionId, BaseSubscription, subscription, isBase, refType, refTypeId, tier, seats, featureType, featureAmt
, cloudFeatures, vmrsLicenses, featureOrBase, startDate, endDate, entitledYrs, entitledMos, entitledDays, invoiceAmount, invoiceDate
, stdDiscount, ornDiscount, nsdDiscount, nsdApprovalNo, skuNo, endCustomerId, endCustomerName, endCustomerAddr, itemTypeId, itemType
, itemId, salesOrderId, salesOrderLine, subscriptionStatusId, subscriptionStatus )
SELECT DISTINCT
  [ns_creditmemo_ItemList].[internalId] AS 'creditMemoId'
, [ns_creditmemo_ItemList].[line] AS 'creditMemoLine'
, [ns_creditmemo].[tranId] AS 'creditMemoNo'
, ISNULL(CONVERT(int,[ns_creditmemo].[customFieldList-custbody_createdfrom_reporting]),-1) AS 'returnAuthId'
, [ns_creditmemo].[createdFrom-internalId] AS 'rmaId'
, [ns_creditmemo].[createdFrom-name] AS 'rmaDescr'
, [ns_creditMemo].[createdFrom-name] AS 'rmaText'
, [ns_creditMemo].[customFieldList-custbody_rma_sales_order] AS 'cmSalesOrderId'
, [ns_creditMemo].[source] AS 'cmSource'
, [ns_creditMemo].[customFieldList-custbody_creation_source] AS 'sourceId'
--, [ns_creditMemo].[customFieldList-custbody_legacy_sales_order]
, [ns_creditmemo_ItemList].[class-name] AS 'productClass'
, [ns_creditmemo_ItemList].[item-internalId] AS 'cmItemId'
, [ns_creditmemo_ItemList].[item-name] AS 'cmSkuNo'
, [ns_creditmemo_ItemList].[description] AS 'productFamilyPL'
, [ns_creditmemo_ItemList].[price-name] AS 'priceName'
, [ns_creditmemo_ItemList].[quantity] AS 'Qty'
, [ns_creditmemo_ItemList].[units-name] AS 'units'
, [ns_creditmemo_ItemList].[rate] AS 'rate'
, [ns_creditmemo_ItemList].[amount] AS 'amt'
, [ns_creditmemo_ItemList].[customFieldList-custcol_ava_incomeaccount] AS 'incomeAcct'
, [ns_creditmemo_ItemList].[department-name] AS 'departmentName'
, [ns_creditmemo_ItemList].[location-name] AS 'locName'
, [ns_creditmemo].[tranDate] AS 'cmDate'
, [ns_creditmemo].[otherRefNum] AS 'customerPONo'
, [subscription_dim].[baseSubscriptionId] AS 'baseSubscriptionId'
, [subscription_dim].[subscriptionId] AS 'subscriptionId'
, [subscription_dim].[BaseSubscription] AS 'BaseSubscription'
, [subscription_dim].[subscription] AS 'subscription'
, [subscription_dim].[isBase] AS 'isBase'
, [subscription_dim].[refType] AS 'refType'
, [subscription_dim].[refTypeId] AS 'refTypeId'
, [subscription_dim].[tier] AS 'tier'
, [subscription_dim].[seats] AS 'seats'
, [subscription_dim].[featureType] AS 'featureType'
, [subscription_dim].[featureAmt] AS 'featureAmt'
, [subscription_dim].[cloudFeatures] AS 'cloudFeatures'
, [subscription_dim].[vmrsLicenses] AS 'vmrsLicenses'
, [subscription_dim].[featureOrBase] AS 'featureOrBase'
, [subscription_dim].[startDate] AS 'startDate'
, [subscription_dim].[endDate] AS 'endDate'
, [subscription_dim].[entitledYrs] AS 'entitledYrs'
, [subscription_dim].[entitledMos] AS 'entitledMos'
, [subscription_dim].[entitledDays] AS 'entitledDays'
, [subscription_dim].[invoiceAmount] AS 'invoiceAmount'
, [subscription_dim].[invoiceDate] AS 'invoiceDate'
, [subscription_dim].[stdDiscount] AS 'stdDiscount'
, [subscription_dim].[ornDiscount] AS 'ornDiscount'
, [subscription_dim].[nsdDiscount] AS 'nsdDiscount'
, [subscription_dim].[nsdApprovalNo] AS 'nsdApprovalNo'
, [subscription_dim].[skuNo] AS 'skuNo'
, [subscription_dim].[endCustomerId] AS 'endCustomerId'
, [subscription_dim].[endCustomerName] AS 'endCustomerName'
, [subscription_dim].[endCustomerAddr] AS 'endCustomerAddr'
, [subscription_dim].[itemTypeId] AS 'itemTypeId'
, [subscription_dim].[itemType] AS 'itemType'
, [subscription_dim].[itemId] AS 'itemId'
, [subscription_dim].[salesOrderId] AS 'salesOrderId'
, [subscription_dim].[salesOrderLine] AS 'salesOrderLine'
, [subscription_dim].[subscriptionStatusId] AS 'subscriptionStatusId'
, [subscription_dim].[subscriptionStatus] AS 'subscriptionStatus'
FROM [ns_creditmemo]
JOIN [ns_creditmemo_ItemList] ON [ns_creditmemo_ItemList].[internalId] = [ns_creditmemo].[internalId]
JOIN [subscription_dim] ON [subscription_dim].[creditMemoNo] = [ns_creditmemo].[tranId]


select * from creditmemo_dim

SELECT DISTINCT ISNULL(CONVERT(int,[ns_creditmemo].[customFieldList-custbody_createdfrom_reporting]),-1)
FROM [ns_creditmemo]
ORDER BY 1

SELECT DISTINCT [ns_creditmemo].[tranId]
FROM [ns_creditmemo]
ORDER BY 1

SELECT DISTINCT [ns_custom_subscription].[internalId], [ns_custom_subscription].[customFieldList-custrecord_credit_memo] 
FROM ns_custom_subscription
WHERE [ns_custom_subscription].[customFieldList-custrecord_credit_memo] IS NOT NULL

SELECT [ns_creditmemo].[createdFrom-internalId], count(*) 
FROM ns_creditMemo
GROUP BY [ns_creditmemo].[createdFrom-internalId]
--HAVING COUNT(*) > 1
ORDER BY 1 DESC


SELECT DISTINCT [ns_creditMemo].[internalId], [ns_creditMemo].[createdFrom-internalId], [ns_custom_subscription].[customFieldList-custrecord_credit_memo] 
FROM [ns_custom_subscription] 
JOIN [ns_creditMemo] ON [ns_creditMemo].[tranId] = [ns_custom_subscription].[customFieldList-custrecord_credit_memo]


SELECT DISTINCT [ns_creditMemo].[internalId], [ns_creditMemo].[createdFrom-internalId], [ns_salesOrder].[internalId] 
FROM [ns_salesOrder] 
JOIN [ns_creditMemo] ON [ns_creditmemo].[internalId] = [ns_salesOrder].[internalId]
ON [ns_creditMemo].[internalId] = [ns_custom_subscription].[customFieldList-custrecord_credit_memo]
WHERE [ns_custom_subscription].[customFieldList-custrecord_credit_memo] IS NOT NULL

SELECT  * FROM [vw_subsseq_dim]


/***************************************************************************************************************************
** 02/01/2017							dim_customer
** by: mmccanlies       02/06/2017
** Load dim_customer
***************************************************************************************************************************/
-- Bill To Customers
-- TRUNCATE TABLE [dim_customer]
DELETE FROM [dim_customer] WHERE recordType = 'BILL'
GO
INSERT INTO [dim_customer] 
( internalId, alternateId, recordType, entityId, companyName, defaultAddr, emailDomain, Addressee, addr1, addr2, addr3, city, [state], zip, country, addrText
 , label, catInternalId, catName, subsInternalId, subsName, phone, fax, email, termsId, termsName, currency, stage, [status], externalId, lastModDate )
SELECT DISTINCT --TOP 100 
  CONVERT(int, internalId) AS 'internalId'
, ISNULL(CONVERT(int, [billingInternalId]),-1) AS 'alternateId'
, 'BILL' AS 'recordType'
, [entityId] AS 'entityId'
, ISNULL(REPLACE([companyName],'''',''''''),'NA') AS 'companyName'
, ISNULL(REPLACE(REPLACE([defaultAddress],'<br>',', '),'''',''''''),'NA') AS 'defaultAddr'
, [emailDomain] AS 'emailDomain'
, REPLACE([billingAddressee],'''','''''') AS 'addressee'
, REPLACE([billingAddr1],'''','''''') AS 'addr1'
, REPLACE([billingAddr2],'''','''''') AS 'addr2'
, REPLACE([billingAddr3],'''','''''') AS 'addr3'
, REPLACE([billingCity],'''','''''') AS 'city'
, [billingState] AS 'state'
, [billingZip] AS 'zip'
, REPLACE([billingCountry],'_','') AS 'country'
, ISNULL(REPLACE(REPLACE([billingAddrText],'<br>',', '),'''',''''''),'NA') AS 'addrTxt'
, REPLACE([billingLabel],'''','''''') AS 'label'
, ISNULL(CONVERT(int,[category-internalId]),-1) AS 'catInternalId'
, ISNULL([category-name],'NA') AS 'catName'
, ISNULL(CONVERT(int,[subsidiary-internalId]),-1) AS 'subsInternalId'
, REPLACE([subsidiary-name],'''','''''') AS 'subsName'
, [phone] AS 'phone'
, [fax] AS 'fax'
, [email] AS 'email'
, [terms-internalId] AS 'termsId'
, [terms-name] AS 'termsName'
, [currency-name] AS 'currency'
, UPPER(REPLACE([stage],'_','')) AS 'stage'
, REPLACE([entityStatus-name],'''','''''') AS 'status'
, [externalId] AS 'externalId'
, [lastModifiedDate] AS 'lastModifiedDate'
FROM [ns_customer]
WHERE [billingInternalId] IS NOT NULL
ORDER BY CONVERT(int, [billingInternalId])

-- END Customers
DELETE FROM [customer_dim] WHERE recordType = 'END'
GO
INSERT INTO [dim_customer] 
( internalId, alternateId, recordType, entityId, companyName, defaultAddr, emailDomain, Addressee, addr1, addr2, addr3, city, [state], zip, country, addrText
 , label, catInternalId, catName, subsInternalId, subsName, phone, fax, email, termsId, termsName, currency, stage, [status], externalId, lastModDate )
 SELECT DISTINCT --TOP 100 
  CONVERT(int, internalId) AS 'internalId'
, -1 AS 'alternateId'
, 'END' AS 'recordType'
, [entityId] AS 'entityId'
, ISNULL(REPLACE([companyName],'''',''''''),'NA') AS 'companyName'
, ISNULL(REPLACE(REPLACE([defaultAddress],'<br>',', '),'''',''''''),'NA') AS 'defaultAddr'
, [emailDomain] AS 'emailDomain'
, REPLACE([billingAddressee],'''','''''') AS 'addressee'
, REPLACE([billingAddr1],'''','''''') AS 'addr1'
, REPLACE([billingAddr2],'''','''''') AS 'addr2'
, REPLACE([billingAddr3],'''','''''') AS 'addr3'
, REPLACE([billingCity],'''','''''') AS 'city'
, [billingState] AS 'state'
, [billingZip] AS 'zip'
, REPLACE([billingCountry],'_','') AS 'country'
, ISNULL(REPLACE(REPLACE([billingAddrText],'<br>',', '),'''',''''''),'NA') AS 'addrTxt'
, REPLACE([billingLabel],'''','''''') AS 'label'
, ISNULL(CONVERT(int,[category-internalId]),-1) AS 'catInternalId'
, ISNULL([category-name],'NA') AS 'catName'
, ISNULL(CONVERT(int,[subsidiary-internalId]),-1) AS 'subsInternalId'
, REPLACE([subsidiary-name],'''','''''') AS 'subsName'
, [phone] AS 'phone'
, [fax] AS 'fax'
, [email] AS 'email'
, [terms-internalId] AS 'termsId'
, [terms-name] AS 'termsName'
, [currency-name] AS 'currency'
, UPPER(REPLACE([stage],'_','')) AS 'stage'
, REPLACE([entityStatus-name],'''','''''') AS 'status', [externalId] AS 'externalId'
, [lastModifiedDate] AS 'lastModifiedDate'
FROM [ns_customer]
ORDER BY CONVERT(int, internalId)
GO

INSERT INTO [dim_customer]
( internalId, alternateId, recordType, companyName, defaultAddr, catInternalId, catName, subsInternalId ) VALUES
( -1, -1, 'BILL', 'NA', 'NA' , -1, 'NA', -1 ), 
( -1, -1, 'END',  'NA', 'NA' , -1, 'NA', -1 )


/***************************************************************************************************************************
**                                          dim_salesorder
** by: mmccanlies       01/25/2017
** Load salesOrder_Dim table
***************************************************************************************************************************/
-- SalesOrder_ItemList Dim
-- TRUNCATE TABLE [dim_salesorder]
GO
INSERT INTO [dim_salesorder]
( salesOrderId, salesOrderLine, salesOrderNo, soTermYrs, soTermMos, soTermDays, soListPrice, soListPricePerYr, soListPricePerMo, soListPricePerDay,
  stdDiscount, stdDiscAmtYrs, stdDiscAmtMos, stdDiscAmtDays, ornDiscount, ornDiscAmtYrs, ornDiscAmtMos, ornDiscAmtDays, nsdDiscount, nsdDiscAmtYrs, nsdDiscAmtMos, nsdDiscAmtDays,
  soItemId, soSkuNo, soLocName, soDescription, soClassName, soClassId, soBookingDate, soCustomerPONo, soServiceStartDate, soServiceEndDate, 
  soServiceYrs, soServiceMos, soServiceDays, soQty, soUnits, soAmount, soPriceType, soCustomerDisc, soRequestDate,  soQtyBilled, soQtyFulfilled, 
  soServiceRenewal, soDeptName, soRevRecStartDate, soRevRecEndDate, soRevRecTermInMonths, soIsClosed, soLineId, endCustomerName, endCustomerAddress )

SELECT DISTINCT 
  ISNULL(CONVERT(int,[ns_salesOrder].[internalId]),-1) AS 'salesOrderId'
, ISNULL(TRY_CONVERT(int,[ns_salesOrder_itemlist].[line]),1) AS 'salesOrderLine'
, [ns_salesOrder].[tranId] AS 'salesOrderNo'

, ISNULL(CONVERT(int,[ns_salesOrder_itemList].[customFieldList-custcol_term]),0)            AS 'soTermYrs'
, ISNULL(CONVERT(int,[ns_salesOrder_itemList].[customFieldList-custcol_term]),0)*12         AS 'soTermMos'
, ISNULL(CONVERT(int,[ns_salesOrder_itemList].[customFieldList-custcol_term]),0)*365        AS 'soTermDays'

, CONVERT(money,[ns_salesOrder_ItemList].[customFieldList-custcol_custlistprice])   AS 'soListPrice'
, CASE WHEN CONVERT(int,[ns_salesOrder_itemList].[customFieldList-custcol_term]) = 0
    THEN 0 
  ELSE CONVERT(money,[ns_salesOrder_ItemList].[customFieldList-custcol_custlistprice]/(CONVERT(int,[ns_salesOrder_itemList].[customFieldList-custcol_term])))
  END AS 'soListPricePerYr'
, CASE WHEN CONVERT(int,[ns_salesOrder_itemList].[customFieldList-custcol_term])*12.0 = 0
    THEN 0 
  ELSE CONVERT(money,[ns_salesOrder_ItemList].[customFieldList-custcol_custlistprice]/(CONVERT(int,[ns_salesOrder_itemList].[customFieldList-custcol_term])*12.0))
  END AS 'soListPricePerMo'
, CASE WHEN CONVERT(int,[ns_salesOrder_itemList].[customFieldList-custcol_term])*365.0 = 0
    THEN 0 
  ELSE CONVERT(money,[ns_salesOrder_ItemList].[customFieldList-custcol_custlistprice]/(CONVERT(int,[ns_salesOrder_itemList].[customFieldList-custcol_term])*365.0))
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

, ISNULL(CONVERT(int,[ns_salesOrder_itemList].[item-internalId]),-1) AS 'soItemId'
, [ns_salesOrder_itemList].[item-name] AS 'soSkuNo' 
, [ns_salesOrder_itemList].[location-name] AS 'soLocName' 
, [ns_salesOrder_itemList].[description] AS 'soDescription' 
, [ns_salesOrder_ItemList].[class-name] AS 'soClassName'
, ISNULL(CONVERT(int,[ns_salesOrder_ItemList].[class-internalId]),-1) AS 'soClassId'
, [ns_salesOrder].[customFieldList-custbody_order_date] AS 'soBookingDate'
, [ns_salesOrder].[otherRefNum] AS 'soCustomerPONo'
, [ns_salesOrder_itemList].[customFieldList-custcol_service_start_date] AS 'soServiceStartDate' 
, [ns_salesOrder_itemList].[customFieldList-custcol_service_end_date] AS 'soServiceEndDate' 
, DATEDIFF(YY, [customFieldList-custcol_service_start_date], [customFieldList-custcol_service_end_date]) AS 'soServiceYrs'
, DATEDIFF(MM, [customFieldList-custcol_service_start_date], [customFieldList-custcol_service_end_date]) AS 'soServiceMos'
, DATEDIFF(DD, [customFieldList-custcol_service_start_date], [customFieldList-custcol_service_end_date]) AS 'soServiceDays'
, CASE WHEN ISNUMERIC(SUBSTRING([ns_salesOrder_itemList].[units-name],1,1)) = 1
    THEN TRY_CAST(SUBSTRING([ns_salesOrder_itemList].[units-name],1,1) AS numeric)
    ELSE 1
  END * CONVERT(numeric,[ns_salesOrder_itemList].[quantity]) AS 'soQty'
, CASE WHEN ISNUMERIC(SUBSTRING([ns_salesOrder_itemList].[units-name],1,1)) = 1
    THEN CASE SUBSTRING([ns_salesOrder_itemList].[units-name],2,1)
           WHEN 'Y' THEN 'YR'
           WHEN 'Q' THEN 'QTR'
           WHEN 'M' THEN 'MO'
           ELSE SUBSTRING([ns_salesOrder_itemList].[units-name],2,LEN([ns_salesOrder_itemList].[units-name]))
         END
    ELSE [ns_salesOrder_itemList].[units-name]
  END AS 'soUnits'

, [ns_salesOrder_itemList].[amount] AS 'soAmount' 
, [ns_salesOrder_itemList].[price-name] AS 'soPriceType' 
, [ns_salesOrder_itemList].[customFieldList-custcolcustcolcustcol_custactdiscount]/100.0 AS 'soCustomerDisc' 
, [ns_salesOrder_itemList].[customFieldList-custcol_request_date] AS 'soRequestDate' 
, [ns_salesOrder_itemList].[quantityBilled] AS 'soQtyBilled' 
, [ns_salesOrder_itemList].[quantityFulfilled] AS 'soQtyFulfilled' 
, [ns_salesOrder_itemList].[customFieldList-custcol_service_renewal] AS 'soServiceRenewal' 
, [ns_salesOrder_itemList].[department-name] AS 'soDeptName' 
, [ns_salesOrder_itemList].[revRecStartDate] AS 'soRevRecStartDate' 
, [ns_salesOrder_itemList].[revRecEndDate] AS 'soRevRecEndDate' 
, [ns_salesOrder_itemList].[revRecTermInMonths] AS 'soRevRecTermInMonths' 
, [ns_salesOrder_itemList].[isClosed] AS 'soIsClosed' 
, ISNULL(TRY_CONVERT(numeric,[ns_salesOrder_itemlist].[customFieldList-custcol_line_id]),-1) AS 'soLineId'
, ISNULL(
  SUBSTRING(ISNULL(SUBSTRING([ns_salesOrder].[customFieldList-custbody_end_customer_address_text],1,500),1 ), 1
, CASE WHEN PATINDEX('%<br>%',[ns_salesOrder].[customFieldList-custbody_end_customer_address_text]) < 1 
      THEN 1
      ELSE PATINDEX('%<br>%',[ns_salesOrder].[customFieldList-custbody_end_customer_address_text]) 
  END-1 ),'NA') AS 'endCustomerName'                                             -- End Customer Name == End Custome Addr up to first '<br>
, ISNULL(REPLACE(SUBSTRING([ns_salesOrder].[customFieldList-custbody_end_customer_address_text],1,500),'<br>',' '),'NA') AS 'endCustomerAddress'
FROM [ns_salesOrder] 
JOIN [ns_salesOrder_itemList] ON [ns_salesOrder_itemList].[internalId] = [ns_salesOrder].[internalId]
RIGHT OUTER JOIN [vw_test_grp] ON [vw_test_grp].[salesOrderId] = ISNULL([ns_salesOrder].[internalId],-1)
        AND [vw_test_grp].[salesOrderLine] = ISNULL(TRY_CONVERT(int,[ns_salesOrder_itemlist].[line]),1)
ORDER BY ISNULL(CONVERT(int,[ns_salesOrder].[internalId]),-1) 
       , ISNULL(TRY_CONVERT(int,[ns_salesOrder_itemlist].[line]),1) 
  
GO
UPDATE [dim_salesorder] SET
  StdDiscount = [subscription_dim].[StdDiscount] 
, StdDiscAmtYrs = CONVERT(money,[salesorder_dim].[soListPricePerMo]*[subscription_dim].[StdDiscount]*12.0) 
, StdDiscAmtMos = CONVERT(money,[salesorder_dim].[soListPricePerMo]*[subscription_dim].[StdDiscount])      
, StdDiscAmtDays = CONVERT(money,[salesorder_dim].[soListPricePerDay]*[subscription_dim].[StdDiscount])     

, ORNDiscount = [subscription_dim].[ORNDiscount] 
, ORNDiscAmtYrs = CONVERT(money,[salesorder_dim].[soListPricePerMo]*[subscription_dim].[ORNDiscount]*12.0) 
, ORNDiscAmtMos  = CONVERT(money,[salesorder_dim].[soListPricePerMo]*[subscription_dim].[ORNDiscount])      
, ORNDiscAmtDays = CONVERT(money,[salesorder_dim].[soListPricePerDay]*[subscription_dim].[ORNDiscount])     

, NSDDiscount = [subscription_dim].[NSDDiscount] 
, NSDDiscAmtYrs = CONVERT(money,( 1-[subscription_dim].[StdDiscount]-[subscription_dim].[ORNDiscount])*[salesorder_dim].[soListPricePerMo]*[subscription_dim].[NSDDiscount]*12) 
, NSDDiscAmtMos = CONVERT(money,( 1-[subscription_dim].[StdDiscount]-[subscription_dim].[ORNDiscount])*[salesorder_dim].[soListPricePerMo]*[subscription_dim].[NSDDiscount] )   
, NSDDiscAmtDays = CONVERT(money,( 1-[subscription_dim].[StdDiscount]-[subscription_dim].[ORNDiscount])*[salesorder_dim].[soListPricePerDay]*[subscription_dim].[NSDDiscount])   
FROM [subscription_dim]
LEFT JOIN [salesorder_dim] ON [salesorder_dim].[salesOrderId] = [subscription_dim].[salesOrderId] AND [salesorder_dim].[salesOrderLine] = [subscription_dim].[salesOrderLine]



SELECT 
  [subscription_dim].[baseSubscriptionId] AS 'baseSubscriptionId' 
, [subscription_dim].[subscriptionId] AS 'subscriptionId'
, [subscription_dim].[entitledDays]
, [salesorder_dim].[soTermYrs]
, [salesorder_dim].[soTermMos]
, [salesorder_dim].[soTermDays]
, [salesorder_dim].[soListPrice] AS ListPrice
, [salesorder_dim].[soListPricePerYr] AS ListPricePerYr
, [salesorder_dim].[soListPricePerMo] AS ListPricePerMo
, [salesorder_dim].[soListPricePerDay] AS ListPricePerDay
, [subscription_dim].[StdDiscount] AS StdDiscount
, CONVERT(money,[salesorder_dim].[soListPricePerMo]*[subscription_dim].[StdDiscount]*12.0) AS StdDiscAmtYrs
, CONVERT(money,[salesorder_dim].[soListPricePerMo]*[subscription_dim].[StdDiscount])      AS StdDiscAmtMos
, CONVERT(money,[salesorder_dim].[soListPricePerDay]*[subscription_dim].[StdDiscount])     AS StdDiscAmtDays
, [subscription_dim].[ORNDiscount] AS ORNDiscount
, CONVERT(money,[salesorder_dim].[soListPricePerMo]*[subscription_dim].[ORNDiscount]*12.0) AS ORNDiscAmtYrs
, CONVERT(money,[salesorder_dim].[soListPricePerMo]*[subscription_dim].[ORNDiscount])      AS ORNDiscAmtMos
, CONVERT(money,[salesorder_dim].[soListPricePerDay]*[subscription_dim].[ORNDiscount])     AS ORNDiscAmtDays
, [subscription_dim].[NSDDiscount] AS NSDDiscount
, CONVERT(money,( 1-[subscription_dim].[StdDiscount]-[subscription_dim].[ORNDiscount])*[salesorder_dim].[soListPricePerMo]*[subscription_dim].[NSDDiscount]*12) AS NSDDiscAmtYrs
, CONVERT(money,( 1-[subscription_dim].[StdDiscount]-[subscription_dim].[ORNDiscount])*[salesorder_dim].[soListPricePerMo]*[subscription_dim].[NSDDiscount] )   AS NSDDiscAmtMos
, CONVERT(money,( 1-[subscription_dim].[StdDiscount]-[subscription_dim].[ORNDiscount])*[salesorder_dim].[soListPricePerDay]*[subscription_dim].[NSDDiscount])   AS NSDDiscAmtDays
FROM [subscription_dim]
LEFT JOIN [salesorder_dim] ON [salesorder_dim].[salesOrderId] = [subscription_dim].[salesOrderId] AND [salesorder_dim].[salesOrderLine] = [subscription_dim].[salesOrderLine]
--AND [subscription_dim].[subscriptionId] IN ( 7552, 7869 )
ORDER BY 1,2


/***************************************************************************************************************************
**                                          dim_invoice
** by: mmccanlies       02/05/2017
** Load dim_invoice table
***************************************************************************************************************************/
-- TRUNCATE TABLE [dim_invoice]
GO
INSERT INTO [dim_invoice] 
( invoiceId, invoiceLine, invoiceNo, invoiceDate, invCustColTerm, serviceStart, serviceEnd, serviceYrs, serviceMos, serviceDays, 
  orderLine, invClassName, skuNo, invDescription, invLocName, invRate, invQty, invUnits, invPriceName, invIncAcct, BillToCustomerId,
  BillToCustomerName, BillToCustomerAddress, billingDate, invAutoSalesOut, invRevRecStartDate, invRevRecEndDate, 
  invRevRecSchedName, subscriptionId, salesOrderId, invItemId )

SELECT DISTINCT 
  ISNULL(CONVERT(int,[ns_invoice].[internalId]),-1) AS 'invoiceId'
, ISNULL(CONVERT(int,CONVERT(numeric,[ns_invoice_itemlist].[customFieldList-custcol_line_id])),1) AS 'invoiceLine'
, [ns_invoice].[tranId] AS 'invoiceNo'
, [ns_invoice].[tranDate] AS 'invoiceDate'
, [ns_invoice_itemList].[customFieldList-custcol_term] AS 'invCustColTerm'
, [ns_invoice_itemList].[customFieldList-custcol_service_start_date] AS 'serviceStart'
, [ns_invoice_itemList].[customFieldList-custcol_service_end_date] AS 'serviceEnd'
, DATEDIFF(YY, [ns_invoice_itemList].[customFieldList-custcol_service_start_date], [ns_invoice_itemList].[customFieldList-custcol_service_end_date]) AS 'serviceYrs'
, DATEDIFF(MM, [ns_invoice_itemList].[customFieldList-custcol_service_start_date], [ns_invoice_itemList].[customFieldList-custcol_service_end_date]) AS 'serviceMos'
, DATEDIFF(DD, [ns_invoice_itemList].[customFieldList-custcol_service_start_date], [ns_invoice_itemList].[customFieldList-custcol_service_end_date]) AS 'serviceDays'

, [orderLine] AS 'orderLine'
, [ns_invoice_itemlist].[class-name] AS 'invClassName'
, [ns_invoice_itemlist].[item-name] AS 'skuNo'
, [ns_invoice_itemlist].[description] AS 'invDescription'
, [ns_invoice_ItemList].[location-name] AS 'invLocName'
, ISNULL([ns_invoice_ItemList].[rate],0) AS 'invRate'

--, ISNULL([ns_invoice_ItemList].[quantity],1) AS 'origInvQty'
--, [ns_invoice_itemlist].[units-name] AS 'origInvUnits'
, CASE WHEN ISNUMERIC(SUBSTRING([ns_invoice_itemlist].[units-name],1,1)) = 1
    THEN ISNULL(TRY_CAST(SUBSTRING([ns_invoice_itemlist].[units-name],1,1) AS numeric),0)
    ELSE 1
  END * CONVERT(numeric,[ns_invoice_ItemList].[quantity]) AS 'invQty'
, CASE WHEN ISNUMERIC(SUBSTRING([ns_invoice_itemlist].[units-name],1,1)) = 1
    THEN CASE SUBSTRING([ns_invoice_itemlist].[units-name],2,1)
           WHEN 'Y' THEN 'YR'
           WHEN 'Q' THEN 'QTR'
           WHEN 'M' THEN 'MO'
           ELSE SUBSTRING([ns_invoice_itemlist].[units-name],2,LEN([ns_invoice_itemlist].[units-name]))
         END
    ELSE [ns_invoice_itemlist].[units-name]
  END AS 'invUnits'
, [ns_invoice_itemlist].[price-name] AS 'invPriceName'
--, [ns_invoice_itemlist].[customFieldList-custcol_standard_discount_pct] AS 'invStdDiscPct'
--, [ns_invoice_itemlist].[customFieldList-custcol_orn_discount_pct] AS 'invOrnDiscPct'
--, [ns_invoice_itemlist].[customFieldList-custcol_nsd_discount_pct] AS 'invNsdDiscPct'
, [ns_invoice_itemlist].[customFieldList-custcol_ava_incomeaccount] AS 'invIncAcct'
, ISNULL([ns_invoice].[customFieldList-custbody_bill_customer],-1) AS 'BillToCustomerId'
, [ns_invoice].[entity-name] AS 'BillToCustomerName'
, ISNULL(REPLACE([ns_invoice].[billAddress],'<br>',' '),'NA')  AS 'BillToCustomerAddress'
, [ns_invoice].[tranDate] AS 'billingDate'

, ISNULL([ns_invoice_itemlist].[customFieldList-custcol_auto_sales_out],-1) AS 'invAutoSalesOut'
, [ns_invoice_itemlist].[revRecStartDate] AS 'invRevRecStartDate'
, [ns_invoice_itemlist].[revRecEndDate] AS 'invRevRecEndDate'
, [ns_invoice_itemlist].[revRecSchedule-name] AS 'invRevRecSchedName'
, ISNULL(CONVERT(int,[ns_invoice_itemlist].[customFieldList-custcol_subscription]),-1) AS 'subscriptionId'
, ISNULL(CONVERT(int,[ns_invoice].[createdFrom-internalId]),-1) AS 'salesOrderId'
, ISNULL(CONVERT(int,[ns_invoice_ItemList].[item-internalId]),-1) AS 'invItemId'
--INTO [dim_invoice]
FROM [ns_custom_subscription] 
LEFT OUTER JOIN [ns_salesorder] ON ISNULL([ns_salesorder].[internalId],-1) = ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_transaction],-1)
LEFT OUTER JOIN [ns_salesorder_itemlist] ON ISNULL([ns_salesorder_itemlist].[internalId],-1) = ISNULL([ns_salesorder].[internalId],-1)
	AND [ns_salesorder_itemlist].[line] = [ns_custom_subscription].[customFieldList-custrecord_subscription_transaction_line]  -- Added
LEFT OUTER JOIN [ns_invoice] ON ISNULL([ns_invoice].[createdFrom-internalId],-1) = ISNULL([ns_salesorder].[internalId],-1)
LEFT OUTER JOIN [ns_invoice_itemlist] ON ISNULL([ns_invoice_itemlist].[internalId],-1) = ISNULL([ns_invoice].[internalId],-1) 
	AND TRY_CAST(ISNULL([ns_invoice_itemlist].[customFieldList-custcol_line_id],1) AS numeric) = TRY_CAST(ISNULL([ns_salesorder_itemlist].[customFieldList-custcol_line_id],1) AS numeric)   -- Added
RIGHT JOIN [vw_test_grp] ON [vw_test_grp].[invoiceId] = ISNULL([ns_invoice].[internalId],-1)
        AND [vw_test_grp].[invoiceLine] = TRY_CAST(ISNULL([ns_invoice_itemlist].[customFieldList-custcol_line_id],1) AS numeric)
ORDER BY ISNULL(CONVERT(int,[ns_invoice_itemlist].[customFieldList-custcol_subscription]),-1)
;

-- Fix subscriptionId's in invoice_dim first
UPDATE [dim_invoice] SET 
  [subscriptionId = [xrf_index].[subscriptionId]
FROM [dim_invoice]
JOIN [xrf_index] ON [xrf_index].invoiceId = [dim_invoice].[invoiceId]
 AND [xrf_index].invoiceLine = [dim_invoice].[invoiceLine]



/***************************************************************************************************************************
**                                          dim_product
** by: mmccanlies       01/17/2017
** Create dim_product table
** -- from ns_classification                   Where is sku_dim
**                                             This table should replace sku_dim
***************************************************************************************************************************/
--TRUNCATE TABLE dim_product 
GO
INSERT INTO [dim_product] 
( classId, itemId, className, productClass, productType, productFamily, productFamilyPL, skuNo, skuDescription, skuDurationYrs, skuSeats )
SELECT DISTINCT
  CONVERT(int, nis.[class-internalId]) AS 'classId'
, CONVERT(int, nis.internalId) AS 'itemId'
, nis.[class-name] AS 'className'
, PARSENAME(REPLACE(nis.[class-name],' : ','.'),1) AS 'productClass'
, PARSENAME(REPLACE(nis.[class-name],' : ','.'),2) AS 'productType'
, PARSENAME(REPLACE(nis.[class-name],' : ','.'),3) AS 'productFamily'
, PARSENAME(REPLACE(nis.[class-name],' : ','.'),4) AS 'productFamilyPL'
, nis.itemId AS 'SkuNo'
, nis.[customFieldList-custitem_term] AS 'skuDurationYrs'
, nis.salesDescription AS 'skuDescription'
, NULL AS 'skuSeats'
--INTO [dim_product]
FROM [fdw_raw].[fdw_raw].[ns_nonInventorySaleItem] nis
JOIN [fdw_raw].[fdw_raw].[xrf_index] xrf ON nis.[internalId] = xrf.[itemId]
ORDER BY CONVERT(int, nis.[class-internalId]), CONVERT(int, nis.internalId)
;


/***************************************************************************************************************************
**                                          dim_salesout
** by: mmccanlies       02/05/2017
** Load dim_salesout table
***************************************************************************************************************************/
-- SalesOut Dim
-- TRUNCATE TABLE [dim_salesout]
INSERT INTO [dim_salesout]
( salesOutId, salesOutLine, outDate, outPurchaseDate, outSerialNo, outStatus, outItemId, outQty, outAmt, outListPrice, 
  outSoldThruReseller, outReseller, outResllerPONo, outCustomerNo, outCompanyName, outAddr1, outAddr2, outAddr3, outAddr4, 
  outCity, outState, outZip, outProvince, outCounty, outCountry, outEmail, outPhone, outSFPartnerNo, outSalesRegion, 
  outSalesOrderNo, outSalesOrder, outExternalId )

SELECT DISTINCT
  ISNULL(CONVERT(int,[ns_custom_sales_out].[internalId]),-1) AS 'salesOutId'
, ISNULL(CONVERT(int,CONVERT(numeric,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_original_line_num])),1) AS 'salesOutLine'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_date] AS 'outDate'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_purchasedate] AS 'outPurchaseDate'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_serial_number] AS 'outSerialNo'
, ISNULL(CONVERT(int,CONVERT(numeric,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_status])),1) AS 'outStatus'
, ISNULL(CONVERT(int,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_item]),-1) AS 'outItemId'
, ISNULL(CONVERT(int,CONVERT(numeric,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_quantity])),-1) AS 'outQty'
, ISNULL(CONVERT(money,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_amount]),0) AS 'outAmt'
, ISNULL(CONVERT(money,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_list_price]),0) AS 'outListPrice'

, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_sold_thru_reseller] AS 'outSoldThruReseller'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_strategic_reseller] AS 'outReseller'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_reseller_po_number] AS 'outResllerPONo'
, ISNULL(CONVERT(int,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_customer_number]),-1) AS 'outCustomerNo'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_company_name] AS 'outCompanyName'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_address_1] AS 'outAddr1'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_address_2] AS 'outAddr2'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_address_3] AS 'outAddr3'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_address_4] AS 'outAddr4'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_city] AS 'outCity'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_state] AS 'outState'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_zip] AS 'outZip'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_province] AS 'outProvince'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_county] AS 'outCounty'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_country] AS 'outCountry'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_email] AS 'outEmail'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_phone] AS 'outPhone'
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_sf_partner_number] AS 'outSFPartnerNo'

, ISNULL(CONVERT(int,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_sales_region]),-1) AS 'outSalesRegion'
, ISNULL(CONVERT(int,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_original_trans]),-1) AS 'outSalesOrderNo'
, ISNULL(CONVERT(int,[ns_custom_sales_out].[customFieldList-custrecord_original_sales_order]),-1) AS 'outSalesOrder'
, [ns_custom_sales_out].[externalId] AS 'outExternalId'
FROM [ns_custom_sales_out]                                                      --268634
RIGHT OUTER JOIN [vw_test_grp] ON [vw_test_grp].[salesOutId] = ISNULL(CONVERT(int,[ns_custom_sales_out].[internalId]),-1)
        AND [vw_test_grp].[salesOutLine] = ISNULL(TRY_CONVERT(int,[ns_custom_sales_out].[customFieldList-custrecord_sales_out_original_line_num]),1)
ORDER BY 1,2

----IN [ns_custom_sales_out]
--WHERE [isInactive] = 0							--268634
--WHERE [customFieldList-custrecord_sales_out_country] IS NOT NULL		--171199
--WHERE [externalId] IS NOT NULL						--169966
--WHERE [customFieldList-custrecord_sales_out_strategic_reseller] IS NOT NULL	--159311
--WHERE [customFieldList-custrecord_sales_out_sold_thru_reseller] IS NOT NULL	-- 80538
--WHERE [customFieldList-custrecord_sales_out_reseller_po_number] IS NOT NULL   --  9155


/***************************************************************************************************************************
**                                          Update reseller in dim_salesout
** by: mmccanlies       02/07/2017
** Update dim_salesout table
***************************************************************************************************************************/
-- Sales Out Dim
-- 
GO
UPDATE [dim_salesout] SET 
  [outReseller] = [tmp_legacyreseller_xrf].[resellerName]
, [outResllerPONo] = [tmp_legacyreseller_xrf].[poNo]
, [outSoldThruReseller] = 1
FROM [xrf_index]
JOIN [xrf_legacy_reseller] ON [xrf_legacy_reseller].[baseSubscriptionId] = [xrf_index].[baseSubscriptionId]
JOIN [dim_salesout] ON [dim_salesout].[salesOutId] = [xrf_index].[salesOutId]


/***************************************************************************************************************************
**                                              dim_subscription
** by: mmccanlies       02/05/2017
** Load dim_subscription table
***************************************************************************************************************************/
-- DROP TABLE [dim_subscription]
GO
-- TRUNCATE TABLE [dim_subscription]
GO
INSERT INTO [dim_subscription] 
( baseSubscriptionId, subscriptionId, BaseSubscription, subscription, isBase, refType, refTypeId, tier, seats, 
  featureType, featureAmt, cloudFeatures, vmrsLicenses, featureOrBase, tierId, tierLvl, ssoIncl, lyncIncl, maxUsersSet,
  maxMtgParticipants, maxVMRs, endPointsAsUsers, recordingEnabled, recordingHrsIncl, backgroundSet, startDate, endDate,
  entitledYrs, entitledMos, entitledDays, invoiceAmount, invoiceDate, stdDiscount, ornDiscount, nsdDiscount,  nsdApprovalNo, 
  skuNo, endCustomerId, endCustomerName, endCustomerAddr, itemType, itemId, itemTypeId, salesOrderId, salesOrderLine, 
  subscriptionStatusId, subscriptionStatus )
SELECT DISTINCT
  ISNULL(CONVERT(int, [ns_custom_subscription].[customFieldList-custrecord_base_subscription]),-1) AS 'baseSubscriptionId' 
, ISNULL(CONVERT(int, [ns_custom_subscription].[internalId]),-1) AS 'subscriptionId'
, (SELECT customRecordId FROM [ns_custom_subscription] s WHERE s.internalId = [ns_custom_subscription].[customFieldList-custrecord_base_subscription] ) AS 'BaseSubscription'
, [ns_custom_subscription].[customRecordId] AS 'subscription'
, ISNULL(CONVERT(int, [customFieldList-custrecord_base_subscription_flag]),0) AS 'isBase' 
, CASE WHEN [ns_custom_subscription].[customFieldList-custrecord_credit_memo] IS NOT NULL
  THEN 'Credit Memo'
  ELSE
	  CASE [customFieldList-custrecord_reference_type] 
		WHEN 4 THEN 'Cloud - New'
		WHEN 5 THEN 'Cloud - Renewal'
		WHEN 6 THEN 'Cloud - Upgrade'
		WHEN 7 THEN 'Cloud - Upgrade/Renewal'
		WHEN 8 THEN 'Cloud - Upgrade/Renewal Midterm'
		WHEN 9 THEN 'Cloud - Feature'
		WHEN 10 THEN 'Cloud - Add Users'
	  END
END AS 'refType'
, [ns_custom_subscription].[customFieldList-custrecord_reference_type] AS 'refTypeId' 
, [CustomSubscriptionTierDefault].[tierName] AS 'tier'
, [customSubscriptionTierDefault].[internalId] AS 'tierId'
, [customSubscriptionTierDefault].[tierLvl] AS 'tierLvl'
, ISNULL(CONVERT(int, [customFieldList-custrecord_number_of_seats_2]),0) AS 'seats' 

, ISNULL([ns_custom_subscription].[customFieldList-custrecord_license_type],'') AS 'featureType'
, CASE WHEN [ns_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'Ampl%'
      THEN ISNULL(CONVERT(int,[ns_custom_subscription].[customFieldList-custrecord_amplify_hours]),0)
    WHEN [ns_custom_subscription].[customFieldList-custrecord_license_type] LIKE 'Extr%'
      THEN ISNULL(CONVERT(int, [ns_custom_subscription].[customFieldList-custrecord_number_of_seats]),0)
    ELSE 0
  END AS 'featureAmt'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_cloud_features],'') AS 'cloudFeatures'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_vmrs],0) AS 'vmrsLicenses'
, CASE 
	WHEN [ns_custom_subscription].[customFieldList-custrecord_base_subscription_flag] = 1 THEN 'Base'
    WHEN [ns_custom_subscription].[customFieldList-custrecord_license_type] IS NOT NULL THEN 'Feature'
	ELSE 'Other'
  END AS 'featureOrBase'

, [customSubscriptionTierDefault].[ssoIncl] AS 'ssoIncl'
, [customSubscriptionTierDefault].[lyncIncl] AS 'lyncIncl'
, [customSubscriptionTierDefault].[maxUsersSet] AS 'maxUsersSet'
, [customSubscriptionTierDefault].[maxMtgParticipants] AS 'maxMtgParticipants'
, [customSubscriptionTierDefault].[maxVMRs] AS 'maxVMRs'
, [customSubscriptionTierDefault].[endPointsAsUsers] AS 'endPointsAsUsers'
, [customSubscriptionTierDefault].[recordingEnabled] AS 'recordingEnabled'
, [customSubscriptionTierDefault].[recordingHrsIncl] AS 'recordingHrsIncl'
, [customSubscriptionTierDefault].[backgroundSet] AS 'backgroundSet'

, [ns_custom_subscription].[customFieldList-custrecord_subscription_start_date] AS 'startDate' 
, [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date] AS 'endDate' 
, DATEDIFF(YY, [ns_custom_subscription].[customFieldList-custrecord_subscription_start_date], [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date]) AS 'entitledYrs'
, DATEDIFF(MM, [ns_custom_subscription].[customFieldList-custrecord_subscription_start_date], [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date]) AS 'entitledMos'
, [dbo].[ufn_datediff_365]([ns_custom_subscription].[customFieldList-custrecord_subscription_start_date], [ns_custom_subscription].[customFieldList-custrecord_subscription_end_date]) AS 'entitledDays'

, 0 AS 'invoiceAmt'
, '1900-01-01' AS 'invoiceDate'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_standard_discount_pct],0)/100.0 AS 'stdDiscount'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_orn_discount_pct],0)/100.0 AS 'ornDiscount'
, ISNULL([ns_custom_subscription].[customFieldList-custrecord_nsd_discount_pct],0)/100.0 AS 'nsdDiscount'

, [ns_custom_subscription].[customFieldList-custrecord_nsd_id] AS 'nsdApprovalNo'
, [ns_custom_subscription].[customFieldList-custrecord_subscription_item_no] AS 'skuNo' 
, ISNULL(CONVERT(int,[customFieldList-custrecord_subscription_end_customer]),-1) AS 'endCustomerId' 
, [customer_dim].[entityId] AS 'endCustomerName'
, REPLACE(REPLACE(addrText,'<br>',''),'''','''''') AS 'endCustomerAddr'
, (SELECT description1 FROM [xrf_lookup] WHERE [refType] = 'ItemType' AND [sourceRefId] = [ns_custom_subscription].[customFieldList-custrecord_item_type]) AS 'itemType'
, ISNULL(CONVERT(int,[ns_custom_subscription].[customFieldList-custrecord_subscription_item]),-1) AS 'itemId'
, ISNULL(CONVERT(int,[ns_custom_subscription].[customFieldList-custrecord_item_type]),-1) AS 'itemTypeId'
, ISNULL(CONVERT(int,CONVERT(numeric,[ns_custom_subscription].[customFieldList-custrecord_subscription_transaction])),1) AS 'salesOrderId'
, ISNULL(CONVERT(int,[ns_custom_subscription].[customFieldList-custrecord_subscription_transaction_line]),1) AS 'salesOrderLine'
, ISNULL(CONVERT(int,[ns_custom_subscription].[customFieldList-custrecord_subscription_status]),-1) AS 'subscriptionStatusId'
, (SELECT [description1] FROM [xrf_lookup] WHERE [xrf_lookup].[refType] = 'subStatus' AND [xrf_lookup].[sourceRefId] = [ns_custom_subscription].[customFieldList-custrecord_subscription_status] ) AS 'status'
--INTO [dim_subscription]
FROM [ns_custom_subscription] 
LEFT OUTER JOIN [dim_customer] ON [dim_customer].[internalId] = ISNULL(CONVERT(int,[ns_custom_subscription].[customFieldList-custrecord_subscription_end_customer]),-1)
            AND [dim_customer].[recordType] = 'END'
JOIN [customSubscriptionTierDefault] ON  [customSubscriptionTierDefault].[internalId] = ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_tier],-1)
JOIN [vw_test_grp] ON  [vw_test_grp].[subscriptionId] = [ns_custom_subscription].[internalId] 
ORDER BY ISNULL(CONVERT(int, [ns_custom_subscription].[customFieldList-custrecord_base_subscription]),-1) ASC 
	   , [customFieldList-custrecord_subscription_start_date] 
       , ISNULL(CONVERT(int, [ns_custom_subscription].[internalId]),-1)
GO

-- invoice_dim must be loaded and updated before subscription_dim
-- Set invoiceDates in subscription_dim
UPDATE [dim_subscription] SET
  invoiceAmount = [dim_invoice].[invRate]
, invoiceDate = [dim_invoice].[invoiceDate]
FROM [subscription_dim]
JOIN [dim_invoice] ON [dim_invoice].subscriptionId = [subscription_dim].[subscriptionId]

-- I don't remember what why I set the seats and tier for refTypeId=9 (Feature) 
-- I suppose these subscriptions don't have values and we don't want to Up/Dngrade based on that
UPDATE sub2 SET
  seats = sub1.seats
, tier = sub1.tier
FROM [vw_subsseq_dim] x
JOIN [dim_subscription] sub1 ON sub1.[baseSubscriptionId] = x.Base AND sub1.[subscriptionId] = x.sub1
JOIN [dim_subscription] sub2 ON sub2.[baseSubscriptionId] = x.Base AND sub2.[subscriptionId] = x.sub2
WHERE sub2.refTypeId = 9


SELECT * FROM subscription_dim

/***************************************************************************************************************************
**                                          tmp_subs_dim
** by: mmccanlies       02/13/2017
** Update tmp_subs_dim table
***************************************************************************************************************************/
-- Flatten basic records prior to ARR bucketing logic.
-- DROP TABLE [tmp_subs_dim]
GO
TRUNCATE TABLE [tmp_subs_dim]
GO
SELECT DISTINCT
  [baseSubscriptionId]
, [subscriptionId]
, [isBase]
, [startDate]
, [endDate]
, [invoiceDate]
, [invoiceAmount]
, [refType]
, [refTypeId]
, CASE WHEN [dim_subscription].[refType] = 'Credit Memo'
      THEN 1
      ELSE 0
  END AS 'isCreditMemo'
, DENSE_RANK() OVER (PARTITION BY baseSubscriptionId ORDER BY startDate, subscriptionId) AS 'RnkOrdr'
INTO [tmp_subs_dim]
FROM [dim_subscription]
--WHERE [dim_subscription].[refType] != 'Credit Memo'
ORDER BY [baseSubscriptionId]
       , [subscriptionId]

SELECT  * FROM [tmp_subs_dim]

/***************************************************************************************************************************
**                                          no_name_yet
** by: mmccanlies       02/13/2017
** Update no_name_yet table
***************************************************************************************************************************/
-- Use to update fields in subscription_dim and/or arr_fact
-- late renewal, late renewal days, entitled days for mid-term renewal and Credit Amt from previous subscription

SELECT
  sub1.baseSubscriptionId AS Base
, sub1.subscriptionId AS Sub1
, sub2.subscriptionId AS Sub2
, CONVERT(int,sub1.endDate-sub1.startDate) AS sub1Days
, CONVERT(int,sub2.endDate-sub2.startDate) AS sub2Days
, CASE WHEN CONVERT(int,sub1.endDate-sub2.invoiceDate) < 0
      THEN 1
      ELSE 0
  END AS isLateRenew
, CASE WHEN CONVERT(int,sub1.endDate-sub2.invoiceDate) < 0
      THEN CONVERT(int,sub1.endDate-sub2.invoiceDate)
      ELSE 0
  END AS lateRenewDays
, sub1.invoiceAmount

, CONVERT(int,sub1.endDate-sub2.startDate) AS startGap
,  CASE WHEN (sub2.refTypeId < 9) AND (sub2.RefType != 'CreditMemo')
      THEN
          CASE WHEN CONVERT(int,sub1.endDate-sub2.startDate) > 0
              THEN (1.0*CONVERT(int,sub1.endDate-sub2.startDate)/CONVERT(int,sub1.endDate-sub1.startDate))*sub1.invoiceAmount
          END
  END AS 'CreditAmt'
, sub1.endDate
, sub2.invoiceDate
, sub2.startDate
FROM (
        SELECT 
          sub1.baseSubscriptionId AS Base
        , sub1.subscriptionId AS Sub1
        , sub2.subscriptionId AS Sub2
        FROM [tmp_subs_dim] sub1
        JOIN [tmp_subs_dim] sub2 ON sub2.baseSubscriptionId = sub1.baseSubscriptionId
         AND (sub2.RnkOrdr-sub1.RnkOrdr) = 1
         AND sub1.isCreditMemo != 1
        UNION ALL
        SELECT 
          sub1.baseSubscriptionId AS Base
        , sub1.subscriptionId AS Sub1
        , sub2.subscriptionId AS Sub2
        FROM [tmp_subs_dim] sub1
        JOIN [tmp_subs_dim] subm ON subm.baseSubscriptionId = sub1.baseSubscriptionId AND (subm.RnkOrdr-sub1.RnkOrdr) = 1
         AND subm.isCreditMemo = 1
        JOIN [tmp_subs_dim] sub2 ON sub2.baseSubscriptionId = sub1.baseSubscriptionId
         AND (sub2.RnkOrdr-sub1.RnkOrdr) = 2 
    ) x
JOIN [tmp_subs_dim] sub1 ON sub1.baseSubscriptionId = x.Base AND sub1.subscriptionId = x.sub1
JOIN [tmp_subs_dim] sub2 ON sub2.baseSubscriptionId = x.Base AND sub2.subscriptionId = x.sub2
ORDER BY x.Base, x.Sub1
GO



/***************************************************************************************************************************
**                                          no_name_yet
** by: mmccanlies       02/07/2017
** Load no_name_yet table
** -- [vw_subsseq_dim]  - built on subscription_dim only
** -- [vw_subslist_dim] - built on vw_subsseq_dim
***************************************************************************************************************************/
-- Load no_name_yet
-- NOTE: you can't add another call to [dbo].[ufn_datediff_365] with maxrecursion = 100 you would have to increase recursion level.
-- This calculates basic ARR Calc which is the Credit Amount for subscription2 or CreditAmt2
-- ALSO remember invoiceDate and invoiceAmt are no longer in subscription_dim

SELECT
  sub1.baseSubscriptionId AS Base
, sub1.subscriptionId AS Sub1
, sub2.subscriptionId AS Sub2
, CAST(sub1.endDate AS date) AS endDate1
, CAST(sub2.startDate AS date) AS startDate2
, CAST(sub2.invoiceDate AS date) AS invoiceDate2
, SIGN(sub2.invoiceAmount-sub1.invoiceAmount) AS invoiceChg
, sub1.invoiceAmount AS invoiceAmt1
, sub2.invoiceAmount AS invoiceAmt2
, sub1.tier AS tier1
, sub2.tier AS tier2
, SIGN(sub2.tierLvl-sub1.tierLvl) AS tierChg
, sub1.tierLvl AS tierLvl1
, sub2.tierLvl AS tierLvl2
, SIGN(sub2.seats-sub1.seats) AS seatsChg
, sub1.seats AS seats1
, sub2.seats AS seats2
, SIGN(sub2.entitledDays-sub1.entitledDays) AS entitledDaysChg
, sub1.entitledDays AS entitledDays1
, sub2.entitledDays AS entitledDays2
, sub1.featureType AS FeatureType1
, sub2.featureType AS featureType2
, sub1.featureAmt AS featureAmt1
, sub2.featureAmt AS featureAmt2
, SIGN(sub2.maxVMRs-sub1.maxVMRs) AS vmrsChg
, sub1.maxVMRs AS maxVMRs1
, sub2.maxVMRs AS maxVMRs2
, CASE WHEN CONVERT(int,sub1.endDate-sub2.invoiceDate) < 0
      THEN 1
      ELSE 0
  END AS 'isLateRenew'
, [dbo].[ufn_datediff_365](sub2.invoiceDate, sub1.endDate) AS 'renewGapDays'
, [dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate) AS startGap
, ISNULL(
    CASE WHEN (sub2.refTypeId < 9) AND (sub2.RefType != 'CreditMemo')
      THEN
          CASE WHEN CONVERT(int,sub1.endDate-sub2.startDate) > 0
              THEN ISNULL(CONVERT(money,(1.0*[dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate)/[dbo].[ufn_datediff_365](sub1.startDate,sub1.endDate))*sub1.invoiceAmount),0)
          END
     END, 0) AS 'CreditAmt2'
FROM [vw_subsseq_dim] x
JOIN [vw_subslist_dim] sub1 ON sub1.baseSubscriptionId = x.Base AND sub1.subscriptionId = x.sub1
JOIN [vw_subslist_dim] sub2 ON sub2.baseSubscriptionId = x.Base AND sub2.subscriptionId = x.sub2
ORDER BY x.base, x.sub1


SELECT 
  baseSubscriptionId, subscriptionId
, arrAmt
, creditAmt
FROM fact_arr
ORDER BY baseSubscriptionId, CAST(subscriptionId AS int)

SELECT
  sub1.baseSubscriptionId AS Base
, sub1.subscriptionId AS Sub1
, sub2.subscriptionId AS Sub2
, CAST(sub1.endDate AS date) AS endDate1
, CAST(sub2.startDate AS date) AS startDate2
, CAST(sub2.invoiceDate AS date) AS invoiceDate2
, SIGN(sub2.invoiceAmount-sub1.invoiceAmount) AS invoiceChg
, [arr_fact].[arrAmtChg]
, [arr_fact].[amount] + [arr_fact].[creditAmt]
, sub1.invoiceAmount AS invoiceAmt1
, sub2.invoiceAmount AS invoiceAmt2
, sub1.tier AS tier1
, sub2.tier AS tier2
, SIGN(sub2.tierLvl-sub1.tierLvl) AS tierChg
, sub1.tierLvl AS tierLvl1
, sub2.tierLvl AS tierLvl2
, SIGN(sub2.seats-sub1.seats) AS seatsChg
, sub1.seats AS seats1
, sub2.seats AS seats2
, SIGN(sub2.entitledDays-sub1.entitledDays) AS entitledDaysChg
, sub1.entitledDays AS entitledDays1
, sub2.entitledDays AS entitledDays2
, sub1.featureType AS FeatureType1
, sub2.featureType AS featureType2
, sub1.featureAmt AS featureAmt1
, sub2.featureAmt AS featureAmt2
, SIGN(sub2.maxVMRs-sub1.maxVMRs) AS vmrsChg
, sub1.maxVMRs AS maxVMRs1
, sub2.maxVMRs AS maxVMRs2
, CASE WHEN CONVERT(int,sub1.endDate-sub2.invoiceDate) < 0
      THEN 1
      ELSE 0
  END AS 'isLateRenew'
, [dbo].[ufn_datediff_365](sub2.invoiceDate, sub1.endDate) AS 'renewGapDays'
, [dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate) AS startGap
, ISNULL(
    CASE WHEN (sub2.refTypeId < 9) AND (sub2.RefType != 'CreditMemo')
      THEN
          CASE WHEN CONVERT(int,sub1.endDate-sub2.startDate) > 0
              THEN ISNULL(CONVERT(money,(1.0*[dbo].[ufn_datediff_365](sub2.startDate,sub1.endDate)/[dbo].[ufn_datediff_365](sub1.startDate,sub1.endDate))*sub1.invoiceAmount),0)
          END
     END, 0) AS 'CreditAmt2'
FROM [vw_subsseq_dim] x
JOIN [vw_subslist_dim] sub1 ON sub1.baseSubscriptionId = x.Base AND sub1.subscriptionId = x.sub1
JOIN [vw_subslist_dim] sub2 ON sub2.baseSubscriptionId = x.Base AND sub2.subscriptionId = x.sub2
JOIN [arr_fact] ON [arr_fact].[subscrioptionId] = sub2.[subscriptionId]
ORDER BY x.base, x.sub1


SELECT 
  x.base
, x.sub1
, x.sub2
, CAST(arr1.endDateId AS date) AS endDate1
, CAST(arr2.startDateId AS date) AS startDate2
, CAST(sub2.invoiceDate AS date) AS invoiceDate2
, arr2.arrAmtChg AS arrAmountChg
, CASE WHEN arr1.isFeature = 0 AND arr2.isFeature = 0
    THEN CAST(SIGN(arr2.arrAmt-arr1.arrAmt) AS int) 
    ELSE 0 
  END AS arrAmtChg2
, arr1.arrAmt AS arrAmt1
, arr2.arrAmt AS arrAmt2
, arr1.creditAmt AS creditAmt1
, arr2.creditAmt AS creditAmt2
, arr2.tierChg AS arrTierChg
, sub1.tier AS tier1
, sub2.tier AS tier2
, sub1.tierLvl AS tierLvl1
, sub2.tierLvl AS tierLvl2
, arr2.seatsChg AS arrSeatsChg
, sub1.seats AS seats1
, sub2.seats AS seats2
, arr2.termDaysChg AS termDaysChg
, sub1.entitledDays AS entitledDays1
, sub2.entitledDays AS entitledDays2
, sub1.featureType AS FeatureType1
, sub2.featureType AS featureType2
, sub1.featureAmt AS featureAmt1
, sub2.featureAmt AS featureAmt2
, arr2.vmrsChg
, sub1.maxVMRs AS maxVMRs1
, sub2.maxVMRs AS maxVMRs2
, arr2.isLateRenew
, [dbo].[ufn_datediff_365](sub2.invoiceDate, sub1.endDate) AS 'renewGapDays'
, arr2.renewGapDays
, arr2.creditAmt
, arr1.creditAmt
, arr1.isNew
, arr2.isNew
, arr2.isRenewal
, arr2.isLateRenew
, arr2.renewGapDays
, arr2.creditMemo
, arr2.isFeature
FROM [vw_subsseq_dim] x
JOIN [fact_arr] arr1 ON arr1.baseSubscriptionId = x.Base AND arr1.subscriptionId = x.sub1
JOIN [fact_arr] arr2 ON arr2.baseSubscriptionId = x.Base AND arr2.subscriptionId = x.sub2
JOIN [vw_subslist_dim] sub1 ON sub1.baseSubscriptionId = x.Base AND sub1.subscriptionId = x.sub1
JOIN [vw_subslist_dim] sub2 ON sub2.baseSubscriptionId = x.Base AND sub2.subscriptionId = x.sub2
ORDER BY x.base, x.sub1

