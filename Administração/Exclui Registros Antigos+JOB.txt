
USE Traces 

if object_id('stpExclui_Registros_Antigos') is not null
	drop procedure stpExclui_Registros_Antigos
	GO


create procedure stpExclui_Registros_Antigos
AS
BEGIN
	declare @Registro_Contador int, @Resultado_WhoisActive int, @Historico_Tamanho_Tabela int, --@Acesso_A_Disco int,
			@Historico_Utilizacao_Indices int, @Historico_Fragmentacao_Indice int, @Traces INT,
			@Historico_Waits_Stats int, @Historico_Utilizacao_Arquivo INT
		
	-- PARAMETRIZAÇÃO - Todos esses valores abaixo são em dias
	select 
		@Registro_Contador = 60, -- Todos esses valores são em dias
		@Resultado_WhoisActive = 7,
		@Historico_Tamanho_Tabela = 180,
		--@Acesso_A_Disco = 7,
		@Historico_Utilizacao_Indices = 90,
		@Historico_Fragmentacao_Indice = 60,
		@Traces = 60,
		@Historico_Waits_Stats = 30,
		@Historico_Utilizacao_Arquivo = 30
	
	delete from Registro_Contador
	where Dt_Log <  DATEADD(dd,@Registro_Contador*-1,getdate())
		
	delete from Resultado_WhoisActive
	where Dt_Log <  DATEADD(dd,@Resultado_WhoisActive*-1,getdate())
	
	delete from Historico_Tamanho_Tabela
	where Dt_Referencia <  DATEADD(dd,@Historico_Tamanho_Tabela*-1,getdate())
	
	delete from Historico_Utilizacao_Indices
	where Dt_Historico <  DATEADD(dd,@Historico_Utilizacao_Indices*-1,getdate())
	
	--delete from Acesso_A_Disco
	--where Dt_Registro <  DATEADD(dd,@Acesso_A_Disco*-1,getdate())
	
	delete from Historico_Fragmentacao_Indice
	where Dt_Referencia <  DATEADD(dd,@Historico_Fragmentacao_Indice*-1,getdate())
	
	delete from Traces
	where StartTime <  DATEADD(dd,@Traces*-1,getdate())
	
	delete from Historico_Waits_Stats
	where Dt_Referencia <  DATEADD(dd,@Historico_Waits_Stats*-1,getdate())

	delete from Historico_Utilizacao_Arquivo
	where Dt_Registro <  DATEADD(dd,@Historico_Utilizacao_Arquivo*-1,getdate())	
END
	
	GO

USE [msdb]
GO

/****** Object:  Job [DBA - Exclui Registros Antigos]    Script Date: 11/09/2014 18:37:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 11/09/2014 18:37:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Exclui Registros Antigos', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Nenhuma descrição disponível.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Alerta_BD', 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBA - Exclui registros antigos]    Script Date: 11/09/2014 18:37:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - Exclui registros antigos', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec stpExclui_Registros_Antigos', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA - Exclui registros Antigos', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140705, 
		@active_end_date=99991231, 
		@active_start_time=235000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


