/*****************************************************************************************************

Substituir  C:\BASESDEDADOS\Traces 

*****************************************************************************************************/


USE [Traces]
GO

CREATE TABLE [dbo].[Log_DeadLock](
	[eventName] [varchar](100) NULL,
	[eventDate] [datetime] NULL,
	[deadlock] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
USE [Traces]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[stpXEvent_DeadLock]
AS
BEGIN
	-- Stop your Extended Events session
	ALTER EVENT SESSION capture_deadlocks ON SERVER
	STATE = STOP;

	declare @filenamePattern sysname;
 
	SELECT @filenamePattern = REPLACE( CAST(field.value AS sysname), '.xel', '*xel' )
	FROM sys.server_event_sessions AS [session]
	JOIN sys.server_event_session_targets AS [target]
	  ON [session].event_session_id = [target].event_session_id
	JOIN sys.server_event_session_fields AS field 
	  ON field.event_session_id = [target].event_session_id
	  AND field.object_id = [target].target_id	
	WHERE
		field.name = 'filename'
		and [session].name= N'capture_deadlocks'

	insert into Log_DeadLock
	SELECT deadlockData.EventName,dateadd(hh,-3,deadlockData.eventDate),deadlockData.deadlock
	FROM sys.fn_xe_file_target_read_file ( @filenamePattern, null, null, null) 
		as event_file_value
	CROSS APPLY ( SELECT CAST(event_file_value.[event_data] as xml) ) 
		as event_file_value_xml ([xml])
	CROSS APPLY (
		SELECT 
			event_file_value_xml.[xml].value('(event/@name)[1]', 'varchar(100)') as eventName,
			event_file_value_xml.[xml].value('(event/@timestamp)[1]', 'datetime') as eventDate,
			event_file_value_xml.[xml].query('//event/data/value/deadlock') as deadlock	
	  ) as deadlockData
	  LEFT JOIN Log_DeadLock X on dateadd(hh,-3,deadlockData.eventDate) = X.eventDate
	WHERE deadlockData.eventName = 'xml_deadlock_report'
		and X.eventDate is null
	ORDER BY deadlockData.eventDate


	-- Clean up your session from the server
	DROP EVENT SESSION [capture_deadlocks] ON SERVER;


	CREATE EVENT SESSION [capture_deadlocks] ON SERVER 
	ADD EVENT sqlserver.xml_deadlock_report( ACTION(sqlserver.database_name) ) 
	ADD TARGET package0.asynchronous_file_target(
	  SET filename = 'C:\BASESDEDADOS\Traces\capture_deadlocks.xel',
		  max_file_size = 500,
		  max_rollover_files = 5)
	WITH (
		STARTUP_STATE=ON,
		EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
		MAX_DISPATCH_LATENCY=15 SECONDS,
		TRACK_CAUSALITY=OFF
		)
 

	 -- Start the session
	ALTER EVENT SESSION capture_deadlocks
	ON SERVER STATE = START
END

GO

-- INICIA O EVENTO
CREATE EVENT SESSION [capture_deadlocks] ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report( ACTION(sqlserver.database_name) ) 
ADD TARGET package0.asynchronous_file_target(
	SET filename = 'C:\BASESDEDADOS\Traces\capture_deadlocks.xel',
		max_file_size = 500,
		max_rollover_files = 5)
WITH (
	STARTUP_STATE=ON,
	EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY=15 SECONDS,
	TRACK_CAUSALITY=OFF
	)
 

	-- Start the session
ALTER EVENT SESSION capture_deadlocks
ON SERVER STATE = START

GO

USE [msdb]
GO

/****** Object:  Job [DBA - XEvent Deadlock]    Script Date: 25/09/2017 23:40:03 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 25/09/2017 23:40:03 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - XEvent Deadlock', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Alerta_BD', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [PROC]    Script Date: 25/09/2017 23:40:03 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Executa Procedure', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [stpXEvent_DeadLock]', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DIÁRIO - A CADA 5 MINUTOS', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160713, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=220059, 
		@schedule_uid=N'db1f3048-7ca2-48d4-b832-bf918af054b9'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


/*
-- PARA TESTE

SELECT * FROM Traces.[dbo].[Log_DeadLock]

use traces
go
create table teste1 (id int)

insert into teste1 values (1)

create table teste2 (id int)

insert into teste2 values (2)


-- CONEXAO 1
BEGIN TRAN
	UPDATE teste1
	SET id = id

	UPDATE teste2
	SET id = id

COMMIT

-- CONEXAO 2
BEGIN TRAN
	UPDATE teste2
	SET id = id

	UPDATE teste1
	SET id = id

COMMIT


EXEC msdb.dbo.sp_start_job N'DBA - XEvent Deadlock'


SELECT * FROM Traces.[dbo].[Log_DeadLock]

DROP TABLE teste1
DROP TABLE teste2
*/