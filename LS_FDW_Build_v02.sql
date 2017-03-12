--USE [sandbox_mike]
--GO
/***************************************************************************************************************************
**                                          xrf_index
** by: mmccanlies       01/24/2017
** Create xrf_index
***************************************************************************************************************************/
--IF object_id('xrf_index', 'U') IS NOT NULL
--DROP TABLE [xrf_index] 
GO
DROP TABLE [xrf_index]
GO
CREATE TABLE [xrf_index] (
    [xrfIndexId] [bigint] IDENTITY(1,1) NOT NULL,
	[baseSubscriptionId] [int] NULL,
	[subscriptionId] [int] NULL,
    [creditMemoId] [int] NULL,
    [creditMemoNo] [nvarchar](50) NULL,
	[isBase] [int] NULL,
	[salesOrderId] [int] NULL,
	[salesOrderLine] [int] NULL,
	[classId] [int] NULL,
	[itemId] [int] NULL,
	[invoiceId] [int] NULL,
	[invoiceLine] [int] NULL,
	[salesOutId] [int] NULL,
	[salesOutLine] [int] NULL,
  	[invItemId] [int] NULL,
    [soItemid] [int] NULL,
	[salesOrgId] [nvarchar](50) NULL,
	[billCustomerId] [int] NULL,
	[endCustomerId] [int] NULL,
	[resellerId] [int] NULL
)
GO
CREATE CLUSTERED INDEX CLI_Xrf_Index_Id_Int ON [xrf_index] (xrfIndexId) 
GO


/***************************************************************************************************************************
**                                          customSubscriptionTierDefault
** by: mmccanlies       02/13/2017
** Create customSubscriptionTierDefault
***************************************************************************************************************************/
--IF object_id('customSubscriptionTierDefault', 'U') IS NOT NULL
-- DROP TABLE [customSubscriptionTierDefault]
GO
CREATE TABLE [customSubscriptionTierDefault] (
  [subscriptionTierId]    [int] NOT NULL
, [internalId]    [int] NOT NULL
, [tierLvl]    [int] NULL
, [tierName]    [nvarchar](50) NULL 
, [ssoIncl]     [bit] NULL 
, [lyncIncl]     [bit] NULL 
, [maxUsersSet]    [int] NULL 
, [maxUsersSetUnits]   [nvarchar](50) NULL
, [maxMtgParticipants]    [int] NULL 
, [maxVMRs]    [int] NULL 
, [maxVMRsUnits]   [nvarchar](50) NULL
, [endPointsAsUsers]    [bit] NULL 
, [recordingEnabled]    [bit] NULL 
, [recordingHrsIncl]    [bit] NULL 
, [BackgroundSet]    [bit] NULL 
)


/***************************************************************************************************************************
**                                          xrf_lookup
** by: mmccanlies       03/07/2017
** Create xrf_lookup_xrf table
***************************************************************************************************************************/
--IF object_id('xrf_lookup', 'U') IS NOT NULL
--DROP TABLE [xrf_lookup] 
GO
CREATE TABLE [xrf_lookup] (
lookupId         bigint identity(1,1),
sourceRefId      varchar(50),
refType          varchar(20),
description1     varchar(100),
description2     varchar(100),
)


/***************************************************************************************************************************
**                                          fact_arr
** by: mmccanlies       02/05/2017
** Create fact_arr
***************************************************************************************************************************/
--IF object_id('fact_arr', 'U') IS NOT NULL
--DROP TABLE [fact_arr]
GO
CREATE TABLE [fact_arr](
    [xrfIndexId] [bigint] NOT NULL,
	[baseSubscriptionId] [int] NULL,
	[subscriptionId] [int] NOT NULL,
	[salesOrderId] [int] NOT NULL,
	[salesOrderLine] [int] NULL,
	[invoiceId] [int]  NULL,
	[invoiceLine] [int] NULL,
	[invItemId] [int] NULL,
	[soItemId] [int] NULL,
	[salesOrgId] [int] NOT NULL,
	[salesOutId] [int] NULL,
	[salesOutLine] [int] NULL,
	[classId] [int] NULL,
	[itemId] [int] NULL,
	[billToCustomerId] [int] NULL,
	[endCustomerId] [int] NULL,
	[resellerId] [int] NULL,
	[startDateId] [date] NULL,
	[endDateId] [date] NULL,
	[invoiceAmt] [money] NULL,
	[invoiceAmtPerYr] [money] NULL,
	[arrAmtPerYr] [money] NULL,
	[creditAmt] [money] NULL,
	[seats] [int] NULL,
	[amplifyHrs] [int] NULL,
	[extremeHrs] [int] NULL,
	[vmrs] [int] NULL,
	[recordingHrs] [int] NULL,
	[totalSeats] [int] NULL,
	[totalAmplifyHrs] [int] NULL,
	[totalVmrs] [int] NULL,
	[totalRecordingHrs] [int] NULL,
    [cumARRAmtPerYr] [money] NULL,
	[arrAmtChg] [int] NULL,
	[tierChg] [int] NULL,
	[seatsChg] [int] NULL,
	[termDaysChg] [int] NULL,
	[vmrsChg] [int] NULL,
	[isNew] [bit] NULL,
	[isRenewal] [bit] NULL,
	[isLateRenew] [bit] NULL,
	[renewGapDays] [bit] NULL,
	[isCreditMemo] [bit] NULL,
	[isAddSeats] [bit] NULL,
	[isFeature] [bit] NULL,
	[isUpDngrade] [bit] NULL,
	[isExpansion] [bit] NULL,
	[isChurn] [bit] NULL
) 
GO
CREATE NONCLUSTERED INDEX NCL_Fact_ARR_XrfIndexId ON [xrf_index] (xrfIndexId) 
GO


/***************************************************************************************************************************
**                                          dim_calendar
** by: mmccanlies       02/09/2017
** Create/load dim_calendar
***************************************************************************************************************************/
--IF object_id('dim_calendar', 'U') IS NOT NULL
--DROP TABLE [dim_calendar]
GO
CREATE TABLE [dim_calendar] (
	[dateId] [int] NULL,
	[date] [datetime] NOT NULL,
	[calDayOfYear] [int] NULL,
	[calWk] [int] NULL,
	[calMo] [int] NULL,
	[calQtr] [int] NULL,
	[calYr] [int] NULL,
	[calYrMoStr] [nvarchar](6) NULL,
	[calYrQtrStr] [nvarchar](34) NULL,
	[calYearMo] [int] NULL,
	[cwFirstDay] [int] NULL,
	[cmFirstDay] [int] NULL,
	[cmLastDay] [int] NULL,
	[cqFirstDay] [int] NULL,
	[cqLastDay] [int] NULL,
	[cyFirstDay] [int] NULL,
	[cyLastDay] [int] NULL,
	[fiscWk] [int] NULL,
	[fiscMo] [int] NULL,
	[fiscQtr] [int] NULL,
	[fiscYr] [int] NULL,
	[fiscYrMoStr] [nvarchar](6) NULL,
	[fiscYrQtrStr] [nvarchar](34) NULL,
	[fiscYearMo] [int] NULL,
	[fmFirstDay] [int] NULL,
	[fmLastDay] [int] NULL,
	[fqFirstDay] [int] NULL,
	[fqLastDay] [int] NULL,
	[fyFirstDay] [int] NULL,
	[fyLastDay] [int] NULL
) 
GO
CREATE NONCLUSTERED INDEX NCL_Dim_Calendar_DateId ON [dim_calendar] (dateId) INCLUDE (date)
GO



/***************************************************************************************************************************
**                                          dim_creditmemo
** by: mmccanlies       02/09/2017
** Create/load dim_creditmemo
***************************************************************************************************************************/
--IF object_id('dim_creditmemo', 'U') IS NOT NULL
--DROP TABLE [dim_creditmemo]
GO
CREATE TABLE [dim_creditmemo] (
    [xrfIndexId] [bigint] NOT NULL,
	[creditMemoId] [nvarchar](50) NOT NULL,
	[creditMemoLine] [int] NULL,
	[creditMemoNo] [nvarchar](50) NULL,
	[returnAuthId] [int] NULL,
	[rmaId] [nvarchar](50) NULL,
	[rmaDescr] [nvarchar](50) NULL,
	[rmaText] [nvarchar](50) NULL,
	[cmSalesOrderId] [nvarchar](50) NULL,
	[cmSource] [nvarchar](50) NULL,
	[sourceId] [nvarchar](50) NULL,
	[productClass] [nvarchar](100) NULL,
	[cmItemId] [nvarchar](50) NULL,
	[cmSkuNo] [nvarchar](50) NULL,
	[productFamilyPL] [nvarchar](150) NULL,
	[priceName] [nvarchar](50) NULL,
	[qty] [float] NULL,
	[units] [nvarchar](50) NULL,
	[rate] [money] NULL,
	[amt] [money] NULL,
	[incomeAcct] [nvarchar](50) NULL,
	[departmentName] [nvarchar](50) NULL,
	[locName] [nvarchar](50) NULL,
	[cmDate] [datetime] NULL,
	[customerPONo] [nvarchar](50) NULL,
	[baseSubscriptionId] [int] NULL,
	[subscriptionId] [int] NULL,
	[parentId] [int] NULL,
	[baseSubscription] [nvarchar](50) NULL,
	[subscription] [nvarchar](50) NULL,
    [parentSubscription] [nvarchar](50) NULL,
	[isBase] [int] NULL,
	[refType] [nvarchar](50) NULL,
	[refTypeId] [int] NULL,
	[refTypeTxt] [nvarchar](50) NULL,
    [tierId] [int] NULL,
    [tierLvl] [nvarchar](50) NULL,
    [tierName] [nvarchar](50) NULL,
	[seats] [int] NULL,
    [cumSeats] [int] NULL,
	[startDate] [datetime] NULL,
	[endDate] [datetime] NULL,
    [isCreditMemo] [bit] NULL,
	[invoiceAmt] [money] NULL,
	[salesOrderId] [int] NULL,
	[salesOrderLine] [int] NULL,
	[subscriptionStatusId] [int] NULL,
	[subscriptionStatus] [nvarchar](100) NULL
) 
GO
CREATE NONCLUSTERED INDEX NCL_Dim_CreditMemo_DateId ON [dim_creditmemo] (xrfIndexId)
GO


/***************************************************************************************************************************
** 02/01/2017							dim_customer
** by: mmccanlies       02/01/2017
** Load customer_dim
***************************************************************************************************************************/
--IF object_id('dim_customer', 'U') IS NOT NULL
--DROP TABLE [dim_customer]
GO
CREATE TABLE [dim_customer] (
  customerId		bigint identity(1,1)
, internalId		int
, alternateId		int
, recordType		nvarchar(50)
, entityId			nvarchar(100)
, companyName		nvarchar(100)
, defaultAddr		nvarchar(250)
, emailDomain		nvarchar(50)
, Addressee			nvarchar(100)
, addr1				nvarchar(150)
, addr2				nvarchar(150)
, addr3				nvarchar(100)
, city				nvarchar(50)
, [state]			nvarchar(50)
, zip				nvarchar(50)
, country			nvarchar(50)
, addrText			nvarchar(250)
, label				nvarchar(150)
, [status]			nvarchar(50)
, catInternalId		nvarchar(50)
, catName			nvarchar(50)
, subsInternalId	nvarchar(50)
, subsName			nvarchar(50)
, phone				nvarchar(50)
, fax				nvarchar(50)
, email				nvarchar(50)
, termsId			nvarchar(50)
, termsName			nvarchar(50)
, currency			nvarchar(50)
, stage				nvarchar(50)
, externalId		nvarchar(50)
, lastModDate		datetime
)
GO
CREATE NONCLUSTERED INDEX NCI_customer_dim_internalId ON [dim_customer] (internalId)
GO


/***************************************************************************************************************************
**                                          dim_invoice_dim
** by: mmccanlies       01/17/2017
** Create dim_invoice table from ns_invoice
**
***************************************************************************************************************************/
--IF object_id('dim_invoice', 'U') IS NOT NULL
--DROP TABLE [dim_invoice] 
GO
CREATE TABLE [dim_invoice](
    [xrfIndexId] [bigint] NOT NULL,
	[invoiceId] [int] NOT NULL,
	[invoiceLine] [int] NULL,
	[invoiceNo] [nvarchar](50) NULL,
	[invoiceDate] [datetime] NULL,
	[invCustColTerm] [int] NULL,
	[serviceStart] [datetime] NULL,
	[serviceEnd] [datetime] NULL,
	[serviceYrs] [int] NULL,
	[serviceMos] [int] NULL,
	[serviceDays] [int] NULL,
	[orderLine] [int] NULL,
	[invClassName] [nvarchar](100) NULL,
	[skuNo] [nvarchar](50) NULL,
	[invDescription] [nvarchar](100) NULL,
	[invLocName] [nvarchar](50) NULL,
	[invRate] [nvarchar](50) NOT NULL,
	[invQty] [numeric](37, 0) NULL,
	[invUnits] [nvarchar](50) NULL,
	[invPriceName] [nvarchar](50) NULL,
	[invIncAcct] [nvarchar](50) NULL,
	[BillToCustomerId] [nvarchar](50) NOT NULL,
	[BillToCustomerName] [nvarchar](100) NULL,
	[BillToCustomerAddress] [nvarchar](4000) NOT NULL,
	[billingDate] [datetime] NULL,
	[invAutoSalesOut] [nvarchar](50) NOT NULL,
	[invRevRecStartDate] [datetime] NULL,
	[invRevRecEndDate] [datetime] NULL,
	[invRevRecSchedName] [nvarchar](50) NULL,
	[subscriptionId] [int] NULL,
	[salesOrderId] [int] NULL,
	[invItemId] [int] NOT NULL
) 
GO
CREATE NONCLUSTERED INDEX NCL_Dim_Invoice_XrfIndexId ON [dim_invoice] (xrfIndexId)
GO


/***************************************************************************************************************************
**                                          dim_salesOrder
** by: mmccanlies       01/25/2017
** Load dim_salesOrder table
***************************************************************************************************************************/
--IF object_id('dim_salesorder', 'U') IS NOT NULL
--DROP TABLE [dim_salesorder]
GO
CREATE TABLE [dim_salesorder](
    [xrfIndexId] [bigint] NOT NULL,
	[salesOrderId] [int] NOT NULL,
	[salesOrderLine] [int] NOT NULL,
	[salesOrderNo] [nvarchar](50) NULL,
	[soTermYrs] [float] NULL,
	[soTermMos] [float] NULL,
	[soTermDays] [float] NULL,
	[soListPrice] [money] NULL,
	[soListPricePerYr] [money] NULL,
	[soListPricePerMo] [money] NULL,
	[soListPricePerDay] [money] NULL,
    [stdDiscount] [float] NULL,
    [stdDiscAmtYrs] [money] NULL,
    [stdDiscAmtMos] [money] NULL,
    [stdDiscAmtDays] [money] NULL,
    [ornDiscount] [float] NULL,
    [ornDiscAmtYrs] [money] NULL,
    [ornDiscAmtMos] [money] NULL,
    [ornDiscAmtDays] [money] NULL,
    [nsdDiscount] [float] NULL,
    [nsdDiscAmtYrs] [money] NULL,
    [nsdDiscAmtMos] [money] NULL,
    [nsdDiscAmtDays] [money] NULL,
	[soItemId] [int] NULL,
	[soSkuNo] [nvarchar](50) NULL,
	[soLocName] [nvarchar](50) NULL,
	[soDescription] [nvarchar](100) NULL,
	[soClassName] [nvarchar](100) NULL,
	[soClassId] [int] NULL,
	[soBookingDate] [datetime] NULL,
	[soCustomerPONo] [nvarchar](50) NULL,
	[soServiceStartDate] [datetime] NULL,
	[soServiceEndDate] [datetime] NULL,
	[soServiceYrs] [int] NULL,
	[soServiceMos] [int] NULL,
	[soServiceDays] [int] NULL,
	[soQty] [float] NULL,
	[soUnits] [nvarchar](50) NULL,
	[soAmount] [float] NULL,
	[soPriceType] [nvarchar](50) NULL,
	[soCustomerDisc] [float] NULL,
	[soRequestDate] [datetime] NULL,
	[soQtyBilled] [float] NULL,
	[soQtyFulfilled] [float] NULL,
	[soServiceRenewal] [bit] NULL,
	[soDeptName] [nvarchar](50) NULL,
	[soRevRecStartDate] [datetime] NULL,
	[soRevRecEndDate] [datetime] NULL,
	[soRevRecTermInMonths] [int] NULL,
	[soIsClosed] [bit] NULL,
   	[soLineId] [int] NULL,
	[endCustomerName] [nvarchar](500) NULL,
	[endCustomerAddress] [nvarchar](500) NULL
) 
GO
CREATE NONCLUSTERED INDEX NCL_Dim_SalesOrder_XrfIndexId ON [dim_salesorder] (xrfIndexId)
GO



/***************************************************************************************************************************
**                                          dim_salesorg
** by: mmccanlies       01/17/2017
** Create dim_salesorg table
***************************************************************************************************************************/
--IF object_id('dim_salesorg', 'U') IS NOT NULL
--DROP TABLE [dim_salesorg] 
GO
CREATE TABLE [dim_salesorg](
	[salesorgId] [bigint] IDENTITY(1,1) NOT NULL,
	[sourceId] [int] NULL,
	[geo] [nvarchar](255) NULL,
	[region] [nvarchar](255) NULL,
	[subRegion] [nvarchar](255) NULL,
	[territory] [nvarchar](255) NULL,
	[salesPerson] [nvarchar](255) NULL,
	[salesPersonEmail] [nvarchar](255) NULL
) 
GO


/***************************************************************************************************************************
**                                          dim_salesout
** by: mmccanlies       01/25/2017
** Create dim_salesout table
***************************************************************************************************************************/
-- SalesOut Dim
--IF object_id('dim_salesout', 'U') IS NOT NULL
--DROP TABLE [dim_salesout]
GO
CREATE TABLE [dim_salesout](
	[salesOutId] [int] NOT NULL,
	[salesOutLine] [int] NOT NULL,
	[outDate] [datetime] NULL,
	[outPurchaseDate] [datetime] NULL,
	[outSerialNo] [nvarchar](50) NULL,
	[outStatus] [int] NOT NULL,
	[outItemId] [int] NOT NULL,
	[outQty] [int] NOT NULL,
	[outAmt] [money] NOT NULL,
	[outListPrice] [money] NOT NULL,
	[outSoldThruReseller] [nvarchar](50) NULL,
	[outReseller] [nvarchar](100) NULL,
	[outResllerPONo] [nvarchar](100) NULL,
	[outCustomerNo] [int] NOT NULL,
	[outCompanyName] [nvarchar](200) NULL,
	[outAddr1] [nvarchar](150) NULL,
	[outAddr2] [nvarchar](100) NULL,
	[outAddr3] [nvarchar](100) NULL,
	[outAddr4] [nvarchar](50) NULL,
	[outCity] [nvarchar](100) NULL,
	[outState] [nvarchar](100) NULL,
	[outZip] [nvarchar](100) NULL,
	[outProvince] [nvarchar](50) NULL,
	[outCounty] [nvarchar](50) NULL,
	[outCountry] [nvarchar](100) NULL,
	[outEmail] [nvarchar](100) NULL,
	[outPhone] [nvarchar](50) NULL,
	[outSFPartnerNo] [nvarchar](50) NULL,
	[outSalesRegion] [int] NOT NULL,
	[outSalesOrderNo] [int] NOT NULL,
	[outSalesOrder] [int] NOT NULL,
	[outExternalId] [nvarchar](50) NULL
) 
GO
CREATE NONCLUSTERED INDEX NCL_Dim_SalesOut_salesOutId ON [dim_salesout] (salesOutId, salesOutLine)
GO



/***************************************************************************************************************************
**                                          dim_product
** by: mmccanlies       02/27/2017
** Create sku_dim
***************************************************************************************************************************/
--IF object_id('dim_product', 'U') IS NOT NULL
--DROP TABLE [dim_product]
GO
CREATE TABLE [dim_product](
	[productId] [int] IDENTITY(1,1) NOT NULL,
	[classId] [int] NULL,
	[itemId] [int] NOT NULL,
	[className] [nvarchar](100) NULL,
	[productClass] [nvarchar](128) NULL,
	[productType] [nvarchar](128) NULL,
	[productFamily] [nvarchar](128) NULL,
	[productFamilyPL] [nvarchar](128) NULL,
	[SkuNo] [nvarchar](50) NULL,
	[skuDurationYrs] [int] NULL,
	[skuDescription] [nvarchar](2000) NULL,
	[skuSeats] [int] NULL,
    [recordingHrs] [int] NULL,
    [vmrsIncl] [int] NULL,
    [unitName] [nvarchar](50) NULL,
    [externalId] [nvarchar](50) NULL,
UNIQUE NONCLUSTERED 
(	[itemId] ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO



/***************************************************************************************************************************
**                                          dim_subscription
** by: mmccanlies       01/16/2017
** Create dim_subscription
***************************************************************************************************************************/
--IF object_id('dim_subscription', 'U') IS NOT NULL
--DROP TABLE   [dim_subscription]
GO
CREATE TABLE [dim_subscription] (
    [xrfIndexId] [bigint] NOT NULL,
	[baseSubscriptionId] [int] NULL,
	[subscriptionId] [int] NOT NULL,
    [parentId] [int] NULL,
	[baseSubscription] [nvarchar](50) NULL,
	[subscription] [nvarchar](50) NULL,
    [parentSubscription] [nvarchar](50) NULL,
    [creditMemoNo] [nvarchar](50) NULL,
    [overallOrdr] [int] NULL,
    [renewalOrdr] [int] NULL,
	[isBase] [int] NULL,
	[refType] [nvarchar](100) NULL,
	[refTypeId] [int] NULL,
    [refTypeTxt] [nvarchar](100) NULL,
    [tierId] [int] NULL,
    [tierLvl]    [int] NULL,
    [tierName]    [nvarchar](50) NULL,
	[seats] [int] NULL,
    [totalSeats] [int] NULL,
	[startDate] [date] NULL,
	[endDate] [date] NULL,
	[entitledYrs] [int] NULL,
	[entitledMos] [int] NULL,
	[entitledDays] [int] NULL,
    [daysTilExpiration] [int] NULL,
	[invoiceAmount] [money] NULL,
	[invoiceDate] [date] NULL,
	[stdDiscount] [float] NULL,
	[ornDiscount] [float] NULL,
	[nsdDiscount] [float] NULL,
	[nsdApprovalNo] [nvarchar](50) NULL,
	[skuNo] [nvarchar](50) NULL,
	[endCustomerId] [int] NULL,
    [endCustomerName] [nvarchar](250) NULL,
    [endCustomerAddr] [nvarchar](500) NULL,
	[itemTypeId] [int] NULL,
	[itemType] [nvarchar](100) NULL,
	[itemId] [int] NULL,
	[salesOrderId] [int] NULL,
	[salesOrderLine] [int] NULL,
	[subscriptionStatusId] [int] NULL,
	[subscriptionStatus] [nvarchar](100) NULL,
    [featureType] [nvarchar](50) NULL,
	[featureAmt] [int] NULL,
    [extraSeats] [int] NULL,
    [amplifyQty] [int] NULL,
    [extremeQty] [int] NULL,
    [vmrsQty] [int] NULL,
	[cloudFeatures] [nvarchar](50) NULL,
	[vmrsLicenses] [int] NULL,
	[featureOrBase] [nvarchar](50) NULL,
    [ssoIncl]     [bit] NULL, 
    [lyncIncl]     [bit] NULL, 
    [maxUsersSet]    [int] NULL, 
    [maxUsersSetUnits]   [nvarchar](50) NULL,
    [maxMtgParticipants]    [int] NULL, 
    [maxVMRs]    [int] NULL, 
    [maxVMRsUnits]   [nvarchar](50) NULL,
    [endPointsAsUsers]    [bit] NULL, 
    [recordingEnabled]    [bit] NULL, 
    [recordingHrsIncl]    [bit] NULL, 
    [backgroundSet]    [bit] NULL,
    [isNew] [bit] NULL, 
    [isRenewal] [bit] NULL,
    [isMidTerm] [bit] NULL,
    [isUpgrade] [bit] NULL,
    [isCreditMemo] [bit] NULL, 
    [isAddSeats] [bit] NULL,
    [isAddFeature] [bit] NULL,
) 
GO
CREATE NONCLUSTERED INDEX NCL_Dim_Subscription_XrfIndexId ON [dim_Subscription] (xrfIndexId)
GO


/***************************************************************************************************************************
**                                          xrf_legacy_reseller
** by: mmccanlies       02/27/2017
** Create xrf_legacy_reseller
***************************************************************************************************************************/
--IF object_id('xrf_legacy_reseller', 'U') IS NOT NULL
--DROP TABLE	[xrf_legacy_reseller]
GO
CREATE TABLE [xrf_legacy_reseller](
	[baseSubscriptionId] [int] NULL,
	[subscriptionId] [int] NULL,
    [internalId] [int] NULL,
    [resellerId] [int] NULL,
	[baseSubscription] [nvarchar](50) NULL,
	[Subscription] [nvarchar](50) NULL,
	[salesOrderNo] [nvarchar](50) NULL,
	[salesOrderNoInt] [nvarchar](50) NULL,
	[invoiceNo] [nvarchar](50) NULL,
	[poNo] [nvarchar](50) NULL,
	[startDate] [date] NULL,
	[salesOutDate] [date] NULL,
	[resellerName] [nvarchar](100) NULL
) 
GO
CREATE NONCLUSTERED INDEX NCI_LegacyReseller_Xrf_baseSubscriptionId_salesOrderNoInt ON [tmp_legacyreseller_xrf] ([baseSubscriptionId], [salesOrderNoInt])
GO



/***************************************************************************************************************************
**                                          dim_subscription_details
** by: mmccanlies       03/02/2017
** Create dim_subscription_details table with columms for chanages and ARR bucketing
**
***************************************************************************************************************************/
-- Create View dim_subscription_details
--IF object_id('dim_subscription_details', 'U') IS NOT NULL
--DROP TABLE [dim_subscription_details]
GO
CREATE TABLE [dim_subscription_details](
    [xrfIndexId] [bigint] NOT NULL,
	[baseSubscriptionId] [int] NULL,
	[subscriptionId] [int] NOT NULL,
	[prevSubscriptionId] [int] NULL,
	[creditMemoNo] [nvarchar](50) NULL,
	[refTypeId] [int] NULL,
	[refTypeTxt] [nvarchar](100) NULL,
	[tierName] [nvarchar](50) NULL,
	[tierLvl] [int] NULL,
	[prefix] [varchar](10) NOT NULL,
	[entitlementTerm] [varchar](100) NULL,
	[priceTerm] [varchar](100) NULL,
	[seats] [int] NULL,
	[totalSeats] [int] NULL,
	[startDate] [date] NULL,
	[endDate] [date] NULL,
	[entitledDays] [int] NULL,
	[termDays] [int] NULL,
	[invoiceAmount] [money] NULL,
	[arrAmtPerYr] [money] NULL,
	[totalArrAmtPerYr] [money] NULL,
	[arrDelta] [money] NULL,
	[amplifyQty] [int] NULL,
	[extremeQty] [int] NULL,
	[vmrsQty] [int] NULL,
	[recordingHrs] [int] NULL,
	[arrAmtChg] [int] NULL,
	[entitlementChg] [int] NULL,
	[tierChg] [int] NULL,
	[seatChg] [int] NULL,
	[daysBtwPriorEndAndCurrStart] [int] NULL,
	[daysTilExpiration] [int] NULL,
    [isCreditMemo] [bit] NULL,
    [isAddSeats] [bit] NULL,
	[termChg] [int] NULL,
	[newBase] [int] NULL,
	[updateOrdr] [int] NULL,
	[baseIdOrdr] [int] NULL
)
GO

/**************************************************************************************************************************
**                                              VIEWS
***************************************************************************************************************************/

/***************************************************************************************************************************
**                                          vw_test_grp
** by: mmccanlies       01/24/2017
** Create vw_test_grp
***************************************************************************************************************************/
--IF object_id('vw_test_grp', 'v') IS NOT NULL
--DROP VIEW [vw_test_grp]
GO
CREATE VIEW [vw_test_grp] AS
SELECT * 
FROM [xrf_index] 
WHERE baseSubscriptionId IN  
( '131', '359', '663', '738', '757', '761', '780', '788', '791', '805', '840', '867', '870', '871', '902', '907'     -- First 147
, '914', '920', '925', '944', '962', '1047', '1140', '1144', '1348', '1511', '3702', '4334', '4538', '4600'
, '4698', '4719', '4833', '4880', '4883', '4939', '4941', '4985', '4987', '4993', '5042', '5043', '5048'
, '5050', '5087', '5094', '5098', '5119', '5122', '5129', '5131', '5159', '5163', '5167', '5189', '5219'
, '5222', '5238', '5286', '5298', '5344', '5374', '5389', '5393', '5400', '5420', '5444', '5512', '5578'
, '5591', '5653', '5657', '5874', '6042', '6300', '6648', '6936', '7583', '7597', '8113', '8141', '9446'
, '9472', '9790', '9798', '9799', '9807', '9815', '9816', '9825', '9828', '9833', '9836', '9838', '9844'
, '9846', '9847', '9852', '9855', '9859', '9862', '9865', '9866', '9867', '9869', '9870', '9871', '9872'
, '9885', '9887', '9888', '9900', '9904', '9906', '9907', '9908', '9909', '9916', '9918', '9924', '9925'
, '9927', '9928', '9933', '9934', '9938', '9940', '9942', '9944', '9946' )

-- Test Use Cases
('6366','3525','3771','845','1517','60','57','5408','580','3369','1544','1153','834','4901','563','1349','352','4206','3491','837','3393','3471','4015','3491','167','217')


/***************************************************************************************************************************
**                                          vw_subscription_update
** by: mmccanlies       02/28/2017
** vw_subscription_update is a critical view. It allows ranking of subscriptions at the New, Renewal levels and a sub-ranking of 
** additional Features and Seats so they can be summed to their 'parent' subscription which allows for direct comparison of 
** subscriptions at the parent level. Does not include the Credit Memo reversal lines.
** Something else may need to be done with Credit Memos
***************************************************************************************************************************/
-- Create View vw_subscription_update
--IF object_id('vw_subscription_update', 'v') IS NOT NULL
-- DROP VIEW [vw_subscription_update]
GO
CREATE VIEW [vw_subscription_update] AS (
SELECT DISTINCT
  s.xrfIndexId
, x.baseSubscriptionId
, x.subscriptionId
, x.[parentId]
, ( SELECT TOP 1 s2.subscription FROM dim_subscription s2 WHERE s2.baseSubscriptionId = x.baseSubscriptionId AND  s2.subscriptionId = x.parentId) AS 'parentSubscription'
, DENSE_RANK() OVER (PARTITION BY s.baseSubscriptionId ORDER BY s.startDate, s.subscriptionId) AS 'overallOrdr'
, x.rnkOrdr AS 'renewalOrdr'
, x.[refTypeTxt]
, s.tierName
, s.tierLvl
, s.[seats] AS 'seats'
, s.[seats] + x.[extraSeats] AS 'totalSeats'
--, s.amplify AS 'existingAmplify'
, x.[amplifyQty]
--, s.[amplify] + x.[amplifyQty] AS 'totalAmplify'
, x.[extremeQty]
--, s.[extreme] AS 'existingExtreme'
--, s.[extreme]+x.[extremeQty] AS 'totalExtreme'
--, 0 AS 'isCreditMemo'
, s.[vmrsLicenses] AS 'vmrsLicenses'
, s.creditMemoNo
, s.isCreditMemo
, CASE WHEN s.[subscriptionId] = s.[baseSubscriptionId] -- or refTypeId = 4
        THEN 1
        ELSE 0
    END AS 'isBase'
, CASE WHEN s.[subscriptionId] = s.[baseSubscriptionId] -- or refTypeId = 4
        THEN 1
        ELSE 0
    END AS 'isNew'
, CASE WHEN s.[refTypeId] IN (5, 7, 8)
    THEN 1
    ELSE 0
    END AS 'isRenewal'
, CASE WHEN s.[refTypeId] IN (6, 7, 8)
    THEN 1
    ELSE 0
    END AS 'isUpgrade'
, CASE WHEN s.[refTypeId] = 8
    THEN 1
    ELSE 0
    END AS 'isMidTerm'
, CASE WHEN s.[refTypeId] = 9
    THEN 1
    ELSE 0
    END AS 'isAddFeature'
, CASE WHEN s.[refTypeId] = 10
    THEN 1
    ELSE 0
    END AS 'isAddSeats'
FROM (
        SELECT
          [baseSubscriptionId] AS 'baseSubscriptionId'
        , [subscriptionId] AS 'subscriptionId'
        , [baseSubscriptionId] AS 'parentId'
        , [isBase] AS 'isBase'
        , DENSE_RANK() OVER (PARTITION BY baseSubscriptionId ORDER BY startDate, subscriptionId) AS 'RnkOrdr'
        , REPLACE(refType,'Cloud',CONVERT(varchar,refTypeId)) AS 'refTypeTxt'
        , [refType]
        , [refTypeId]
        , (SELECT ISNULL(SUM(s2.seats),0)      FROM [dim_subscription] s2 WHERE s2.baseSubscription = s1.baseSubscription AND s2.refTypeId = 10 AND s2.startDate BETWEEN s1.startDate AND DATEADD(DD,-1,s1.endDate) ) AS 'extraSeats'
        , (SELECT ISNULL(SUM(s2.featureAmt),0) FROM [dim_subscription] s2 WHERE s2.baseSubscription = s1.baseSubscription AND s2.refTypeId = 9 AND featureType = 'Amplify'  AND s2.startDate BETWEEN s1.startDate AND DATEADD(DD,-1,s1.endDate) ) AS 'amplifyQty'
        , (SELECT ISNULL(SUM(s2.featureAmt),0) FROM [dim_subscription] s2 WHERE s2.baseSubscription = s1.baseSubscription AND s2.refTypeId = 9 AND featureType = 'Extreme'  AND s2.startDate BETWEEN s1.startDate AND DATEADD(DD,-1,s1.endDate) ) AS 'extremeQty'
        FROM [dim_subscription] s1
        WHERE s1.refTypeId IN (4,5,6,7,8)
        UNION ALL
        SELECT
          [baseSubscriptionId]
        , [subscriptionId]
        , ( SELECT TOP 1 s2.subscriptionId FROM dim_subscription s2 WHERE s2.baseSubscription = s1.baseSubscription AND s2.refTypeId IN (4,5,6,7,8) AND s2.startDate <= DATEADD(DD,-1,s1.endDate) AND DATEADD(DD,-1,s2.endDate) >= s1.startDate ORDER BY s2.startDate DESC ) AS parentId
        , 0 AS isBase
        , -1 --DENSE_RANK() OVER (PARTITION BY baseSubscriptionId ORDER BY startDate, subscriptionId) AS 'RnkOrdr'
        , REPLACE(refType,'Cloud',CONVERT(varchar,refTypeId))
        , [refType]
        , [refTypeId]
        , 0 AS extraSeats
        , CASE WHEN featureType = 'Amplify'
            THEN ISNULL(featureAmt,0) 
            ELSE 0
            END AS amplifyQty
        , CASE WHEN featureType = 'Extreme'
            THEN ISNULL(featureAmt,0) 
            ELSE 0 
            END AS extremeQty
        FROM [dim_subscription] s1
        WHERE s1.refTypeId = 9    
        UNION ALL
        SELECT
          [baseSubscriptionId]
        , [subscriptionId]
        , ( SELECT TOP 1 s2.subscriptionId FROM dim_subscription s2 WHERE s2.baseSubscription = s1.baseSubscription AND s2.refTypeId IN (4,5,6,7,8) AND s2.startDate <= DATEADD(DD,-1,s1.endDate) AND DATEADD(DD,-1,s2.endDate) >= s1.startDate ORDER BY s2.startDate DESC ) AS parentId
        , 0 AS isBase
        , -1 --DENSE_RANK() OVER (PARTITION BY baseSubscriptionId ORDER BY startDate, subscriptionId) AS 'RnkOrdr'
        , REPLACE(refType,'Cloud',CONVERT(varchar,refTypeId))
        , [refType]
        , [refTypeId]
        , ISNULL(seats,0) AS extraSeats
        , 0 AS amplify
        , 0 AS extreme
        FROM [dim_subscription] s1
        WHERE s1.refTypeId = 10  
    ) x
JOIN [dim_subscription] s ON s.baseSubscriptionId = x.baseSubscriptionId AND  s.subscriptionId = x.subscriptionId
)

/***************************************************************************************************************************
**                                          vw_subscription_list
** by: mmccanlies       02/28/2017
** Create vw_subscription_list_dim view  list of basic subscripiton information with ordering by startDate and subscriptionId
** CASE stmt might have to be changed if they go through with change to set refType = refType of parent subscription
***************************************************************************************************************************/
-- Create View vw_subscription_list
--IF object_id('vw_subscription_list', 'v') IS NOT NULL
--DROP VIEW [vw_subscription_list]
GO
CREATE VIEW [vw_subscription_list] AS 
SELECT DISTINCT
  [xrfIndexId]
, [baseSubscriptionId]
, [subscriptionId]
, [isBase]
, [tierName]
, [tierLvl]
, [entitledDays]
, [seats]
, [featureType]
, [featureAmt]
, [maxVMRs]
, CONVERT(date,[startDate]) AS 'startDate'
, CONVERT(date,[endDate]) AS 'endDate'
, CONVERT(date,[invoiceDate]) AS 'invoiceDate'
, CONVERT(money,[invoiceAmount]) AS 'invoiceAmount'
, [refType]
, [refTypeId]
, CASE WHEN [dim_subscription].[refType] = 'Credit Memo'
      THEN 1
      ELSE 0
  END AS 'isCreditMemo'
, CASE WHEN [subscriptionId] = [baseSubscriptionId] -- or refTypeId = 4
       THEN 1
       ELSE 0
  END AS 'isNew'
, CASE WHEN [refTypeId] IN (5, 7, 8)
    THEN 1
    ELSE 0
  END AS 'isRenewal'
, CASE WHEN [refTypeId] IN (6, 7, 8)
    THEN 1
    ELSE 0
  END AS 'isUpgrade'
, CASE WHEN [refTypeId] = 8
    THEN 1
    ELSE 0
  END AS 'isMidTerm'
, CASE WHEN [refTypeId] = 9
    THEN 1
    ELSE 0
  END AS 'isAddFeature'
, CASE WHEN [refTypeId] = 10
    THEN 1
    ELSE 0
  END AS 'isAddSeats'
, DENSE_RANK() OVER (PARTITION BY baseSubscriptionId ORDER BY startDate, subscriptionId) AS 'RnkOrdr'
FROM [dim_subscription]
GO



/***************************************************************************************************************************
**                                          vw_subscription_sequence
** by: mmccanlies       02/07/2017
** Create vw_subsseq_dim view.  This view lists each subscription with it's subscription skipping creditmemo records
** NOTE: currently will only skip one credit memo per subscription. Will need to be enhanced to handle more than one CM in a row
***************************************************************************************************************************/
-- Create View vw_subscription_sequence
--IF object_id('vw_subscription_sequence', 'v') IS NOT NULL
--DROP VIEW [vw_subscription_sequence]
GO
CREATE VIEW [vw_subscription_sequence] AS 
SELECT 
  sub1.baseSubscriptionId AS Base
, sub1.subscriptionId AS Sub1
, sub2.subscriptionId AS Sub2
FROM [vw_subscription_list] sub1
JOIN [vw_subscription_list] sub2 ON sub2.baseSubscriptionId = sub1.baseSubscriptionId
    AND (sub2.RnkOrdr-sub1.RnkOrdr) = 1
    AND sub1.isCreditMemo != 1
UNION ALL
SELECT 
  sub1.baseSubscriptionId AS Base
, sub1.subscriptionId AS Sub1
, sub2.subscriptionId AS Sub2
FROM [vw_subscription_list] sub1
JOIN [vw_subscription_list] subm ON subm.baseSubscriptionId = sub1.baseSubscriptionId AND (subm.RnkOrdr-sub1.RnkOrdr) = 1
    AND subm.isCreditMemo = 1
JOIN [vw_subscription_list] sub2 ON sub2.baseSubscriptionId = sub1.baseSubscriptionId
    AND (sub2.RnkOrdr-sub1.RnkOrdr) = 2 


/**************************************************************************************************************************
**                                              FUNCTIONS
***************************************************************************************************************************/

/***************************************************************************************************************************
**                                          ufn_datediff_365
** by: mmccanlies       01/16/2017
** Create ufn_datediff_365
** Similar to DATEDIFF(DD,start,end) except, always returns days between Start and End data and ignores Leap Days and treats 
** all years as having 365 days for financial calendar purposes
***************************************************************************************************************************/
DROP FUNCTION [dbo].[ufn_datediff_365]
GO
CREATE FUNCTION [dbo].[ufn_datediff_365]
(
  @startDate DATE
, @endDate DATE
) RETURNS int AS
BEGIN 
    DECLARE @secondYear      AS DATE ;
    DECLARE @nextToLastYear  AS DATE ;
    DECLARE @daysBetween AS int = 0
    SELECT
      @secondYear = DATEADD(YY,YEAR(@startDate)-1899,0) 
    , @nextToLastYear   = DATEADD(YY,YEAR(@endDate)-1900,-1)
    OPTION (maxrecursion 100)
    ;WITH cte_tmp(dt) AS
    (
    SELECT CAST(@secondYear AS DATE)
    UNION ALL
    SELECT DATEADD(YY,1,dt)
    FROM cte_tmp
    WHERE dt < @nextToLastYear
    ) 
    SELECT @daysBetween = DATEDIFF(DD,@startDate,@endDate)-SUM(LeapDay)
    FROM (
    SELECT 
     YEAR(@startDate) AS startYr
    --, @startDate AS startDate
    --, CAST(CAST(YEAR(@startDate) AS VARCHAR(4))+'0301' AS DATE) AS March1
    --, DATEDIFF(DD, @startDate, CAST(CAST(YEAR(@startDate) AS varchar(4))+'0301' AS DATE)) 
    ,  CASE WHEN DATEDIFF(DD, @startDate, CAST(CAST(YEAR(@startDate) AS varchar(4))+'0301' AS DATE)) > 0
          THEN ISDATE(CAST(YEAR(@startDate) AS VARCHAR(4))+'0229')
          ELSE 0
      END AS 'LeapDay'
    UNION ALL
    SELECT 
      YEAR(dt) AS 'Year'
    --, DATEPART(DY,DATEADD(YY,YEAR(@startDate)-1899,0)) AS 'Date'
    , (ISDATE(CAST(YEAR(dt) AS VARCHAR(4))+'0229')) 'LeapDay'
    FROM cte_tmp 
    WHERE dt < @nextToLastYear
    UNION ALL
    SELECT
      YEAR(@endDate)
    --, @endDate AS startDate
    --, CAST(CAST(YEAR(@endDate) AS VARCHAR(4))+'0228' AS DATE) AS lastDayFeb
    --, DATEDIFF(DD, CAST(CAST(YEAR(@endDate) AS varchar(4))+'0228' AS DATE),@endDate) 
    ,  CASE WHEN YEAR(@endDate)>YEAR(@startDate) AND DATEDIFF(DD, CAST(CAST(YEAR(@endDate) AS VARCHAR(4))+'0228' AS DATE), @endDate) > 0
          THEN ISDATE(CAST(YEAR(@endDate) AS varchar(4))+'0229')
          ELSE 0
      END AS 'LeapDay'
    ) x
    RETURN @daysBetween
END

/**************************************************************************************************************************
**                                          END OF SCRIPT LS_FDW_BUILD                                                   **
***************************************************************************************************************************/



