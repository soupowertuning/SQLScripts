USE [Traces]
GO

/****** Object:  StoredProcedure [dbo].[stpXEvent_Erros_BD]    Script Date: 26/09/2016 11:38:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*


CREATE TABLE [dbo].[Log_Erros_BD](
	[err_timestamp] [datetime] NULL,
	[err_severity] [tinyint] NULL,
	[err_number] [int] NULL,
	[username] [varchar](100) NULL,
	[database_id] [varchar](100) NULL,
	[err_message] [varchar](512) NULL,
	[sql_text] [varchar](max) NULL,
	[Dt_Registro] [datetime] NOT NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
*/

CREATE procedure [dbo].[stpXEvent_Erros_BD]
AS
BEGIN
	-- VERIFICA SE JA EXISTE ALGUM EVENTO ATIVO
	IF EXISTS( select * from sys.dm_xe_sessions where name = 'what_queries_are_failing' )
	BEGIN
		-- Stop your Extended Events session
		ALTER EVENT SESSION what_queries_are_failing ON SERVER
		STATE = STOP;

		IF(OBJECT_ID('tempdb..#events_cte') IS NOT NULL)
			DROP TABLE #events_cte

		select
			DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),xevents.event_data.value('(event/@timestamp)[1]', 'datetime')) AS [err_timestamp],
			xevents.event_data.value('(event/data[@name="severity"]/value)[1]', 'tinyint') AS [err_severity],
			xevents.event_data.value('(event/data[@name="error_number"]/value)[1]', 'int') AS [err_number],
			xevents.event_data.value('(event/action[@name="username"]/value)[1]', 'varchar(100)') AS username,
			xevents.event_data.value('(event/action[@name="database_id"]/value)[1]', 'varchar(100)') AS database_id,
			xevents.event_data.value('(event/data[@name="message"]/value)[1]', 'varchar(512)') AS [err_message],
			xevents.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'varchar(max)') AS [sql_text],
			--xevents.event_data
			GETDATE() as [Dt_Registro]
		into #events_cte
		from sys.fn_xe_file_target_read_file
			('C:\BKP\Traces\what_queries_are_failing*.xel',
			'C:\BKP\Traces\what_queries_are_failing*.xem',
			null, null)
		cross apply (select CAST(event_data as XML) as event_data) as xevents

		insert into Log_Erros_BD
		SELECT A.*
		from #events_cte A	
		left join Log_Erros_BD B on A.err_message = B.err_message and A.err_timestamp = B.err_timestamp
		where A.sql_text not like '%sp_whoisactive%'
			and A.sql_text not like '%stpAlerta%'
			and B.err_message is null
		order by A.err_timestamp
	END

	-- VERIFICA SE JA EXISTE ALGUM EVENTO CRIADO
	IF EXISTS( select * from sys.server_event_sessions where name = 'what_queries_are_failing' )
	BEGIN
		-- Clean up your session from the server
		DROP EVENT SESSION what_queries_are_failing ON SERVER;
	END

	CREATE EVENT SESSION
	what_queries_are_failing
	ON SERVER
	ADD EVENT sqlserver.error_reported
	(
	ACTION (sqlserver.sql_text, sqlserver.tsql_stack, sqlserver.database_id, sqlserver.username)
	WHERE ([severity]> 12)
	)
	ADD TARGET package0.asynchronous_file_target
	(set filename = 'C:\BKP\Traces\what_queries_are_failing.xel' ,
	metadatafile = 'C:\BKP\Traces\what_queries_are_failing.xem',
	max_file_size = 500,
	max_rollover_files = 5)
	WITH (MAX_DISPATCH_LATENCY = 5SECONDS)

	-- Start the session
	ALTER EVENT SESSION what_queries_are_failing
	ON SERVER STATE = START
END
GO

USE [msdb]
GO

/****** Object:  Job [DBA - XEvent erros Banco de dados]    Script Date: 22/02/2018 19:09:34 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 22/02/2018 19:09:34 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - XEvent erros Banco de dados', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBA - XEvent error]    Script Date: 22/02/2018 19:09:34 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - XEvent error', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec stpXEvent_Erros_BD', 
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
		@freq_subday_interval=60, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150812, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'3fa56740-03a8-4232-8c5b-1cf2b0286f22'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

-- Cria o Evento
CREATE EVENT SESSION
what_queries_are_failing
ON SERVER
ADD EVENT sqlserver.error_reported
(
ACTION (sqlserver.sql_text, sqlserver.tsql_stack, sqlserver.database_id, sqlserver.username)
WHERE ([severity]> 12)
)
ADD TARGET package0.asynchronous_file_target
(set filename = 'D:\Traces\what_queries_are_failing.xel' ,
metadatafile = 'D:\Traces\what_queries_are_failing.xem',
max_file_size = 500,
max_rollover_files = 5)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS)


-- Start the session
ALTER EVENT SESSION what_queries_are_failing
ON SERVER STATE = START




