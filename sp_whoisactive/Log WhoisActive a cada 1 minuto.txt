--Estou usando uma base chamada Traces para guardar as procedures
use Traces 
if OBJECT_ID('Resultado_WhoisActive') is not null
	drop table Resultado_WhoisActive
CREATE TABLE Resultado_WhoisActive (   Dt_Log datetime,[dd hh:mm:ss.mss] varchar(8000) NULL,[database_name] nvarchar(128) NULL,
   [session_id]       smallint NOT NULL,
    blocking_session_id       smallint  NULL,
   [sql_text] xml NULL,[login_name] nvarchar(128) NOT NULL,[wait_info] nvarchar(4000) NULL,
      [status] varchar(30) NOT NULL,[percent_complete] varchar(30) NULL,[host_name] nvarchar(128) NULL,[sql_command] xml NULL,[CPU] varchar(100),
	  [reads] varchar(100),[writes] varchar(100)
    )      

  USE [msdb]
GO

/****** Object:  Job [DBA - Carga Whoisactive]    Script Date: 04/23/2014 19:59:41 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 04/23/2014 19:59:41 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Carga Whoisactive', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBA - WhoisActive]    Script Date: 04/23/2014 19:59:41 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - WhoisActive', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC sp_WhoIsActive @get_outer_command = 1,
            @output_column_list = ''[collection_time][d%][session_id][blocking_session_id][sql_text][login_name][wait_info][status][percent_complete]
      [host_name][database_name][sql_command][CPU][reads][writes]'',
    @destination_table = ''Resultado_WhoisActive''
', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA - WhoisActive', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140212, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=220000, 
		@schedule_uid=N'c8a3eb26-b2ed-456d-8c4d-ae7c95e88163'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:


