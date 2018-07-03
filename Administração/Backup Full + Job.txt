--Estou usando uma base chamada Traces para guardar as procedures
use Traces

/*
ALTERAR O caminho do backup para o tamanho escolhido pelo cliente: D:\Backup\FULL\
 -- COMPRESSION  --incluir a compressão caso a versão seja maior que a 2008 R2
*/

GO
if OBJECT_ID('stpBackup_FULL_Database') is not null
	drop procedure stpBackup_FULL_Database
		 
GO
CREATE procedure [dbo].[stpBackup_FULL_Database] 
	@Caminho varchar(150) 
	, @Nm_Database varchar(500)
	, @Ds_Backup varchar(255) = NULL -- 255 é maior valor aceito pelo campo description da tabela 'msdb.dbo.backupset'
AS
BEGIN
	declare @Nm_Backup varchar(150);
	set @Nm_Backup = 'Backup FULL em Disco ' + @Nm_Database
		
	if (@Ds_Backup is null)
	begin
		backup database @Nm_Database 
		to disk = @Caminho
		WITH  FORMAT, CHECKSUM, NAME = @Nm_Backup, COMPRESSION
				
	end
	else
	begin
		backup database @Nm_Database 
		to disk = @Caminho
		WITH  FORMAT, CHECKSUM, NAME = @Caminho, Description = @Ds_Backup, COMPRESSION		
	end
END
GO

if OBJECT_ID('stpBackup_Databases_Disco') is not null
	drop procedure stpBackup_Databases_Disco
GO
CREATE procedure [dbo].[stpBackup_Databases_Disco]
AS
BEGIN
	declare @Backup_Databases table (Nm_database varchar(500))
	declare @Nm_Database varchar(500), @Nm_Caminho varchar(5000)
	
	insert into @Backup_Databases
	select name
	from sys.databases
	where 
		name not in ('tempdb') 
		AND state_desc = 'ONLINE'

	-- Exclui as bases que devem ser desconsideradas
	--DELETE @Backup_Databases
	--WHERE Nm_database IN (SELECT Nm_Database FROM [dbo].[Desconsiderar_Databases_Rotinas])
				
/*
-- BACKUP FULL DAS BASES ABAIXO SOMENTE NO DOMINGO
		IF((SELECT DATEPART(WEEKDAY, GETDATE())) <> 1 )
		begin
			DELETE @Backup_Databases
			WHERE Nm_database IN ('JF','NFEJF')
		end
*/		
			
		while exists (select null from @Backup_Databases)
		begin
			
			select top 1 @Nm_Database = Nm_database from @Backup_Databases order by Nm_database
			
			/* --armazena uma semana de backup
			set @Nm_Caminho = 'D:\BKP_DADOS\Full\' + @Nm_Database+ '_'+(CASE DATEPART(w, GETDATE()) 
							WHEN 1 THEN 'Domingo'
							WHEN 2 THEN 'Segunda'
							WHEN 3 THEN 'Terca'
							WHEN 4 THEN 'Quarta'
							WHEN 5 THEN 'Quinta' 
							WHEN 6 THEN 'Sexta'
							WHEN 7 THEN 'Sabado'
							END ) + '_Dados.bak'
			*/

			set @Nm_Caminho = 'D:\Backup\FULL\' + @Nm_Database + '_Dados.bak'
			
			exec Traces.dbo.stpBackup_FULL_Database @Nm_Caminho, @Nm_Database, @Nm_Caminho --o último parametro corresponde a descrição do bkp
			
			delete from @Backup_Databases where Nm_database = @Nm_Database
		End
END

GO
	
USE [msdb]
GO

/****** Object:  Job [DBA - Backup Databases FULL]    Script Date: 10/08/2015 19:58:03 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 10/08/2015 19:58:03 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Backup Databases FULL', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Alerta_BD', 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBA - Backup Databases FULL]    Script Date: 10/08/2015 19:58:04 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - Backup Databases FULL', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec stpBackup_Databases_Disco', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA - Backup Databases FULL', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140427, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
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


