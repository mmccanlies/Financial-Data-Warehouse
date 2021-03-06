USE [sandbox_mike]
GO
/****** Object:  StoredProcedure [dbo].[ls_msgHandler]    Script Date: 2/26/2017 6:18:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*************************************************************************************************
**                                    sp_message_handler
** 
** Utility procedure for all procedures to call that will load message into ls_Messages_utl
** created:  2/20/2017   mmccanlies         created 
** revised:  2/26/2017   mmccanlies         changed name of procedure and table written to 
**************************************************************************************************/
CREATE PROCEDURE [sp_message_handler] 
(
    @MsgTimeStamp nvarchar(100),
    @Message      nvarchar(1000),
    @Source       nvarchar(100)
)
AS
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
    SET NOCOUNT ON
    
    INSERT INTO utl_messages ( msgTimeStamp, message, source ) VALUES
    ( @MsgTimeStamp, @Message, @Source )
 
    -- RETURN SUCCESS --
    RETURN (0) 

