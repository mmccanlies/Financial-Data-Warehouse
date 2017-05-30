USE [sandbox_mike]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
**                                    sp_ctrl_main
** 
** Main FDW Load control program
** dependencies:    -- generally expects all staging tables to be loaded
** 
** created:  3/06/2017   mmccanlies 
** revised:  3/08/2017   mmccanlies        Added "isActive = 1" condition
**************************************************************************************************/
ALTER PROCEDURE [sp_ctrl_main]
(
    @batchId int = 1
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    DECLARE @ProcName nvarchar(100)  = N'sp_ctrl_main '
    DECLARE @ErrMsg   nvarchar(2000) = N'**** Error occurred in '+@ProcName+' - '	
    DECLARE @EntryMsg nvarchar(1000) = N'Starting Procedure '+@ProcName+'  '
    DECLARE @MidMsg   nvarchar(1000) = N'    Procedure '+@ProcName+'  '
    DECLARE @ExitMsg  nvarchar(1000) = N'Exiting Procedure '+@ProcName+'  '
    DECLARE @ExitTxt  nvarchar(1500)
    DECLARE @currentTime nvarchar(100)
    DECLARE @sqlStr nvarchar(1000);
    DECLARE @iMax int;
    DECLARE @idx int = 1;

    DECLARE @tblBatchOrder TABLE
               (
                RowID              int identity (1,1), 
                procName      nvarchar(100),
                procId        int,
                procOrder     int,
                procTruncate  bit,
                procDebug     bit
               ) ;

    -- log entry
    SELECT @currentTime = CONVERT(nvarchar(100), sysdatetime())
    EXEC [sp_message_handler] @currentTime, @EntryMsg, @ProcName ;
    SET @batchId = 1 ;
    
    INSERT INTO @tblBatchOrder 
    SELECT 
      procName
    , procId
    , procOrder
    , procTruncateTbl
    , procDebug
    FROM [utl_batch_order] 
    WHERE procBatchId = @batchId 
      AND isActive = 1
    ORDER BY procOrder  ;

    SET @iMax = @@ROWCOUNT
    SET @idx = 1

BEGIN TRY
    BEGIN TRANSACTION
        WHILE @idx <= @iMax  
        BEGIN

            SELECT @sqlStr = 'EXEC ['+procName+'] '+CAST(procTruncate AS nvarchar)+', '+CAST(procDebug AS nvarchar)
            FROM @tblBatchOrder 
            WHERE rowId = @idx 
            ORDER BY procOrder ;

            EXEC( @sqlStr ) ;
            SET @idx += 1;  
        END

           
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

