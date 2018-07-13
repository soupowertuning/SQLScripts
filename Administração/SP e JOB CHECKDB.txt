
/*
--Instruções de Uso

Alterar o profile e e-mail para receber a notificação do checkdb
	@profile_name = 'MSSQLServer',
	@recipients = 'seuemail@dominio.com.br',
	
	--Se o operator for diferente de Alerta_BD, tem que alterar.

*/

Use Traces
GO

-- esse alerta deve ser executado logo após o insert do job de traces (codigo na aba de testes alertas)
if object_id('stpCHECKDB_Databases') is not null
	drop procedure stpCHECKDB_Databases
GO

CREATE PROCEDURE [dbo].[stpCHECKDB_Databases]
AS
BEGIN

declare @Databases table(Id_Database int identity(1,1), Nm_Database varchar(50))

declare @Total int, @Loop int, @Nm_Database varchar(50)
insert into @Databases(Nm_Database)
select name
from master.sys.databases
where name not in ('tempdb')  -- Caso não deseje fazer o check de algua database
and state_desc = 'ONLINE'

select @Total = max(Id_Database)
from @Databases

set @Loop = 1

while (@Loop <= @Total)
begin

	select @Nm_Database = Nm_Database
	from @Databases
	where Id_Database = @Loop

	DBCC CHECKDB(@Nm_Database) WITH NO_INFOMSGS 
	set @Loop = @Loop + 1
end 
END
GO

if OBJECT_ID('stpAlerta_CheckDB') is not null 
drop procedure stpAlerta_CheckDB
GO
CREATE procedure stpAlerta_CheckDB
AS

	if OBJECT_ID('tempdb..#TempLog') is not null drop table #TempLog
	
	CREATE TABLE #TempLog (
		  LogDate     DATETIME,
		  ProcessInfo NVARCHAR(50),
		  [Text] NVARCHAR(MAX))

	if OBJECT_ID('tempdb..#logF') is not null drop table #logF
	
	CREATE TABLE #logF (
		  ArchiveNumber     INT,
		  LogDate           DATETIME,
		  LogSize           INT )

	-- Seleciona o número de arquivos.
	INSERT INTO #logF  
	EXEC sp_enumerrorlogs

	DECLARE @TSQL  NVARCHAR(2000)
	DECLARE @lC    INT

	SELECT @lC = MIN(ArchiveNumber) FROM #logF

	--Loop para realizar a leitura de todo o log
	WHILE @lC IS NOT NULL
	BEGIN
		  INSERT INTO #TempLog
		  EXEC sp_readerrorlog @lC
		  SELECT @lC = MIN(ArchiveNumber) FROM #logF
		  WHERE ArchiveNumber > @lC
	END

	if object_id('_Result_Corrupcao') is not null
		drop table _Result_Corrupcao
		
	select LogDate,SUBSTRING(Text,charindex('found',Text),(charindex('Elapsed time',Text)-charindex('found',Text)))  Erros ,   Text 
	into _Result_Corrupcao
	from #TempLog
	where LogDate >= getdate()-1 
		--and LogDate < cast(floor(cast(getdate() as float)) as datetime)	 
		and Text like '%DBCC CHECKDB (%'
		and Text not like '%IDR%'
		and substring(Text,charindex('found',Text), charindex('Elapsed time',Text) - charindex('found',Text)) <> 'found 0 errors and repaired 0 errors.'
	-- leitura do log do dia anterior

	if exists (		select null from _Result_Corrupcao 	)
		EXEC msdb.dbo.sp_send_dbmail
				@Profile_Name = 'MSSQLServer',
				@Recipients =	'seuemail@dominio.com.br',
				@query = 'select LogDate,Erros,Text from Traces.dbo._Result_Corrupcao',
				@subject = 'ALERTA: Existe uma base que está corrompida no Banco de Dados. Verifique com urgência!';									
				
	if object_id('_Result_Corrupcao') is not null
		drop table _Result_Corrupcao

GO

USE [msdb]
GO

/****** Object:  Job [DBA - CHECKDB Databases]    Script Date: 08/30/2016 21:18:11 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 08/30/2016 21:18:11 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - CHECKDB Databases', 
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
/****** Object:  Step [DBA - CheckDB Databases]    Script Date: 08/30/2016 21:18:11 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - CheckDB Databases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec stpCHECKDB_Databases', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ALERTA CORRUPÇÂO DATABASES]    Script Date: 08/30/2016 21:18:11 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ALERTA CORRUPÇÂO DATABASES', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec stpAlerta_CheckDB', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA - CheckDB Databases', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140208, 
		@active_end_date=99991231, 
		@active_start_time=20000, 
		@active_end_time=235959, 
		@schedule_uid=N'b9f3e0d0-af0c-4485-a571-31c31b20c29f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


