--Estou usando uma base chamada Traces para guardar as procedures
Use Traces

GO
CREATE PROCEDURE [dbo].[stpBackup_Diferencial_Disco]
AS
	declare @Backup_Databases table (Nm_database varchar(500))
	declare @Nm_Database varchar(500), @Nm_Caminho varchar(5000)

	insert into @Backup_Databases
	select Name
	from sys.databases
	where Name not in ('tempdb','msdb','master','model') AND state_desc = 'ONLINE'
	
	-- Exclui as bases que devem ser desconsideradas
	--DELETE @Backup_Databases
	--WHERE Nm_database IN (SELECT Nm_Database FROM [dbo].[Desconsiderar_Databases_Rotinas])
		
	while exists (select null from @Backup_Databases)
	begin
		
		select top 1 @Nm_Database = Nm_database from @Backup_Databases order by Nm_database
		
		set @Nm_Caminho = 'F:\Backups\Diferencial\' + @Nm_Database + '_Diferencial_Dados.bak'
		
		exec traces.dbo.stpBackup_Diferencial_Database @Nm_Caminho, @Nm_Database, @Nm_Caminho --o último parametro corresponde a descrição do bkp
		
		delete from @Backup_Databases where Nm_database = @Nm_Database
	End
	
	GO
	CREATE procedure [dbo].[stpBackup_Diferencial_Database] 
		@Caminho varchar(150) 
		, @Nm_Database varchar(50)
		, @Ds_Backup varchar(255) = NULL -- 255 é maior valor aceito pelo campo description da tabela 'msdb.dbo.backupset'
	AS	
		declare @Nm_Backup varchar(150);
		set @Nm_Backup = 'Backup Diferencial em Disco '+@Nm_Database
		
		if (@Ds_Backup is null)
		begin
			backup database @Nm_Database 
			to disk = @Caminho
			WITH  FORMAT, COMPRESSION
			, NAME = @Caminho, DIFFERENTIAL
		end
		else
		begin
			backup database @Nm_Database 
			to disk = @Caminho
			WITH  FORMAT, COMPRESSION
			, NAME = @Caminho, Description = @Ds_Backup,DIFFERENTIAL
		end


GO

USE [Traces]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[stpBackup_Novas_Databases]
AS
BEGIN
	-- Realiza o backup full para novas databases criadas no dia
	declare @Backup_Databases table (Nm_database varchar(500))
	declare @Nm_Database varchar(500), @Nm_Caminho varchar(5000)
		
	insert into @Backup_Databases
	select name
	from sys.sysdatabases
	where crdate >= CAST(floor(cast(getdate() as float)) as datetime)
		and name <> 'tempdb'
		and dbid > 4
		
	declare @query varchar(4000)
	
	while exists (select null from @Backup_Databases)
	begin		
		select top 1 @Nm_Database = Nm_database from @Backup_Databases order by Nm_database
		
		set @Nm_Caminho =	'\\C\backup_sql\Full\' + @Nm_Database + '_' 
							+ REPLACE(CONVERT(VARCHAR(10),GETDATE(),120),'-','') + '_Dados.bak'
		
		exec traces.dbo.stpBackup_Full_Database @Nm_Caminho, @Nm_Database, @Nm_Caminho --o último parametro corresponde a descrição do bkp
		
		delete from @Backup_Databases where Nm_database = @Nm_Database
	End
END

GO

USE [msdb]
GO

/****** Object:  Job [DBA - Backup Diferencial Databases]    Script Date: 26/03/2017 14:18:07 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 26/03/2017 14:18:07 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Backup Diferencial Databases', 
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
/****** Object:  Step [DBA - Backup Diferencial Novas Databases]    Script Date: 26/03/2017 14:18:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - Backup Diferencial Novas Databases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dbo].[stpBackup_Novas_Databases]', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [BKP Diferencial]    Script Date: 26/03/2017 14:18:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'BKP Diferencial', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [dbo].[stpBackup_Diferencial_Disco]', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA - Backup Diferencial Databases', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=62, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20160517, 
		@active_end_date=99991231, 
		@active_start_time=200000, 
		@active_end_time=235959, 
		@schedule_uid=N'415f6ffc-1d5f-4578-a2a8-eef0faa697a6'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


