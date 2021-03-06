USE [sandbox_mike]
GO
/****** Object:  StoredProcedure [dbo].[sp_dim_product]    Script Date: 2/27/2017 12:00:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
**                                     sp_dim_product
** 
** Load product dimension table
** created:  2/24/2017   mmccanlies           
** revised:  3/07/2017      "            Revised to use source views instead of source tables 
**************************************************************************************************/
ALTER PROCEDURE [dbo].[sp_dim_product] 
(
    @Rebuild   bit = 1,        -- 1 = Truncate and rebuild
    @Debug     bit = 0         -- 1 = Execute Debug Clause
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_dim_product '
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
            TRUNCATE TABLE [dim_product]

        -- Major Code Sections --
        INSERT INTO dim_product 
        ( classId, itemId, className, productClass, productType, productFamily, productFamilyPL, skuNo, skuDescription, skuDurationYrs, skuSeats, 
          recordingHrs, vmrsIncl, unitName, externalId )
        SELECT DISTINCT
          CONVERT(int, nis.[class-internalId]) AS 'classId'
        , CONVERT(int, nis.internalId) AS 'itemId'
        , nis.[class-name] AS 'className'
        , PARSENAME(REPLACE(nis.[class-name],' : ','.'),1) AS 'productClass'
        , PARSENAME(REPLACE(nis.[class-name],' : ','.'),2) AS 'productType'
        , PARSENAME(REPLACE(nis.[class-name],' : ','.'),3) AS 'productFamily'
        , PARSENAME(REPLACE(nis.[class-name],' : ','.'),4) AS 'productFamilyPL'
        , nis.itemId AS 'SkuNo'
        , nis.salesDescription AS 'skuDescription'
        , nis.[customFieldList-custitem_term] AS 'skuDurationYrs'
        , CONVERT(int, nis.[customFieldList-custitem_number_of_seats]) AS 'skuSeats'
        , CONVERT(int, nis.[customFieldList-custitem_recording_hours]) AS 'recordingHrs'
        , CONVERT(int, nis.[customFieldList-custitem_vmrs_included])   AS 'vmrsIncl'
        , [saleUnit-name] AS 'unitName'
        , [externalId] AS 'externalId'
        FROM [vw_nonInventorySaleItem] nis
        -- JOIN [xrf_index] xrf ON nis.[internalId] = xrf.[salesOrderId]
        ORDER BY CONVERT(int, nis.internalId), CONVERT(int, nis.[class-internalId]) ;

        -- log result
        SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
               @ExitTxt = @MidMsg+CONVERT(varchar,@@ROWCOUNT)+' rows updated'
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
            @ErrState    = CONVERT(nvarchar, ERROR_STATE())+' ' ;  
    
    SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime()),
           @ErrMsg = @ErrMessage+@ErrSeverity+@ErrState ;
    EXEC [sp_message_handler] @currentTime, @ErrMsg, @ProcName ;
    ROLLBACK
    RAISERROR ( @ErrMessage, @ErrSeverity, @ErrState );  
END CATCH;  

