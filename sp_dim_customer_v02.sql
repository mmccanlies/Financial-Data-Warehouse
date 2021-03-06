USE [sandbox_mike]
GO
/****** Object:  StoredProcedure [dbo].[sp_dim_customer]    Script Date: 2/27/2017 11:47:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
**                                     sp_dim_customer
**
** dependencies: ns_customer
**
** Load story or task#: description
** created:  2/27/2017   mmccanlies           
** revised:  3/07/2017      "            Revised to use source views instead of tables i.e. vw_custom_subscription vs. ns_custom_subscription
**************************************************************************************************/
ALTER PROCEDURE [dbo].[sp_dim_customer] 
(
    @Rebuild   bit = 1,       -- 1 = Truncate and rebuild
    @Debug     bit = 0        -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_dim_customer'
    DECLARE @ErrMsg   nvarchar(2000) = N'**** Error occurred in '+@ProcName+' - '	
    DECLARE @EntryMsg nvarchar(1000) = N'Starting Procedure '+@ProcName+'  '
    DECLARE @MidMsg   nvarchar(1000) = N'    Procedure '+@ProcName+'  '
    DECLARE @ExitMsg  nvarchar(1000) = N'Exiting Procedure '+@ProcName+'  '
    DECLARE @ExitTxt  nvarchar(1500)
    DECLARE @currentTime nvarchar(100)
    SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime())
    EXEC [sp_message_handler] @currentTime, @EntryMsg, @ProcName ;

BEGIN TRY
        -- Major Code Sections --
    BEGIN TRANSACTION
        IF @Rebuild =1 
            TRUNCATE TABLE [dim_customer] ;
            -- DELETE FROM [dim_customer] WHERE recordType = 'BILL'

        INSERT INTO [dim_customer] 
        ( internalId, alternateId, recordType, entityId, companyName, defaultAddr, emailDomain, Addressee, addr1, addr2, addr3, city, [state], zip, country, addrText
         , label, catInternalId, catName, subsInternalId, subsName, phone, fax, email, termsId, termsName, currency, stage, [status], externalId, lastModDate )
        SELECT DISTINCT 
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
        FROM [vw_customer]
        WHERE [billingInternalId] IS NOT NULL
        ORDER BY ISNULL(CONVERT(int, [billingInternalId]),-1) ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows inserted'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        -- END Customers
        DELETE FROM [dim_customer] WHERE recordType = 'END'

        INSERT INTO [dim_customer] 
        ( internalId, alternateId, recordType, entityId, companyName, defaultAddr, emailDomain, Addressee, addr1, addr2, addr3, city, [state], zip, country, addrText
         , label, catInternalId, catName, subsInternalId, subsName, phone, fax, email, termsId, termsName, currency, stage, [status], externalId, lastModDate )
         SELECT DISTINCT 
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
        FROM [vw_customer]
        ORDER BY CONVERT(int, internalId) ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
        EXEC [sp_message_handler] @currentTime, @ExitTxt, @ProcName ;

        INSERT INTO [dim_customer]
        ( internalId, alternateId, recordType, companyName, defaultAddr, catInternalId, catName, subsInternalId ) VALUES
        ( -1, -1, 'BILL', 'NA', 'NA' , -1, 'NA', -1 ), 
        ( -1, -1, 'END',  'NA', 'NA' , -1, 'NA', -1 )

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

