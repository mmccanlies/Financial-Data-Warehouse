
--*******************************************************************************



-------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

SELECT COUNT(*) FROM [ns_custom_subscription] WHERE internalId IS NULL											UNION ALL --0
SELECT COUNT(*) FROM [ns_custom_subscription] WHERE [customFieldList-custrecord_base_subscription] IS NULL		UNION ALL --0
SELECT COUNT(*) FROM [ns_invoice] WHERE internalId IS NULL														UNION ALL --0
SELECT COUNT(*) FROM [ns_invoice_ItemList] WHERE internalId IS NULL												UNION ALL --0
SELECT COUNT(*) FROM [ns_invoice_ItemList] WHERE [item-internalId] IS NULL										UNION ALL --0
SELECT COUNT(*) FROM [ns_salesOrder] WHERE internalId IS NULL													UNION ALL --0
SELECT COUNT(*) FROM [ns_salesOrder_ItemList] WHERE [item-internalId] IS NULL									UNION ALL --0
SELECT COUNT(*) FROM [ns_custom_sales_out] WHERE [customFieldList-custrecord_sales_out_original_trans] IS NULL			  --162720

-----------------------------------
-- Loading Test Data

SELECT 
  [BaseSubscription]
, [Subscription]
, [RefType]
, [Tier]
, [Seats]
, [FeatureType]
, [FeatureAmt]
, [FeatureOrBase]
, [ItemTermYr]
, [ItemTermDay]
, [StartDate]
, [EndDate]
, [EntitledDays]
, [InvoiceDate]
, [InvoiceAmt]
, [Geo]
, [Region]
, [SubRegion]
, [Territory]
, [Salesperson]
, [BillToCustomerName]
, [BillToCustomerAddr]
, [EndCustomerName]
, [EndCustomerAddr]
, [BookingDate]
, [BillingDate]
, [SalesOutDate]
, [SalesOrderNo]
, [SalesInvoiceNo]
, [CustomerPoNo]
, [ProdClass]
, [ProdType]
, [ProdFamily]
, [ProdFamilyPL]
, [SKUNo]
, [SKUDescription]
, [SKUDuration]
, [SKUSeats]
, [ListPrice]
, [ListPrice]
, [ListPriceMo]
, [ListPriceDay]
, [StdDisc]
, [StdDiscYr]
, [StdDiscMo]
, [StdDisctDay]
, [ORNDisc]
, [ORNDiscYr]
, [ORNDiscMo]
, [ORNDiscDay]
, [NSDDisc]
, [NSDAppr]
, [NSDDiscYr]
, [NSDDiscMo]
, [NSDDiscDay]
, [ARRAmtMo]
, [ARRAmtDay]
, [ARRAmtInvoice]
, [ARRNewMo]
, [ARRBaseMo]
, [ARRBaseEnd]
, [ARRPriorMoEnd]
, [CreditAmt]
FROM [ARRWalk_TestData]
ORDER BY BaseSubscription, Subscription, [startDate]

-- Remove leading/trailing spaces
UPDATE [ARRWalk_TestData] SET
  BaseSubscription = LTRIM(RTRIM(BaseSubscription))
, Subscription = LTRIM(RTRIM(Subscription))
, RefType = LTRIM(RTRIM(RefType))
, Tier = LTRIM(RTRIM(Tier))
, BillToCustomerAddr = LTRIM(RTRIM(BillToCustomerAddr))
, ProdFamily =  LTRIM(RTRIM(ProdFamily))

UPDATE [ARRWalk_TestData] SET
 BillToCustomerAddr = LTRIM(RTRIM(BillToCustomerAddr))
--------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------
-- ARR Walk based on proto tables
--------------------------------------------------------------------------------------
-- ARR Walk Report
SELECT DISTINCT 
  [dim_subscription].[BaseSubscription]
, [dim_subscription].[subscription]
, [dim_subscription].[RefType]
, [dim_subscription].[Tier]
, [dim_subscription].[Seats]
, ISNULL([dim_subscription].[featureType],'') AS FeatureType
--, [dim_subscription].cloudFeatures AS CloudFeature  -- 22160 most common
, CASE WHEN ISNULL([dim_subscription].[featureType],'') != ''
    THEN [dim_subscription].[featureAmt]
    ELSE 0
  END AS FeatureAmt
, [dim_subscription].[featureAmt]
, [dim_salesorder].[soTermYrs]
, [dim_salesorder].[soTermMos]
, [dim_salesorder].[soTermDays]

, [dim_subscription].[StartDate]
, [dim_subscription].[EndDate]
, [dim_subscription].[EntitledDays]
, [dim_invoice].[invoiceDate] AS InvoiceDate
, [dim_subscription].[InvoiceAmount]
, [dim_salesorder].[soListPrice]
, [dim_salesorder].[soListPricePerYr] AS ListPriceYr
, [dim_salesorder].[soListPricePerMo] AS ListPriceMo
, [dim_salesorder].[soListPricePerDay] AS ListPriceDay

, [dim_subscription].StdDiscount AS StdDiscount
, [dim_salesorder].StdDiscAmtYrs AS StdDiscountYrs
, [dim_salesorder].StdDiscAmtMos AS StdDiscountMos
, [dim_salesorder].StdDiscAmtDays AS StdDiscountDays
, [dim_subscription].[ORNDiscount] AS ORNDiscount
, [dim_salesorder].ORNDiscAmtYrs AS ORNDiscountYrs
, [dim_salesorder].ORNDiscAmtMos AS ORNDiscountMos
, [dim_salesorder].ORNDiscAmtDays AS ORNDiscountDays
, [dim_subscription].[NSDDiscount] AS NSDDiscount
, [dim_salesorder].NSDDiscAmtYrs AS NSDDiscountYrs
, [dim_salesorder].NSDDiscAmtMos AS NSDDiscountMos
, [dim_salesorder].NSDDiscAmtDays AS NSDDiscountDays
, [dim_subscription].NSDApprovalNo AS NSDApprovalNo

, [dim_subscription].[FeatureOrBase]
, [dim_product].[skuNo]
, [dim_product].[skuDescription]
, [dim_product].[skuDurationYrs]
, [dim_product].[skuSeats]
, [dim_product].[className]
, [dim_product].[productClass]
, [dim_product].[productType]
, [dim_product].[productFamily]
, [dim_product].[productFamilyPL]
, [dim_salesorg].[geo] AS 'Geo'
, [dim_salesorg].[region] AS 'Region'
, [dim_salesorg].[subRegion] AS 'Sub-Region'
, [dim_salesorg].[territory] AS 'Territory'
, [dim_salesorg].[salesPerson] AS 'SalesPerson'
, [dim_invoice].[BillToCustomerName]
, [dim_invoice].[BillToCustomerAddress]
, [dim_subscription].[endCustomerName]
, [dim_subscription].[endCustomerAddr]

, [dim_subscription].[baseSubscriptionId]
, [dim_subscription].[subscriptionId]
, [dim_invoice].[invItemId]
FROM [dim_subscription]
JOIN [fact_arr] ON [dim_subscription].[subscriptionId] = [fact_arr].[subscriptionId]
JOIN [dim_invoice] ON [dim_invoice].[invoiceId] = [fact_arr].[invoiceId] AND [dim_invoice].[invoiceLine] = [fact_arr].[invoiceLine]
JOIN [dim_salesorder] ON [dim_salesorder].[salesOrderId] = [fact_arr].[salesOrderId] AND [dim_salesorder].[salesOrderLine] = [fact_arr].[salesOrderLine]
JOIN [dim_product] ON [dim_product].[itemId] = [fact_arr].[itemId]
JOIN [dim_salesorg] ON [dim_salesorg].[sourceId] = [fact_arr].[salesOrgId]
ORDER BY [dim_subscription].[baseSubscriptionId], [dim_subscription].[subscriptionId]


------------------------------------------------------------------------------------------------
-- ARR Walk Dimension demo SQL
--------------------------------------------------------------------------------------

SELECT DISTINCT
  CONVERT(int,[fact_arr].[BaseSubscriptionId]) AS 'Base Subscription Id'
, CONVERT(int,[fact_arr].[subscriptionId]) AS 'Subscription Id'
, [dim_subscription].BaseSubscription AS 'Base Subscription'
, [dim_subscription].subscription AS 'Subscription'
, [dim_subscription].isBase AS isBase
, [dim_subscription].RefType AS RefType
-- , customFieldList-custrecord_subscription_transaction_line AS  trans_line
, [dim_subscription].refTypeId AS RefTypeId
, [dim_subscription].tierName AS Tier
, [dim_subscription].Seats AS Seats
, [dim_subscription].featureType AS FeatureType
--, [dim_subscription].cloudFeatures AS CloudFeature  -- 22160 most common
, [dim_subscription].featureAmt AS FeatureAmt
--, [dim_subscription].vmrsLicenses AS VMRS
, [dim_salesorder].[soTermYrs] AS ItemTermYrs
, [dim_salesorder].[soTermMos] AS ItemTermMos
, [dim_salesorder].[soTermDays] AS ItemTermDays

, [dim_subscription].StartDate AS StartDate
, [dim_subscription].EndDate AS EndDate
, [dim_subscription].EntitledDays AS EntitledDays

, [dim_invoice].[invoiceDate] AS InvoiceDate
, [dim_invoice].[invRate] AS InvoiceAmt

, [dim_salesorder].[soListPrice] AS soListPrice
, [dim_salesorder].[soListPricePerYr] AS soListPricePerYr
, [dim_salesorder].[soListPricePerMo] AS soListPricePerMo
, [dim_salesorder].[soListPricePerDay] AS soListPricePerDay

, [dim_salesorder].StdDiscount AS StdDiscount
, [dim_salesorder].StdDiscAmtYrs AS StdDiscountYrs
, [dim_salesorder].StdDiscAmtMos AS StdDiscountMos
, [dim_salesorder].StdDiscAmtDays AS StdDiscountDays
, [dim_salesorder].ORNDiscount AS ORNDiscount
, [dim_salesorder].ORNDiscAmtYrs AS ORNDiscountYrs
, [dim_salesorder].ORNDiscAmtMos AS ORNDiscountMos
, [dim_salesorder].ORNDiscAmtDays AS ORNDiscountDays
, [dim_salesorder].NSDDiscount AS NSDDiscount
, [dim_salesorder].NSDDiscAmtYrs AS NSDDiscountYrs
, [dim_salesorder].NSDDiscAmtMos AS NSDDiscountMos
, [dim_salesorder].NSDDiscAmtDays AS NSDDiscountDays
, [dim_subscription].NSDApprovalNo AS NSDApprovalNo

, [dim_subscription].FeatureOrBase AS FeatureOrBase
, [dim_product].[skuNo] AS skuNo
, [dim_product].[skuDescription] AS skuDescription
, [dim_product].[skuDurationYrs] AS skuDurationYrs
, [dim_product].[skuSeats] AS skuSeats
, [dim_product].[productClass] AS productClass
, [dim_product].[productType] AS productType
, [dim_product].[productFamily] AS productFamily
, [dim_product].[productFamilyPL] AS productFamilyPL

, [dim_salesorg].[geo] AS 'Geo'
, [dim_salesorg].[region] AS 'Region'
, [dim_salesorg].[subRegion] AS 'Sub-Region'
, [dim_salesorg].[territory] AS 'Territory'
, [dim_salesorg].[salesPerson] AS 'SalesPerson'

, [dim_customer].[catName] AS salesCategory
, [dim_invoice].[BillToCustomerName] AS BillToCustomerName
, [dim_invoice].[BillToCustomerAddress] AS BillToCustomerAddress
, [dim_salesorder].[endCustomerName] AS EndCustomerName
, [dim_salesorder].[endCustomerAddress] AS EndCustomerAddress
, [dim_salesout].[outReseller] AS ResellerName
, NULL AS ResellerAddr

, [dim_salesorder].soBookingDate AS BookingDate
, [dim_invoice].billingDate AS BillingDate
, NULL AS SalesOutDate   -- FROM dim_salesout
, [dim_salesorder].[salesOrderNo] AS salesOrderNo
, [dim_invoice].[invoiceNo] AS invoiceNo
, [dim_salesorder].[soCustomerPONo] AS soCustomerPONo
, [dim_subscription].[itemId] AS 'ItemId #'
, [fact_arr].[arrAmtPerYr]
, [fact_arr].[invoiceAmt]
, [fact_arr].[creditAmt]
, [fact_arr].[seats]
, [fact_arr].[amplifyHrs]
, [fact_arr].[recordingHrs]
, [fact_arr].[vmrs]
, [fact_arr].[arrAmtChg]
, [fact_arr].[tierChg]
, [fact_arr].[seatsChg]
, [fact_arr].[termDaysChg]
, [fact_arr].[vmrsChg]
, [fact_arr].[isNew]
, [fact_arr].[isRenewal]
, [fact_arr].[isLateRenew]
, [fact_arr].[renewGapDays]
, [fact_arr].[iscreditMemo]
, [fact_arr].[isFeature]
, [fact_arr].[isUpDngrade]
, [fact_arr].[isExpansion]
, [fact_arr].[isChurn]

FROM [dim_subscription]
JOIN [fact_arr] ON [dim_subscription].[subscriptionId] = [fact_arr].[subscriptionId]
JOIN [dim_invoice] ON [dim_invoice].[invoiceId] = [fact_arr].[invoiceId] AND [dim_invoice].[invoiceLine] = [fact_arr].[invoiceLine]
JOIN [dim_salesorder] ON [dim_salesorder].[salesOrderId] = [fact_arr].[salesOrderId] AND [dim_salesorder].[salesOrderLine] = [fact_arr].[salesOrderLine]
JOIN [dim_product] ON [dim_product].[itemId] = [fact_arr].[itemId]
JOIN [dim_salesorg] ON [dim_salesorg].[sourceId] = [fact_arr].[salesOrgId]
JOIN [dim_salesout] ON [dim_salesout].[salesOutId] = [fact_arr].[salesOutId]
JOIN [dim_customer] ON [dim_customer].[internalId] = [fact_arr].[billToCustomerId]
ORDER BY CONVERT(int,[fact_arr].[BaseSubscriptionId]), CONVERT(int,[fact_arr].[subscriptionId])



SELECT DISTINCT
  CONVERT(int,[fact_arr].[BaseSubscriptionId])
, CONVERT(int,[fact_arr].[subscriptionId])
, [dim_subscription].StartDate AS StartDate
, [dim_subscription].EndDate AS EndDate
, [dim_subscription].EntitledDays AS EntitledDays
, [dim_invoice].[invoiceDate] AS InvoiceDate
, [fact_arr].[arrAmtChg]
, [fact_arr].[arrAmt]
, [dim_invoice].[invRate] AS InvoiceAmt
, [fact_arr].[invoiceAmt]
, [fact_arr].[creditAmt]
, [fact_arr].[seats]
, [fact_arr].[amplifyHrs]
, [fact_arr].[recordingHours]
, [fact_arr].[vmrs]
, [fact_arr].[tierChg]
, [fact_arr].[seatsChg]
, [fact_arr].[termDaysChg]
, [fact_arr].[vmrsChg]
, [fact_arr].[isNew]
, [fact_arr].[isRenewal]
, [fact_arr].[isLateRenew]
, [fact_arr].[isFeature]

FROM [dim_subscription]
JOIN [fact_arr] ON [dim_subscription].[subscriptionId] = [fact_arr].[subscriptionId]
JOIN [dim_invoice] ON [dim_invoice].[invoiceId] = [fact_arr].[invoiceId] AND [dim_invoice].[invoiceLine] = [fact_arr].[invoiceLine]
JOIN [dim_salesorder] ON [dim_salesorder].[salesOrderId] = [fact_arr].[salesOrderId] AND [dim_salesorder].[salesOrderLine] = [fact_arr].[salesOrderLine]
JOIN [dim_product] ON [dim_product].[itemId] = [fact_arr].[itemId]
JOIN [dim_salesorg] ON [dim_salesorg].[sourceId] = [fact_arr].[salesOrgId]
JOIN [dim_salesout] ON [dim_salesout].[salesOutId] = [fact_arr].[salesOutId]
JOIN [dim_customer] ON [dim_customer].[internalId] = [fact_arr].[billToCustomerId]
ORDER BY CONVERT(int,[fact_arr].[BaseSubscriptionId]), CONVERT(int,[fact_arr].[subscriptionId])

SELECT TOP 150 
  ISNULL(CONVERT(int,[ns_invoice_itemlist].[customFieldList-custcol_subscription]),-1) AS 'subscriptionId'
, ISNULL(CONVERT(int, [ns_custom_subscription].[customFieldList-custrecord_base_subscription]),-1) AS 'baseSubscriptionId'
FROM [ns_custom_subscription] 
LEFT OUTER JOIN [ns_salesorder] ON ISNULL([ns_salesorder].[internalId],-1) = ISNULL([ns_custom_subscription].[customFieldList-custrecord_subscription_transaction],-1)
LEFT OUTER JOIN [ns_salesorder_itemlist] ON ISNULL([ns_salesorder_itemlist].[internalId],-1) = ISNULL([ns_salesorder].[internalId],-1)
	        AND [ns_salesorder_itemlist].[line] = [ns_custom_subscription].[customFieldList-custrecord_subscription_transaction_line]  -- Added
LEFT OUTER JOIN [ns_invoice] ON ISNULL([ns_invoice].[createdFrom-internalId],-1) = ISNULL([ns_salesorder].[internalId],-1)
LEFT OUTER JOIN [ns_invoice_itemlist] ON ISNULL([ns_invoice_itemlist].[internalId],-1) = ISNULL([ns_invoice].[internalId],-1) 
	        AND TRY_CAST(ISNULL([ns_invoice_itemlist].[customFieldList-custcol_line_id],1) AS numeric) = TRY_CAST(ISNULL([ns_salesorder_itemlist].[customFieldList-custcol_line_id],1) AS numeric)   -- Added
AND ISNULL(CONVERT(int,[ns_invoice_itemlist].[customFieldList-custcol_subscription]),-1)  != -1
AND ISNULL(CONVERT(int, [ns_custom_subscription].[customFieldList-custrecord_base_subscription]),-1) != 1
ORDER BY [ns_invoice].[tranDate] DESC



------------------------------------------------------------------------------------------------
-- ARR Walk Buckets demo SQL
------------------------------------------------------------------------------------------------
SELECT DISTINCT *
INTO #tmp
FROM arr_walk_report_1
DROP TABLE arr_walk_report_1
SELECT *
INTO arr_walk_report_1
FROM #tmp

commit

-- Query to Copy Paste results directly into Excel
SELECT DISTINCT
  CONVERT(int,[dim_subscription].[BaseSubscriptionId]) AS 'Base Subscription Id'
, CONVERT(int,[dim_subscription].[subscriptionId]) AS 'Subscription Id'
, [dim_subscription].BaseSubscription AS 'Base Subscription'
, [dim_subscription].subscription AS 'Subscription'
, [dim_subscription].isBase AS 'isBase'
, [dim_subscription].RefType AS 'Ref Type'
, [dim_subscription].refTypeId AS 'Ref Type Id'
, [dim_subscription].refTypeTxt AS 'RefType Txt'
, [dim_subscription].tierId AS 'Tier'
, [dim_subscription].tierLvl AS 'Tier Lvl'
, [dim_subscription].tierName AS 'Tier Name'
, [dim_subscription_details].seats AS 'Seats'
, [dim_subscription_details].totalSeats AS 'Total Seats'
, [dim_subscription].featureType AS 'Feature Type'
, [dim_subscription].featureAmt AS 'Feature Amt'
, [dim_salesorder].[soTermYrs] AS 'Item Term Yrs'
, [dim_salesorder].[soTermMos] AS 'Item Term Mos'
, [dim_salesorder].[soTermDays] AS 'Item Term Days'

, [dim_subscription].StartDate AS 'Start Date'
, [dim_subscription].EndDate AS 'End Date'
, [dim_subscription].EntitledYrs AS 'Entitled Yrs'
, [dim_subscription].EntitledMos AS 'Entitled Mos'
, [dim_subscription].EntitledDays AS 'Entitled Days'

, [dim_subscription].[invoiceDate] AS 'Invoice Date'
, [fact_arr].[invoiceAmt] AS 'Invoice Amt'

, [dim_salesorder].[soListPrice] AS 'List Price'
, [dim_salesorder].[soListPricePerYr] AS 'List Price Per Yr'
, [dim_salesorder].[soListPricePerMo] AS 'List Price Per Mo'
, [dim_salesorder].[soListPricePerDay] AS 'List Price Per Day'

, [dim_salesorder].StdDiscount AS 'Std Discount'
, [dim_salesorder].StdDiscAmtYrs AS 'Std Discount Yrs'
, [dim_salesorder].StdDiscAmtMos AS 'Std Discount Mos'
, [dim_salesorder].StdDiscAmtDays AS 'Std Discount Days'
, [dim_salesorder].ORNDiscount AS 'ORN Discount'
, [dim_salesorder].ORNDiscAmtYrs AS 'ORN Discount Yrs'
, [dim_salesorder].ORNDiscAmtMos AS 'ORN Discount Mos'
, [dim_salesorder].ORNDiscAmtDays AS 'ORN Discount Days'
, [dim_salesorder].NSDDiscount AS 'NSD Discount'
, [dim_salesorder].NSDDiscAmtYrs AS 'NSD Discount Yrs'
, [dim_salesorder].NSDDiscAmtMos AS 'NSD Discount Mos'
, [dim_salesorder].NSDDiscAmtDays AS 'NSD Discount Days'
, [dim_subscription].NSDApprovalNo AS 'NSD Approval No'

, [dim_subscription].FeatureOrBase AS 'Feature Or Base'
, [dim_product].[skuNo] AS 'Sku No'
, [dim_product].[skuDescription] AS 'Sku Description'
, [dim_product].[skuDurationYrs] AS 'Sku Duration Yrs'
, [dim_product].[skuSeats] AS 'sSu Seats'
, [dim_product].[productClass] AS 'Product Class'
, [dim_product].[productType] AS 'Product Type'
, [dim_product].[productFamily] AS 'Product Family'
, [dim_product].[productFamilyPL] AS 'Product FamilyPL'

, [dim_salesorg].[geo] AS 'Geo'
, [dim_salesorg].[region] AS 'Region'
, [dim_salesorg].[subRegion] AS 'Sub Region'
, [dim_salesorg].[territory] AS 'Territory'
, [dim_salesorg].[salesPerson] AS 'Sales Person'

, [dim_customer].[catName] AS 'Sales Category'
, [dim_invoice].[BillToCustomerName] AS 'Bill To Customer Name'
, [dim_invoice].[BillToCustomerAddress] AS 'Bill To Customer Addr'
, [dim_subscription].[endCustomerName] AS 'End Customer Name'
, [dim_subscription].[endCustomerAddr] AS 'End Customer Addr'
, [dim_salesout].[outReseller] AS 'Reseller Name'
, NULL AS 'Reseller Addr'

, [dim_salesorder].soBookingDate AS 'Booking Date'
, [dim_invoice].billingDate AS 'Billing Date'
, [dim_salesout].[outDate] AS 'Sales Out Date'   -- FROM dim_salesout
, [dim_salesorder].[salesOrderNo] AS 'Sales Order No.'
, [dim_invoice].[invoiceNo] AS 'Invoice No.'
, [dim_salesorder].[soCustomerPONo] AS 'Customer PO No.'
, [dim_subscription].[itemId]  AS 'Item Id'

, [dim_subscription_details].[prefix]+[dim_subscription_details].[entitlementTerm]+[dim_subscription_details].[priceTerm] AS 'ARR Category'
, [dim_subscription_details].[termDays] AS 'Term Days'
, [dim_subscription_details].[invoiceAmount] AS 'Invoice Amt'
, [dim_subscription_details].[arrAmtPerYr] AS 'ARR Amt Per Yr'
, [dim_subscription_details].[totalArrAmtPerYr] AS 'Total ARR Amt Per Yr'
, [fact_arr].[creditAmt] AS 'Credit Amt'
, [dim_subscription_details].[arrDelta] AS 'ARR Delta'
, [dim_subscription_details].[arrAmtChg] AS 'ARR Amt Chg'
, [dim_subscription_details].[entitlementChg] AS 'Entitlement Chg'
, [dim_subscription_details].[tierChg] AS 'Tier Chg'
, [dim_subscription_details].[seatChg] AS 'Seat Chg'
, [dim_subscription_details].[daysBtwPriorEndAndCurrStart] AS 'Days Between Prior End And Current Start'
, [dim_subscription_details].[daysTilExpiration] AS 'Days Til Expiration'
, [dim_subscription_details].[termChg] AS 'Term Chg'
, [dim_subscription_details].[amplifyQty] AS 'Amplify Qty'
, [dim_subscription_details].[extremeQty] AS 'Extreme Hrs'
, [dim_subscription_details].[vmrsQty] AS 'VMR Qty'
, [dim_subscription_details].[recordingHrs] AS 'Recording Hrs'
, [dim_subscription_details].[newBase] AS 'New Base'
, [dim_subscription_details].[updateOrdr]
, [dim_subscription_details].[baseIdOrdr]
, [fact_arr].[isNew]
, [fact_arr].[isRenewal]
, [fact_arr].[isLateRenew]
, [fact_arr].[renewGapDays] AS 'Renew Gap Days'
, [dim_subscription].[isCreditMemo]
, [fact_arr].[isFeature]
, [fact_arr].[isUpDngrade]
, [fact_arr].[isExpansion]
, [fact_arr].[isChurn]
FROM [dim_subscription]
JOIN [dim_subscription_details] ON [dim_subscription_details].[subscriptionId] = [dim_subscription].[subscriptionId] AND [dim_subscription_details].[isCreditMemo] = [dim_subscription].[isCreditMemo]
JOIN [fact_arr] ON [dim_subscription].[subscriptionId] = [fact_arr].[subscriptionId] AND  [dim_subscription].[isCreditMemo] = [fact_arr].[isCreditMemo]
JOIN [dim_invoice] ON [dim_invoice].[invoiceId] = [fact_arr].[invoiceId] AND [dim_invoice].[invoiceLine] = [fact_arr].[invoiceLine]
JOIN [dim_salesorder] ON [dim_salesorder].[salesOrderId] = [fact_arr].[salesOrderId] AND [dim_salesorder].[salesOrderLine] = [fact_arr].[salesOrderLine]
JOIN [dim_product] ON [dim_product].[itemId] = [fact_arr].[itemId]
JOIN [dim_salesorg] ON [dim_salesorg].[sourceId] = [fact_arr].[salesOrgId]
JOIN [dim_salesout] ON [dim_salesout].[salesOutId] = [fact_arr].[salesOutId]
JOIN [dim_customer] ON [dim_customer].[internalId] = [fact_arr].[billToCustomerId]
ORDER BY CONVERT(int,[dim_subscription].[baseSubscriptionId]), CONVERT(int,[dim_subscription].[subscriptionId])



----
sp_dim_subscription 1,0
sp_dim_subscription_details 1,0

COMMIT

SELECT * FROM arr_walk_report_1
--- DROP TABLE [arr_walk_report_3]
GO
TRUNCATE TABLE [arr_walk_report_3]

INSERT INTO [arr_walk_report_3] 
( baseSubscriptionId, subscriptionId, baseSubscription, subscription, isBase, refType, refTypeId, refTypeTxt, tier, tierLvl, tierName, seats
, totalSeats, featureType, featureAmt, itemTermYrs, itemTermMos, itemTermDays, startDate, endDate, entitledYrs, entitledMos, entitledDays, invoiceDate
, invoiceAmt, listPrice, listPricePerYr, listPricePerMo, listPricePerDay, stdDiscount, stdDiscountYrs, stdDiscountMos, stdDiscountDays, ORNDiscount
, ORNDiscountYrs, ORNDiscountMos, ORNDiscountDays, NSDDiscount, NSDDiscountYrs, NSDDiscountMos, NSDDiscountDays, NSDApprovalNo, featureOrBase, skuNo
, skuDescription, skuDurationYrs, skuSeats, productClass, productType, productFamily, productFamilyPL, geo, region, subRegion, territory, salesPerson
, salesCategory, billToCustomerName, billToCustomerAddress, endCustomerName, endCustomerAddress, resellerName, resellerAddr, bookingDate, billingDate
, salesOutDate, salesOrderNo, invoiceNo, customerPONo, itemId, ARRCategory, termDays, invoiceAmount, arrAmtPerYr, totalArrAmtPerYr, creditAmt, arrDelta
, arrAmtChg, entitlementChg, tierChg, seatChg, daysBtwPriorEndAndCurrStart, daysTilExpiration, termChg, amplifyQty, extremeQty, vmrsQty, recordingHrs
, newBase, updateOrdr, baseIdOrdr, isNew, isRenewal, isLateRenew, renewGapDays, iscreditMemo, isFeature, isUpDngrade, isExpansion, isChurn
)
-- Query to insert results into ARR_Walk_Report_n table for analysis

SELECT DISTINCT
  CONVERT(int,[dim_subscription].[BaseSubscriptionId]) AS 'baseSubscriptionId'
, CONVERT(int,[dim_subscription].[subscriptionId]) AS 'subscriptionId'
, [dim_subscription].BaseSubscription AS 'baseSubscription'
, [dim_subscription].subscription AS 'subscription'
, [dim_subscription].isBase AS 'isBase'
, [dim_subscription].RefType AS 'refType'
, [dim_subscription].refTypeId AS 'refTypeId'
, [dim_subscription].refTypeTxt AS 'refTypeTxt'
, [dim_subscription].tierId AS 'tier'
, [dim_subscription].tierLvl AS 'tierLvl'
, [dim_subscription].tierName AS 'tierName'
, [dim_subscription_details].seats AS 'seats'
, [dim_subscription_details].totalSeats AS 'totalSeats'
, [dim_subscription].featureType AS 'featureType'
, [dim_subscription].featureAmt AS 'featureAmt'
, [dim_salesorder].[soTermYrs] AS 'itemTermYrs'
, [dim_salesorder].[soTermMos] AS 'itemTermMos'
, [dim_salesorder].[soTermDays] AS 'itemTermDays'

, [dim_subscription].StartDate AS 'startDate'
, [dim_subscription].EndDate AS 'endDate'
, [dim_subscription].EntitledYrs AS 'entitledYrs'
, [dim_subscription].EntitledMos AS 'entitledMos'
, [dim_subscription].EntitledDays AS 'entitledDays'

, [dim_subscription].[invoiceDate] AS 'invoiceDate'
, [fact_arr].[invoiceAmt] AS 'invoiceAmt'

, [dim_salesorder].[soListPrice] AS 'listPrice'
, [dim_salesorder].[soListPricePerYr] AS 'listPricePerYr'
, [dim_salesorder].[soListPricePerMo] AS 'listPricePerMo'
, [dim_salesorder].[soListPricePerDay] AS 'listPricePerDay'

, [dim_salesorder].StdDiscount AS 'stdDiscount'
, [dim_salesorder].StdDiscAmtYrs AS 'stdDiscountYrs'
, [dim_salesorder].StdDiscAmtMos AS 'stdDiscountMos'
, [dim_salesorder].StdDiscAmtDays AS 'stdDiscountDays'
, [dim_salesorder].ORNDiscount AS 'ORNDiscount'
, [dim_salesorder].ORNDiscAmtYrs AS 'ORNDiscountYrs'
, [dim_salesorder].ORNDiscAmtMos AS 'ORNDiscountMos'
, [dim_salesorder].ORNDiscAmtDays AS 'ORNDiscountDays'
, [dim_salesorder].NSDDiscount AS 'NSDDiscount'
, [dim_salesorder].NSDDiscAmtYrs AS 'NSDDiscountYrs'
, [dim_salesorder].NSDDiscAmtMos AS 'NSDDiscountMos'
, [dim_salesorder].NSDDiscAmtDays AS 'NSDDiscountDays'
, [dim_subscription].NSDApprovalNo AS 'NSDApprovalNo'

, [dim_subscription].FeatureOrBase AS 'featureOrBase'
, [dim_product].[skuNo] AS 'skuNo'
, [dim_product].[skuDescription] AS 'skuDescription'
, [dim_product].[skuDurationYrs] AS 'skuDurationYrs'
, [dim_product].[skuSeats] AS 'skuSeats'
, [dim_product].[productClass] AS 'productClass'
, [dim_product].[productType] AS 'productType'
, [dim_product].[productFamily] AS 'productFamily'
, [dim_product].[productFamilyPL] AS 'productFamilyPL'

, [dim_salesorg].[geo] AS 'geo'
, [dim_salesorg].[region] AS 'region'
, [dim_salesorg].[subRegion] AS 'subRegion'
, [dim_salesorg].[territory] AS 'territory'
, [dim_salesorg].[salesPerson] AS 'salesPerson'

, [dim_customer].[catName] AS 'salesCategory'
, [dim_invoice].[BillToCustomerName] AS 'billToCustomerName'
, [dim_invoice].[BillToCustomerAddress] AS 'billToCustomerAddress'
, [dim_subscription].[endCustomerName] AS 'endCustomerName'
, [dim_subscription].[endCustomerAddr] AS 'endCustomerAddress'
, [dim_salesout].[outReseller] AS 'resellerName'
, NULL AS 'resellerAddr'

, [dim_salesorder].soBookingDate AS 'bookingDate'
, [dim_invoice].billingDate AS 'billingDate'
, [dim_salesout].[outDate] AS 'salesOutDate'   -- FROM dim_salesout
, [dim_salesorder].[salesOrderNo] AS 'salesOrderNo'
, [dim_invoice].[invoiceNo] AS 'invoiceNo'
, [dim_salesorder].[soCustomerPONo] AS 'customerPONo'
, [dim_subscription].[itemId]  AS 'itemId'

, [dim_subscription_details].[prefix]+[dim_subscription_details].[entitlementTerm]+[dim_subscription_details].[priceTerm] AS 'ARRCategory'
, [dim_subscription_details].[termDays]
, [dim_subscription_details].[invoiceAmount]
, [dim_subscription_details].[arrAmtPerYr]
, [dim_subscription_details].[totalArrAmtPerYr]
, [fact_arr].[creditAmt] AS 'creditAmt'
, [dim_subscription_details].[arrDelta] AS 'arrDelta'
, [dim_subscription_details].[arrAmtChg]
, [dim_subscription_details].[entitlementChg]
, [dim_subscription_details].[tierChg]
, [dim_subscription_details].[seatChg]
, [dim_subscription_details].[daysBtwPriorEndAndCurrStart]
, [dim_subscription_details].[daysTilExpiration]
, [dim_subscription_details].[termChg]
, [dim_subscription_details].[amplifyQty]
, [dim_subscription_details].[extremeQty]
, [dim_subscription_details].[vmrsQty]
, [dim_subscription_details].[recordingHrs]
, [dim_subscription_details].[newBase]
, [dim_subscription_details].[updateOrdr]
, [dim_subscription_details].[baseIdOrdr]
, [fact_arr].[isNew]
, [fact_arr].[isRenewal]
, [fact_arr].[isLateRenew]
, [fact_arr].[renewGapDays]
, [dim_subscription].[iscreditMemo]
, [fact_arr].[isFeature]
, [fact_arr].[isUpDngrade]
, [fact_arr].[isExpansion]
, [fact_arr].[isChurn]
 INTO [arr_walk_report_3] 
FROM [dim_subscription]  WITH (NOLOCK) 
LEFT JOIN [dim_subscription_details] WITH (NOLOCK) ON [dim_subscription_details].[subscriptionId] = [dim_subscription].[subscriptionId] AND [dim_subscription_details].[isCreditMemo] = [dim_subscription].[isCreditMemo]
LEFT JOIN [fact_arr] WITH (NOLOCK) ON [dim_subscription].[subscriptionId] = [fact_arr].[subscriptionId] AND  [dim_subscription].[isCreditMemo] = [fact_arr].[isCreditMemo]
LEFT JOIN [dim_invoice] WITH (NOLOCK) ON [dim_invoice].[invoiceId] = [fact_arr].[invoiceId] AND [dim_invoice].[invItemLineId] = [fact_arr].[invItemLineId]
LEFT JOIN [dim_salesorder] WITH (NOLOCK) ON [dim_salesorder].[salesOrderId] = [fact_arr].[salesOrderId] AND [dim_salesorder].[salesOrderLine] = [fact_arr].[salesOrderItemLineId]
LEFT JOIN [dim_product] WITH (NOLOCK) ON [dim_product].[itemId] = [fact_arr].[itemId]
LEFT JOIN [dim_salesorg] WITH (NOLOCK) ON [dim_salesorg].[sourceId] = [fact_arr].[salesOrgId]
LEFT JOIN [dim_salesout] WITH (NOLOCK) ON [dim_salesout].[salesOutId] = [fact_arr].[salesOutId]
LEFT JOIN [dim_customer] WITH (NOLOCK) ON [dim_customer].[internalId] = [fact_arr].[billToCustomerId]
WHERE [dim_subscription].[baseSubscriptionId] IN 
( 57, 60, 167, 217, 352, 563, 580, 834, 837, 845, 1153, 1349, 1517, 1544, 3369, 3393, 3471, 3491, 3525, 3771, 4015, 4206, 4901, 5408, 6366 )
ORDER BY CONVERT(int,[dim_subscription].[baseSubscriptionId]), CONVERT(int,[dim_subscription].[subscriptionId]), isCreditMemo

commit


SELECT distinct * --CONVERT(int,[dim_subscription].[baseSubscriptionId]), CONVERT(int,[dim_subscription].[subscriptionId]) 
FROM [dim_subscription]  WITH (NOLOCK) 
JOIN [dim_subscription_details] ON [dim_subscription_details].[subscriptionId] = [dim_subscription].[subscriptionId] AND [dim_subscription_details].[isCreditMemo] = [dim_subscription].[isCreditMemo]
LEFT JOIN [fact_arr] ON [dim_subscription].[subscriptionId] = [fact_arr].[subscriptionId] AND  [dim_subscription].[isCreditMemo] = [fact_arr].[isCreditMemo]
LEFT JOIN [dim_invoice] ON [dim_invoice].[invoiceId] = [fact_arr].[invoiceId] AND [dim_invoice].[invoiceLine] = [fact_arr].[invoiceLine]
LEFT JOIN [dim_salesorder] ON [dim_salesorder].[salesOrderId] = [fact_arr].[salesOrderId] AND [dim_salesorder].[salesOrderLine] = [fact_arr].[salesOrderLine]
LEFT JOIN [dim_product] ON [dim_product].[itemId] = [fact_arr].[itemId]
LEFT JOIN [dim_salesorg] ON [dim_salesorg].[sourceId] = [fact_arr].[salesOrgId]
JOIN [dim_salesout] ON [dim_salesout].[salesOutId] = [fact_arr].[salesOutId]
JOIN [dim_customer] ON [dim_customer].[internalId] = [fact_arr].[billToCustomerId]
ORDER BY CONVERT(int,[dim_subscription].[baseSubscriptionId]), CONVERT(int,[dim_subscription].[subscriptionId])

SELECT DISTINCT [dim_subscription_details].baseSubscriptionId, [dim_subscription_details].subscriptionId 
FROM [dim_subscription_details] 

ON [dim_subscription_details].[subscriptionId] = [dim_subscription].[subscriptionId] AND [dim_subscription_details].[isCreditMemo] = [dim_subscription].[isCreditMemo]

SELECT * FROM xrf_index
SELECT * FROM fact_arr
SELECT * FROM dim_subscription

SELECT * 
FROM [dbo].[arr_walk_report_3]


WHERE baseSubscriptionId IN 
/*
( '131', '359', '663', '738', '757', '761', '780', '788', '791', '805', '840', '867', '870', '871', '902', '907'     -- First 147
, '914', '920', '925', '944', '962', '1047', '1140', '1144', '1348', '1511', '3702', '4334', '4538', '4600'
, '4698', '4719', '4833', '4880', '4883', '4939', '4941', '4985', '4987', '4993', '5042', '5043', '5048'
, '5050', '5087', '5094', '5098', '5119', '5122', '5129', '5131', '5159', '5163', '5167', '5189', '5219'
, '5222', '5238', '5286', '5298', '5344', '5374', '5389', '5393', '5400', '5420', '5444', '5512', '5578'
, '5591', '5653', '5657', '5874', '6042', '6300', '6648', '6936', '7583', '7597', '8113', '8141', '9446'
, '9472', '9790', '9798', '9799', '9807', '9815', '9816', '9825', '9828', '9833', '9836', '9838', '9844'
, '9846', '9847', '9852', '9855', '9859', '9862', '9865', '9866', '9867', '9869', '9870', '9871', '9872'
, '9885', '9887', '9888', '9900', '9904', '9906', '9907', '9908', '9909', '9916', '9918', '9924', '9925'
, '9927', '9928', '9933', '9934', '9938', '9940', '9942', '9944', '9946' ) */


SELECT * 
FROM [dbo].[arr_walk_report_3]
WHERE baseSubscriptionId IN 
('6366','3525','3771','845','1517', 60, 57,'5408','580','3369','1544','1153','834','4901','563','1349','352','4206','3491','837','3393','3471','4015','3491','167','217')
ORDER BY 1,2, baseIdOrdr

SELECT * FROM [xrf_index]  --[dim_subscription_details] 
WHERE baseSubscriptionId IN 
('6366','3525','3771','845','1517', 60, 57,'5408','580','3369','1544','1153','834','4901','563','1349','352','4206','3491','837','3393','3471','4015','3491','167','217')

SELECT * FROM [xrf_index]  --[dim_subscription_details] 
WHERE baseSubscriptionId = 834

SELECT * FROM [fact_arr]  --[dim_subscription_details] 
WHERE baseSubscriptionId = 834

SELECT *
FROM [dim_subscription]  --[dim_subscription_details] 
WHERE [baseSubscriptionId] = 834

SELECT *
FROM [dim_subscription_details]  --[dim_subscription_details] 
WHERE [baseSubscriptionId] = 834




--8617
--8689

SELECT distinct * --CONVERT(int,[dim_subscription].[baseSubscriptionId]), CONVERT(int,[dim_subscription].[subscriptionId]) 
FROM [dim_subscription]  WITH (NOLOCK) 
JOIN [dim_subscription_details] ON [dim_subscription_details].[subscriptionId] = [dim_subscription].[subscriptionId] AND [dim_subscription_details].[isCreditMemo] = [dim_subscription].[isCreditMemo]
LEFT JOIN [fact_arr] ON [dim_subscription].[subscriptionId] = [fact_arr].[subscriptionId] AND  [dim_subscription].[isCreditMemo] = [fact_arr].[isCreditMemo]
WHERE [dim_subscription].[baseSubscriptionId] = 834


WHERE [dim_subscription].[baseSubscriptionId] IN 
( 57, 60, 167, 217, 352, 563, 580, 834, 837, 845, 1153, 1349, 1517, 1544, 3369, 3393, 3471, 3491, 3525, 3771, 4015, 4206, 4901, 5408, 6366 )

( 57, 60, 167, 217, 352, 563, 580, 834, 837, 845, 1153, 1349, 1517, 1544, 3369, 3393, 3471, 3491, 3525, 3771, 4015, 4206, 4901, 5408, 6366 ) 

LEFT JOIN [dim_invoice] ON [dim_invoice].[invoiceId] = [fact_arr].[invoiceId] AND [dim_invoice].[invoiceLine] = [fact_arr].[invoiceLine]
LEFT JOIN [dim_salesorder] ON [dim_salesorder].[salesOrderId] = [fact_arr].[salesOrderId] AND [dim_salesorder].[salesOrderLine] = [fact_arr].[salesOrderLine]
LEFT JOIN [dim_product] ON [dim_product].[itemId] = [fact_arr].[itemId]
LEFT JOIN [dim_salesorg] ON [dim_salesorg].[sourceId] = [fact_arr].[salesOrgId]
JOIN [dim_salesout] ON [dim_salesout].[salesOutId] = [fact_arr].[salesOutId]
JOIN [dim_customer] ON [dim_customer].[internalId] = [fact_arr].[billToCustomerId]

ORDER BY CONVERT(int,[dim_subscription].[baseSubscriptionId]), CONVERT(int,[dim_subscription].[subscriptionId])
