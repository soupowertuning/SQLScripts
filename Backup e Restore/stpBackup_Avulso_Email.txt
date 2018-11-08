/*
------------------------------------------------------------------------------------------------------------------------
INSTRUÇÕES - IMPORTANTE:
------------------------------------------------------------------------------------------------------------------------
Fazer o REPLACE nos e-mails abaixo pelos e-mails desejados.

operator@dominio.com.br

email@dominio.com.br;email2@dominio.com.br


Profile E-mail - Conferir se vai precisar fazer o REPLACE também

@profile_name = 'MSSQLServer'
*/

USE Traces

GO

/*
-- P/ TESTE
EXEC stpBackup_Avulso_Email 'NomeDatabase', 'C:\SQLServer\Backup\','email@dominio.com.br'
*/

CREATE PROCEDURE [dbo].[stpBackup_Avulso_Email] (@Nm_Database VARCHAR(200), @Ds_Caminho_Backup VARCHAR(500), @Ds_Email VARCHAR(500))
AS BEGIN
	/*
	-- P/ TESTE
	DECLARE @Nm_Database VARCHAR(200) = 'NomeDatabase', @Ds_Caminho_Backup VARCHAR(500) = 'C:\SQLServer\Backup\', @Ds_Email VARCHAR(500) = 'email@dominio.com.br'
	*/
	
	------------------------------------------------------------------------------------------------------------------------
	-- EXECUTA O BACKUP
	------------------------------------------------------------------------------------------------------------------------
	DECLARE @Dt_Inicial DATETIME, @Dt_Final DATETIME
	
	-- Guarda o tempo inicial
	SELECT @Dt_Inicial = GETDATE()

	-- ALTERAR O CAMINHO DO ARQUIVO
	SELECT @Ds_Caminho_Backup = @Ds_Caminho_Backup + @Nm_Database + '_' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(20),GETDATE(),120),'-',''),':',''),' ','_') + '_Dados.bak'

	-- SELECT @Ds_Caminho_Backup
	-- C:\SQLServer\Backup\NomeDatabase_20181015_231502_Dados.bak
	
	BACKUP DATABASE @Nm_Database
	TO DISK = @Ds_Caminho_Backup
	WITH CHECKSUM, INIT, COMPRESSION, COPY_ONLY, STATS = 1	

	-- Envia o Email apenas se o Backup for executado com sucesso
	IF(@@ERROR = 0)
	BEGIN
		-- Guarda o tempo final
		SELECT @Dt_Final = GETDATE()

		------------------------------------------------------------------------------------------------------------------------
		-- ENVIA O EMAIL
		------------------------------------------------------------------------------------------------------------------------
		-- Descrição do Email
		DECLARE @Ds_Email_Body VARCHAR(5000)

		SELECT @Ds_Email_Body = 
		'O Backup foi executado com sucesso!<br/><br/>' + '
		' + '<b>Informações:</b><br/><br/>
		' + '<b>Servidor:</b> '		+ @@SERVERNAME								+ '<br/><br/>' + '
		' + '<b>Database:</b> '		+ @Nm_Database								+ '<br/><br/>' + '
		' + '<b>Caminho:</b> '		+ @Ds_Caminho_Backup						+ '<br/><br/>' + '
		' + '<b>Data Inicial:</b> ' + CONVERT(VARCHAR(20), @Dt_Inicial, 120)	+ '<br/><br/>' + '
		' + '<b>Data Final:</b> '	+ CONVERT(VARCHAR(20), @Dt_Final, 120)		+ '<br/><br/>' + '
		' + '<b>Duração:</b>
		' + RIGHT('00' + CAST( (DATEDIFF(SECOND, @Dt_Inicial, @Dt_Final) / 3600) AS VARCHAR(2)), 2) + ' Hora(s) ' +
			RIGHT('00' + CAST( (DATEDIFF(SECOND, @Dt_Inicial, @Dt_Final) / 60 % 60) AS VARCHAR(2)), 2) + ' Minuto(s) ' +
			RIGHT('00' + CAST( (DATEDIFF(SECOND, @Dt_Inicial, @Dt_Final) % 60) AS VARCHAR(2)), 2) + ' Segundo(s) ' + '<br/><br/><br/>' +

		-- Inclui um logo da empresa no final do e-mail
		'<a href="http://www.fabriciolima.net" target=”_blank”> 
			<img	src="http://www.fabriciolima.net/wp-content/uploads/2016/04/Logo_Fabricio-Lima_horizontal.png"
					height="100" width="400"/>
		</a>'

		EXEC msdb.dbo.sp_send_dbmail    
				@profile_name = 'MSSQLServer',	
				@recipients = @Ds_Email,
				@subject = '[Banco de Dados] Solicitação Backup' ,    
				@body = @Ds_Email_Body,    
				@body_format = 'HTML'
	END	
END

GO

USE [msdb]
GO

/****** Object:  Operator [Alerta_BD]    Script Date: 21/10/2018 23:42:09 ******/
IF NOT EXISTS ( SELECT * FROM msdb.dbo.sysoperators WHERE NAME = 'Alerta_BD' )
BEGIN	
	EXEC msdb.dbo.sp_add_operator @name=N'Alerta_BD', 
			@enabled=1, 
			@weekday_pager_start_time=90000, 
			@weekday_pager_end_time=180000, 
			@saturday_pager_start_time=90000, 
			@saturday_pager_end_time=180000, 
			@sunday_pager_start_time=90000, 
			@sunday_pager_end_time=180000, 
			@pager_days=0, 
			@email_address=N'operator@dominio.com.br', 
			@category_name=N'[Uncategorized]'
END

GO

USE [msdb]
GO

/****** Object:  Job [DBA - Solicitação Backup]    Script Date: 21/10/2018 22:50:38 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 21/10/2018 22:50:38 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Solicitação Backup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Executa uma solicitação de Backup Avulso.

OBS: Verificar os parâmetros:
- Nome da Database
- Caminho do Arquivo
- Emails de Destinatário', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Alerta_BD', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [EXECUTA BACKUP AVULSO]    Script Date: 21/10/2018 22:50:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'EXECUTA BACKUP AVULSO', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC stpBackup_Avulso_Email ''NomeDatabase'', ''C:\SQLServer\Backup\'',''email@dominio.com.br;email2@dominio.com.br''', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'BACKUP AVULSO', 
		@enabled=0, 
		@freq_type=1, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181019, 
		@active_end_date=99991231, 
		@active_start_time=235000, 
		@active_end_time=235959, 
		@schedule_uid=N'89542bc1-0717-4d66-a37f-af0abe1ebdef'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO