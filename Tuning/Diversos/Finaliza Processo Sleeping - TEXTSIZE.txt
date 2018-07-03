USE [Traces]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[stpFinaliza_Processo_Sleeping]
AS
BEGIN
	SET NOCOUNT ON

	-- Declara as variaveis
	DECLARE	@Dt_Atual DATETIME, @Qt_Tempo_Textsize INT

	-- Quantidade em Minutos
	SELECT @Qt_Tempo_Textsize = 3	
	
	-- Seta a hora atual
	SELECT @Dt_Atual = GETDATE()		

	--------------------------------------------------------------------------------------------------------------------------------
	--	Cria Tabela para armazenar os Dados da SP_WHOISACTIVE
	--------------------------------------------------------------------------------------------------------------------------------
	-- Cria a tabela que ira armazenar os dados dos processos
	IF ( OBJECT_ID('tempdb..#Resultado_WhoisActive') IS NOT NULL )
		DROP TABLE #Resultado_WhoisActive
		
	CREATE TABLE #Resultado_WhoisActive (		
		[dd hh:mm:ss.mss]		VARCHAR(20),
		[database_name]			NVARCHAR(128),		
		[login_name]			NVARCHAR(128),
		[host_name]				NVARCHAR(128),
		[start_time]			DATETIME,
		[status]				VARCHAR(30),
		[session_id]			INT,
		[blocking_session_id]	INT,
		[wait_info]				VARCHAR(MAX),
		[open_tran_count]		INT,
		[CPU]					VARCHAR(MAX),
		[reads]					VARCHAR(MAX),
		[writes]				VARCHAR(MAX),		
		[sql_command]			XML		
	)   

	--------------------------------------------------------------------------------------------------------------------------------
	--	Carrega os Dados da SP_WHOISACTIVE
	--------------------------------------------------------------------------------------------------------------------------------
	-- Retorna todos os processos que estão sendo executados no momento
	EXEC [dbo].[sp_WhoIsActive]
			@get_outer_command =	1,
			@output_column_list =	'[dd hh:mm:ss.mss][database_name][login_name][host_name][start_time][status][session_id][blocking_session_id][wait_info][open_tran_count][CPU][reads][writes][sql_command]',
			@destination_table =	'#Resultado_WhoisActive'
				    
	-- Altera a coluna que possui o comando SQL
	ALTER TABLE #Resultado_WhoisActive
	ALTER COLUMN [sql_command] VARCHAR(MAX)
	
	UPDATE #Resultado_WhoisActive
	SET [sql_command] = REPLACE( REPLACE( REPLACE( REPLACE( CAST([sql_command] AS VARCHAR(1000)), '<?query --', ''), '--?>', ''), '&gt;', '>'), '&lt;', '')
	
	-- select * from #Resultado_WhoisActive
	
	-- Verifica se existe algum processo executando a mais de 3 minutos com o TEXTSIZE, com alguma transação aberta e o estado "sleeping"
	if OBJECT_ID('tempdb..#Processos_Textsize') is not null
		drop table #Processos_Textsize
		
	select	[dd hh:mm:ss.mss], [database_name], [login_name], [host_name], [start_time], [status], [session_id], 
			[blocking_session_id], [wait_info], [open_tran_count], [CPU], [reads], [writes], [sql_command] 
	INTO #Processos_Textsize
	from #Resultado_WhoisActive
	where	sql_command like '%SET TEXTSIZE %'
			and open_tran_count > 0
			and status = 'sleeping'
			and datediff(second,Start_time, @Dt_Atual) > @Qt_Tempo_Textsize * 60
	
	-- select * from #Processos_Textsize
	
	-- Verifica existe algum processo com TEXTSIZE para matar
	IF EXISTS ( SELECT TOP 1 * FROM #Processos_Textsize )
	BEGIN
		-- Guarda um Historico dos Processos
		INSERT INTO dbo.Processos_Finalizados
		SELECT	@Dt_Atual, [dd hh:mm:ss.mss], [database_name], [login_name], [host_name], [start_time], [status], 
				[session_id], [blocking_session_id], [wait_info], [open_tran_count], [CPU], [reads], [writes], [sql_command]  	
		FROM #Processos_Textsize
		
		-- select * from dbo.Processos_Finalizados	
		
		-- Mata o Processo
		Declare @SpId as varchar(5)

		while (select count(*) from #Processos) > 0
		begin			
			select top 1 @SpId = session_id
			from #Processos_Textsize			
			
			exec ('Kill ' + @SpId)

			delete from #Processos_Textsize where session_id = @SpId
		END	
	END
END

GO

USE [msdb]
GO

/****** Object:  Job [DBA - Finaliza Processo Sleeping]    Script Date: 03/27/2017 13:42:54 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 03/27/2017 13:42:54 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Finaliza Processo Sleeping', 
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
/****** Object:  Step [stpFinaliza_Processo_Sleeping]    Script Date: 03/27/2017 13:42:54 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'stpFinaliza_Processo_Sleeping', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec stpFinaliza_Processo_Sleeping', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'stpFinaliza_Processo_Sleeping', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150411, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'223df2d5-a6df-4c15-8d4f-50c37dd47ebf'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO