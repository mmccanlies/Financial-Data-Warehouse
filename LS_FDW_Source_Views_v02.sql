--GO
/***************************************************************************************************************************
**                                        CREATE INDEXES ON TOP OF SOURCE TABLES
** by: mmccanlies       03/16/2017
** 
***************************************************************************************************************************/
GO
USE [fdw_raw]
GO

--IF EXISTS ( SELECT COUNT(*) FROM [sys].[indexes] WHERE name = 'NCI_ns_salesOrder_line' )
--    DROP INDEX [NCI_ns_salesOrder_line] ON [fdw_raw].[ns_salesOrde] 
--GO
--CREATE NONCLUSTERED INDEX NCI_ns_salesOrderItemList_line ON [ns_salesOrder_ItemList] ( [internalId], [line], [item-internalId] )
GO
IF EXISTS ( SELECT COUNT(*) FROM [sys].[indexes] WHERE name = 'NCI_ns_salesOrderItemList_line' )
    DROP INDEX [NCI_ns_salesOrderItemList_line] ON [fdw_raw].[ns_salesOrder_itemList]
GO
CREATE NONCLUSTERED INDEX NCI_vw_salesOrderItemList_line ON [ns_salesOrder_ItemList] ( [internalId], [customFieldList-custcol_line_id], [item-internalId] )
GO
IF EXISTS ( SELECT COUNT(*) FROM [sys].[indexes] WHERE name = 'NCI_vw_invoiceItemList_line' )
    DROP INDEX [NCI_ns_invoiceItemList_line] ON [fdw_raw].[ns_invoice_ItemList]
GO
CREATE NONCLUSTERED INDEX NCI_vw_invoiceItemList_line ON [ns_invoice_ItemList] ( [internalId], [customFieldList-custcol_line_id], [item-internalId] )
INCLUDE ( [internalId] )
GO
IF EXISTS ( SELECT COUNT(*) FROM [sys].[indexes] WHERE name = 'NCI_vw_invoice_createdFromId' )
    DROP INDEX [NCI_ns_invoice] ON [fdw_raw].[ns_invoice] 
GO
-- This index won't work because createdFrom-internalId contains NULLs
CREATE NONCLUSTERED INDEX NCI_ns_invoice_createdFromId ON [ns_invoice] ( [createdFrom-internalId], [tranId] )
INCLUDE ( [internalId] )

SELECT [internalId], [customFieldList-custcol_line_id], [item-internalId]
FROM ns_salesOrder_itemList

USE [sandbox_mike]
/***************************************************************************************************************************
**                                        BUILD VIEWS ON TOP OF SOURCE TABLES
** by: mmccanlies       03/07/2017
** 
***************************************************************************************************************************/
GO
IF object_id('vw_custom_subscription', 'v') IS NOT NULL
DROP VIEW vw_custom_subscription 
GO
CREATE VIEW vw_custom_subscription 
AS
SELECT 
  [internalId]
, [customRecordId]
, [customFieldList-custrecord_base_subscription]
, [customFieldList-custrecord_base_subscription_flag]
, [customFieldList-custrecord_credit_memo]
, [customFieldList-custrecord_reference_type]
, [customFieldList-custrecord_number_of_seats_2]
, [customFieldList-custrecord_number_of_seats]
, [customFieldList-custrecord_license_type]
, [customFieldList-custrecord_amplify_hours]
, [customFieldList-custrecord_recording_hours]
, [customFieldList-custrecord_sub_recording_hrs_included]
, [customFieldList-custrecord_total_recording_hours]
, [customFieldList-custrecord_vmrs]
, [customFieldList-custrecord_subscription_cloud_features]
, [customFieldList-custrecord_subscription_start_date]
, [customFieldList-custrecord_subscription_end_date]
, [customFieldList-custrecord_subscription_cost]
, [customFieldList-custrecord_standard_discount_pct]
, [customFieldList-custrecord_orn_discount_pct]
, [customFieldList-custrecord_nsd_discount_pct]
, [customFieldList-custrecord_nsd_id]
, [customFieldList-custrecord_subscription_tier]
, [customFieldList-custrecord_subscription_item_no]
, [customFieldList-custrecord_subscription_item]
, [customFieldList-custrecord_item_type]
, [customFieldList-custrecord_subscription_bill_to_customer]
, [customFieldList-custrecord_subscription_end_customer]
, [customFieldList-custrecord_subscription_transaction]
, [customFieldList-custrecord_subscription_transaction_line]
, [customFieldList-custrecord_subscription_status]
, [customFieldList-custrecord_sf_quote_id]
, [customFieldList-custrecord_current_so_text]
, [DBcreated]
, [DBlastmodified]
FROM [fdw_raw].[fdw_raw].[ns_custom_subscription]
/*
WHERE [customFieldList-custrecord_base_subscription] IN 
( '131', '359', '663', '738', '757', '761', '780', '788', '791', '805', '840', '867', '870', '871', '902', '907'
, '914', '920', '925', '944', '962', '1047', '1140', '1144', '1348', '1511', '3702', '4334', '4538', '4600'
, '4698', '4719', '4833', '4880', '4883', '4939', '4941', '4985', '4987', '4993', '5042', '5043', '5048'
, '5050', '5087', '5094', '5098', '5119', '5122', '5129', '5131', '5159', '5163', '5167', '5189', '5219'
, '5222', '5238', '5286', '5298', '5344', '5374', '5389', '5393', '5400', '5420', '5444', '5512', '5578'
, '5591', '5653', '5657', '5874', '6042', '6300', '6648', '6936', '7583', '7597', '8113', '8141', '9446'
, '9472', '9790', '9798', '9799', '9807', '9815', '9816', '9825', '9828', '9833', '9836', '9838', '9844'
, '9846', '9847', '9852', '9855', '9859', '9862', '9865', '9866', '9867', '9869', '9870', '9871', '9872'
, '9885', '9887', '9888', '9900', '9904', '9906', '9907', '9908', '9909', '9916', '9918', '9924', '9925'
, '9927', '9928', '9933', '9934', '9938', '9940', '9942', '9944', '9946' )
*/
GO


GO
IF object_id('vw_salesOrder', 'v') IS NOT NULL
DROP VIEW [vw_salesOrder]
GO
CREATE VIEW [vw_salesOrder]
AS
SELECT 
  [ns_salesOrder].[internalId]
, [ns_salesOrder].[tranId]
, [ns_salesOrder].[tranDate]
, [ns_salesOrder].[customFieldList-custbody_order_date]
, [ns_salesOrder].[otherRefNum]
, [ns_salesOrder].[customFieldList-custbody_transaction_case]
, [ns_salesOrder].[customFieldList-custbody_om_salesperson]
, [ns_salesorder].[subsidiary-name]
, [ns_salesorder].[customFieldList-custbody_bill_customer]
, [ns_salesorder].[entity-internalId]
, [ns_salesorder].[entity-name]
, [ns_salesOrder].[total]
, [ns_salesorder].[lastModifiedDate]
, [DBlastmodified]
, [DBcreated]
FROM [fdw_raw].[fdw_raw].[ns_salesOrder]


GO
IF object_id('vw_salesOrder_itemList', 'v') IS NOT NULL
DROP VIEW [vw_salesOrder_itemList]
GO
CREATE VIEW [vw_salesOrder_itemList]
AS
SELECT 
  [ns_salesOrder_itemlist].[internalId]
, [ns_salesOrder_itemlist].[line]
, [ns_salesOrder_itemList].[item-name]
, [ns_salesOrder_itemList].[item-internalId]
, [ns_salesOrder_ItemList].[class-name]
, [ns_salesOrder_ItemList].[class-internalId]
, [ns_salesOrder_itemList].[location-name]
, [ns_salesOrder_itemList].[description]
, [ns_salesOrder_itemList].[customFieldList-custcol_service_start_date]
, [ns_salesOrder_itemList].[customFieldList-custcol_service_end_date]
, [ns_salesOrder_itemList].[units-name]
, [ns_salesOrder_itemList].[quantity]
, [ns_salesOrder_itemList].[amount]
, [ns_salesOrder_itemList].[price-name]
, [ns_salesOrder_itemList].[customFieldList-custcol_request_date]
, [ns_salesOrder_itemlist].[customFieldList-custcol_term]
, [ns_salesOrder_ItemList].[customFieldList-custcol_custlistprice]
, [ns_salesOrder_itemList].[customFieldList-custcolcustcolcustcol_custactdiscount]
, [ns_salesOrder_itemList].[quantityBilled]
, [ns_salesOrder_itemList].[quantityFulfilled]
, [ns_salesOrder_itemList].[customFieldList-custcol_service_renewal]
, [ns_salesOrder_itemList].[department-name]
, [ns_salesOrder_itemList].[revRecStartDate]
, [ns_salesOrder_itemList].[revRecEndDate]
, [ns_salesOrder_itemList].[revRecTermInMonths]
, [ns_salesOrder_itemlist].[customFieldList-custcol_service_ref_type]
, [ns_salesOrder_itemList].[customFieldList-custcol_install_base]
, [ns_salesOrder_itemlist].[customFieldList-custcol_ib_base_description]
, [ns_salesOrder_itemlist].[customFieldList-custcol_serial]
, [ns_salesOrder_itemlist].[customFieldList-custcol_rma_container_item]
, [ns_salesOrder_itemlist].[customFieldList-custcol_rma_price]
, [ns_salesOrder_itemList].[isClosed]
, [ns_salesOrder_itemlist].[customFieldList-custcol_line_id]
, [DBcreated]
, [DBlastmodified]
FROM [fdw_raw].[fdw_raw].[ns_salesOrder_itemList]



GO
IF object_id('vw_creditMemo', 'v') IS NOT NULL
DROP VIEW [vw_creditMemo]
GO
CREATE VIEW [dbo].[vw_creditMemo]
AS
SELECT
  [ns_creditmemo].[internalId]
, [ns_creditmemo].[tranId]
, [ns_creditmemo].[tranDate]
, [ns_creditMemo].[salesEffectiveDate]
, [ns_creditMemo].[customFieldList-custbody_order_date]
, [ns_creditMemo].[postingPeriod-name]
, [ns_creditmemo].[createdFrom-internalId]
, [ns_creditmemo].[createdFrom-name]
, [ns_creditMemo].[customFieldList-custbody_rma_sales_order]
, [ns_creditMemo].[customFieldList-custbody_receipt]
, [ns_creditMemo].[entity-name]
, [ns_creditMemo].[recognizedRevenue]
, [ns_creditMemo].[applied]
, [ns_creditMemo].[unapplied]
, [ns_creditMemo].[total]
, [ns_creditMemo].[lastModifiedDate]
, [ns_creditMemo].[DBcreated]
, [ns_creditMemo].[DBlastmodified]
FROM [fdw_raw].[fdw_raw].[ns_creditMemo]


GO
IF object_id('vw_creditMemo_itemList', 'v') IS NOT NULL
DROP VIEW [vw_creditMemo_itemList]
GO
CREATE VIEW [vw_creditMemo_itemList]
AS
SELECT
  [ns_creditmemo_ItemList].[internalId]
, [ns_creditmemo_ItemList].[line]
, [ns_creditmemo_ItemList].[customFieldList-custcol_line_id]
, [ns_creditmemo_ItemList].index1
, [ns_creditmemo_ItemList].[class-internalId]
, [ns_creditmemo_ItemList].[class-name]
, [ns_creditmemo_ItemList].[item-internalId]
, [ns_creditmemo_ItemList].[item-name]
, [ns_creditmemo_ItemList].[description]
, [ns_creditmemo_ItemList].[price-name]
, [ns_creditmemo_ItemList].[quantity]
, [ns_creditmemo_ItemList].[units-name]
, [ns_creditmemo_ItemList].[rate]
, [ns_creditmemo_ItemList].[amount]
, [ns_creditmemo_ItemList].[customFieldList-custcol_custlistprice]
, [ns_creditmemo_ItemList].[customFieldList-custcolcustcolcustcol_custactdiscount]
, [ns_creditmemo_ItemList].[customFieldList-custcol_discount_comment]
, [ns_creditmemo_ItemList].[customFieldList-custcol_cost]
, [ns_creditmemo_ItemList].[customFieldList-custcol_ava_incomeaccount]
, [ns_creditmemo_ItemList].[department-name]
, [ns_creditmemo_ItemList].[location-name]
, [ns_creditmemo_ItemList].[customFieldList-custcol_install_base]
, [ns_creditmemo_ItemList].[customFieldList-custcol_install_base_item]
, [ns_creditmemo_ItemList].[customFieldList-custcol_sales_rep]
, [ns_creditmemo_ItemList].[DBcreated]
, [ns_creditmemo_ItemList].[DBlastmodified]
FROM [fdw_raw].[fdw_raw].[ns_creditMemo_itemList]


GO
IF object_id('vw_invoice', 'v') IS NOT NULL
DROP VIEW [vw_invoice]
GO
CREATE VIEW [vw_invoice]
AS
SELECT
  [ns_invoice].[internalId]
, [ns_invoice].[tranId]
, [ns_invoice].[tranDate]
, [ns_invoice].[customFieldList-custbody_bill_customer]
, [ns_invoice].[entity-name]
, [ns_invoice].[billAddress] 
, [ns_invoice].[customFieldList-custbody_order_date]
, [ns_invoice].[total]
, [ns_invoice].[createdFrom-internalId]
, [ns_invoice].[otherRefNum]
, [DBcreated]
, [DBlastmodified]
FROM [fdw_raw].[fdw_raw].[ns_invoice]


GO
IF object_id('vw_invoice_itemList', 'v') IS NOT NULL
DROP VIEW [vw_invoice_itemList]
GO
CREATE VIEW [vw_invoice_itemList]
AS
SELECT
  [ns_invoice_itemlist].[internalId]
, [ns_invoice_itemlist].[customFieldList-custcol_line_id]
, [ns_invoice_itemlist].[orderLine]
, [ns_invoice_itemList].[customFieldList-custcol_term]
, [ns_invoice_itemList].[customFieldList-custcol_service_start_date]
, [ns_invoice_itemList].[customFieldList-custcol_service_end_date]
, [ns_invoice_itemlist].[class-name]    
, [ns_invoice_itemlist].[item-name]     
, [ns_invoice_itemlist].[description]   
, [ns_invoice_ItemList].[location-name] 
, [ns_invoice_ItemList].[rate]
, [ns_invoice_ItemList].[quantity]
, [ns_invoice_itemlist].[units-name]
, [ns_invoice_itemlist].[price-name]
, [ns_invoice_itemlist].[customFieldList-custcol_ava_incomeaccount]
, [ns_invoice_itemlist].[revRecStartDate]
, [ns_invoice_itemlist].[revRecEndDate]
, [ns_invoice_itemlist].[revRecSchedule-name]
, [ns_invoice_itemlist].[customFieldList-custcol_subscription]
, [ns_invoice_itemlist].[customFieldList-custcol_auto_sales_out]
, [ns_invoice_ItemList].[item-internalId]
, [DBcreated]
, [DBlastmodified]
FROM [fdw_raw].[fdw_raw].[ns_invoice_itemList]


GO
IF object_id('vw_custom_sales_out', 'v') IS NOT NULL
DROP VIEW [vw_custom_sales_out]
GO
CREATE VIEW [vw_custom_sales_out]
AS
SELECT
  [ns_custom_sales_out].[internalId]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_original_line_num]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_date]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_purchasedate]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_install_base]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_serial_number]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_status]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_item]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_quantity]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_amount]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_list_price]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_sold_thru_reseller]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_strategic_reseller]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_reseller_po_number]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_customer_number]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_company_name]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_address_1]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_address_2]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_address_3]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_address_4]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_city]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_state]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_zip]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_province]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_county]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_country]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_email]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_phone]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_sf_partner_number]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_sales_region]
, [ns_custom_sales_out].[customFieldList-custrecord_sales_out_original_trans]
, [ns_custom_sales_out].[customFieldList-custrecord_original_sales_order]
, [ns_custom_sales_out].[externalId]
, [DBcreated]
, [DBlastmodified]
FROM [fdw_raw].[fdw_raw].[ns_custom_sales_out]


GO
IF object_id('vw_customer', 'v') IS NOT NULL
DROP VIEW [vw_customer]
GO
CREATE VIEW [vw_customer]
AS
SELECT
  internalId
, [billingInternalId]
, [entityId]
, [companyName]
, [defaultAddress]
, [emailDomain]
, [billingAddressee]
, [billingAddr1]
, [billingAddr2]
, [billingAddr3]
, [billingCity]
, [billingState]
, [billingZip]
, [billingCountry]
, [billingAddrText]
, [billingLabel]
, [category-internalId]
, [category-name]
, [subsidiary-internalId]
, [subsidiary-name]
, [phone]
, [fax]
, [email]
, [terms-internalId]
, [terms-name]
, [currency-name]
, [stage]
, [entityStatus-name]
, [externalId]
, [lastModifiedDate]
FROM [fdw_raw].[fdw_raw].[ns_customer]


GO
IF object_id('vw_nonInventorySaleItem', 'v') IS NOT NULL
DROP VIEW [vw_nonInventorySaleItem]
GO
CREATE VIEW [vw_nonInventorySaleItem]
AS
SELECT
  [class-internalId]
, [internalId]
, [class-name]
, [itemId]
, [salesDescription]
, [customFieldList-custitem_term]
, [customFieldList-custitem_number_of_seats]
, [customFieldList-custitem_recording_hours]
, [customFieldList-custitem_vmrs_included]  
, [saleUnit-name]
, [externalId]
, [createdDate]
, [lastModifiedDate]
FROM [fdw_raw].[fdw_raw].[ns_nonInventorySaleItem]


GO
IF object_id('vw_returnAuthorization', 'v') IS NOT NULL
DROP VIEW [vw_returnAuthorization]
GO
CREATE VIEW [vw_returnAuthorization]
AS
SELECT
  [internalId]
, [tranDate]
, [tranId]
, [createdFrom-internalId]
, [createdFrom-name]
, [class-internalId]
, [class-externalId]
, [class-type]
, [class-name]
, [subTotal]
, [discountTotal]
, [total]
, [revenueStatus]
, [status]
, [customFieldList-custbody_ava_customercompanyname]
, [customFieldList-custbody_bill_customer]
, [billingAddress-addrText]
, [customFieldList-custbody_end_customer]
, [customFieldList-custbody_end_customer_address_text]
, [customFieldList-custbody_receipt]
, [otherRefNum]
, [entity-internalId]
, [entity-name]
, [memo]
, [customFieldList-custbody_custom_return_reason]
, [customFieldList-custbody_om_salesperson]
, [customFieldList-custbody_rma_sales_order]
, [createdDate]
, [lastModifiedDate]
FROM [fdw_raw].[fdw_raw].[ns_returnAuthorization]
GO


IF object_id('vw_returnAuthorization_itemList', 'v') IS NOT NULL
DROP VIEW [vw_returnAuthorization_itemList]
GO
CREATE VIEW [vw_returnAuthorization_itemList]
AS
SELECT
  [internalId]
, [line]
, [customFieldList-custcol_line_id]
, [description]
, [quantity]
, [quantityReceived]
, [quantityBilled]
, [units-name]
, [price-name]
, [rate]
, [amount]
, [class-internalId]
, [class-name]
, [customFieldList-custcol_service_renewal]
, [customFieldList-custcol_custlistprice]
, [customFieldList-custcol_rma_price]
, [customFieldList-custcolcustcolcustcol_custactdiscount]
, [DBcreated]
, [DBlastModified]
FROM [fdw_raw].[fdw_raw].[ns_returnAuthorization_itemList]



IF object_id('vw_custom_defaultsalesperson', 'v') IS NOT NULL
DROP VIEW [vw_custom_defaultsalesperson]
GO
CREATE VIEW [ns_custom_defaultSalesperson]
AS
SELECT *
FROM [fdw_raw].[fdw_raw].[ns_custom_defaultSalesperson]



/**************************************************************************************************************************
**                                          END OF SCRIPT LS_FDW_SOURCE_VIEW                                             **
***************************************************************************************************************************/
