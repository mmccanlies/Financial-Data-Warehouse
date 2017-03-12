
SELECT * FROM (
SELECT 'xrf_index:                 ' AS 'Name', COUNT(*) AS 'Rows' FROM [xrf_index]                 UNION ALL
SELECT 'fact_arr:                  ', COUNT(*) FROM [fact_arr]                  UNION ALL
SELECT 'dim_salesorg:              ', COUNT(*) FROM [dim_salesorg]              UNION ALL
SELECT 'dim_customer:              ', COUNT(*) FROM [dim_customer]              UNION ALL
SELECT 'dim_invoice:               ', COUNT(*) FROM [dim_invoice]               UNION ALL
SELECT 'dim_creditmemo:            ', COUNT(*) FROM [dim_creditmemo]            UNION ALL
SELECT 'dim_subscription:          ', COUNT(*) FROM [dim_subscription]          UNION ALL
SELECT 'dim_subscription_details:  ', COUNT(*) FROM [vw_subscription_sequence]  UNION ALL
SELECT 'dim_product:               ', COUNT(*) FROM [dim_product]               UNION ALL
SELECT 'dim_salesorder:            ', COUNT(*) FROM [dim_salesorder]            UNION ALL
SELECT 'dim_salesout:              ', COUNT(*) FROM [dim_salesout]              UNION ALL 
SELECT 'dim_calendar:              ', COUNT(*) FROM [dim_calendar]              UNION ALL
SELECT 'vw_subscription_sequence:  ', COUNT(*) FROM [vw_subscription_sequence]  UNION ALL
SELECT 'vw_subscription_update:    ', COUNT(*) FROM [vw_subscription_update]
) y
ORDER BY y.[Rows] DESC

SELECT 'xrf_index:                 ' AS 'Name', COUNT(DISTINCT subscriptionId) FROM xrf_index          UNION ALL
SELECT 'fact_arr:                  ', COUNT(DISTINCT subscriptionId) FROM fact_arr                     UNION ALL
SELECT 'dim_subscription:          ', COUNT(DISTINCT subscriptionId) FROM dim_subscription             UNION ALL
SELECT 'vw_subscription_update:    ', COUNT(DISTINCT subscriptionId) FROM vw_subscription_update       UNION ALL
SELECT 'dim_subscription_details:  ', COUNT(DISTINCT subscriptionId) FROM dim_subscription_details    UNION ALL
SELECT 'vw_subscription_sequence:  ', COUNT(DISTINCT sub2) FROM vw_subscription_sequence               UNION ALL
SELECT 'dim_creditmemo:            ', COUNT(DISTINCT subscriptionId) FROM dim_creditmemo               UNION ALL
SELECT 'dim_invoice:               ', COUNT(DISTINCT invoiceId) FROM dim_invoice                       UNION ALL
SELECT 'dim_salesorder:            ', COUNT(DISTINCT salesorderId) FROM dim_salesorder                 UNION ALL
SELECT 'dim_salesout:              ', COUNT(DISTINCT salesoutId) FROM [dim_salesout]  

SELECT 'dim_subscription:          ', COUNT(DISTINCT subscriptionId) FROM dim_subscription UNION ALL
SELECT 'dim_subscription:          ', COUNT(DISTINCT subscriptionId) FROM dim_subscription WHERE baseSubscriptionId = SubscriptionId   UNION ALL
SELECT 'dim_subscription:          ', COUNT(DISTINCT subscriptionId) FROM dim_subscription WHERE baseSubscriptionId != SubscriptionId   

SELECT subscriptionId, COUNT(*) 
FROM [dim_invoice]  
GROUP BY subscriptionId
HAVING COUNT(*) > 1
WHERE subscriptionId = -1


UPDATE utl_batch_order SET
isActive = 0
WHERE runOrderID IN (1020, 1030, 1100)



--TRUNCATE TABLE utl_messages

SELECT 
  CONVERT(date,CONVERT(datetime2,msgTimeStamp,120),100)
, CONVERT(VARCHAR,CONVERT(datetime,CONVERT(datetime2,msgTimeStamp,120),100),114)
, [message]
, source
FROM [utl_messages] ORDER BY msgTimeStamp

23:19:16:353

SELECT 
  CONVERT(date,CONVERT(datetime2,msgTimeStamp,120),100)  AS 'RunDate'
, DATEDIFF(MS, MIN(CONVERT(datetime,CONVERT(datetime2,msgTimeStamp,120),100))
, MAX(CONVERT(datetime,CONVERT(datetime2,msgTimeStamp,120),100)))/1000.0 AS 'RunTime'
, MIN(CONVERT(VARCHAR,CONVERT(datetime,CONVERT(datetime2,msgTimeStamp,120),100),114)) AS 'StartTime'
, MAX(CONVERT(VARCHAR,CONVERT(datetime,CONVERT(datetime2,msgTimeStamp,120),100),114)) AS 'EndTime'
, source
FROM [utl_messages]
WHERE ( [message] LIKE 'Start%' OR [message] LIKE 'Exit%' )
GROUP BY CONVERT(date,CONVERT(datetime2,msgTimeStamp,120),100), source
ORDER BY MIN(CONVERT(VARCHAR,CONVERT(datetime,CONVERT(datetime2,msgTimeStamp,120),100),114))

commit
ROLLBACK



sp_dim_customer 1, 0
--    xrf_index, ns_customer

sp_dim_product 1,0
--    xrf_index, ns_nonInventorySaleItem

sp_xrf_index 1,0
--    ns_custom_subscription, ns_salesorder, ns_salesorder_itemlist, ns_customer, ns_invoice, ns_invoice_itemlist

sp_dim_invoice 1,0
--    xrf_index, ns_custom_subscription, ns_salesorder, ns_salesorder_itemlist, ns_invoice, ns_invoice_itemlist

sp_dim_subscription 1,0
--    dim_invoice, dim_customer, ns_custom_subscription, ns_creditmemo, ns_creditmemo_ItemList, 
--    xrf_index, vw_subscription_update, vw_subscription_sequence_dim, customSubscriptionTierDefault, 

sp_dim_creditmemo 1,0
--    dim_subscription, ns_creditmemo, ns_creditmemo_ItemList

sp_dim_salesorder 1,0
--    xrf_index, dim_subscription, dim_salesorder, ns_salesOrder, ns_salesOrder_itemList 

sp_fact_arr 1,0
--    xrf_index, dim_subscription, dim_creditmemo, vw_subscription_sequence, vw_subscription_list, ns_custom_subscription 


sp_dim_subscription_details 1,0
--    dim_subscription, fact_arr, dim_salesorder, ns_custom_subscription

sp_dim_salesout 1,0
--    salesout_dim, xrf_index, ns_custom_sales_out



SELECT COUNT(*) FROM vw_test_grp
SELECT * FROM vw_test_grp

SELECT customerId,  COUNT(*) FROM dim_customer
GROUP BY customerId
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC


SELECT COUNT(*), '  customSubscriptionTierDefault' FROM [dbo].[customSubscriptionTierDefault]
UNION ALL 
SELECT COUNT(*), '  dim_calendar' FROM [dbo].[dim_calendar]
UNION ALL 
SELECT COUNT(*), '  xxls_region_dtls' FROM [dbo].[xxls_region_dtls]
UNION ALL 
SELECT COUNT(*), '  xrf_legacy_reseller' FROM [dbo].[xrf_legacy_reseller]
UNION ALL 
SELECT COUNT(*), '  utl_stored_procedure_list' FROM [dbo].[utl_stored_procedure_list]
UNION ALL 
SELECT COUNT(*), '  utl_messages' FROM [dbo].[utl_messages]
UNION ALL 
SELECT COUNT(*), '  dim_salesorg' FROM dim_salesorg
UNION ALL 
SELECT COUNT(*), '  dim_product' FROM dim_product
UNION ALL 
SELECT COUNT(*), '  dim_customer' FROM dim_customer
UNION ALL 
SELECT COUNT(*), '  xrf_index' FROM xrf_index
UNION ALL 
SELECT COUNT(*), '  fact_arr' FROM fact_arr
UNION ALL 
SELECT COUNT(*), '  dim_invoice' FROM dim_invoice
UNION ALL 
SELECT COUNT(*), '  dim_subscription' FROM dim_subscription
UNION ALL 
SELECT COUNT(*), '  dim_subscription_details' FROM dim_subscription_details
UNION ALL 
SELECT COUNT(*), '  dim_creditmemo' FROM dim_creditmemo
UNION ALL 
SELECT COUNT(*), '  dim_salesorder' FROM dim_salesorder
UNION ALL 
SELECT COUNT(*), '  dim_salesout' FROM dim_salesout
 



rollback

TRUNCATE TABLE utl_messages

SELECT * FROM [dbo].[utl_messages] ORDER BY msgTimeStamp

exec sp_ctrl_main ;


EXEC sp_xrf_index 1, 0

SELECT * FROM dim_subscription_details
ORDER BY 1,2


SELECT COUNT(*) FROM [arr_walk_report_3] WITH (NOLOCK)

commit
