USE Traces

GO

-- Cria a tabela de Historico
CREATE TABLE [dbo].[Medicao_IOPS](
    ID_Medicao_IOPS bigint identity,
    [Data] [datetime] NOT NULL,
    [IO] [bigint] NULL,
    [TAXA] [bigint] NULL
) ON [PRIMARY]
 
-- Cria indice para melhorar o desempenho
CREATE CLUSTERED INDEX SK01_Medicao_IOPS on Medicao_IOPS(Id_Medicao_IOPS)

GO
      
USE [msdb]
GO

/****** Object:  Job [DBA - Histórico Contador - IOPS]    Script Date: 06/27/2017 16:13:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 06/27/2017 16:13:28 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Histórico Contador - IOPS', 
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
/****** Object:  Step [Insere Historico]    Script Date: 06/27/2017 16:13:28 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Insere Historico', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Insere os dados na tabela de historico
INSERT INTO Traces..Medicao_IOPS(Data, IO, Taxa)
SELECT  GETDATE() Data, 
		SUM(num_of_reads + num_of_writes) AS IO,
		SUM(num_of_bytes_read + num_of_bytes_written) AS TAXA        
FROM sys.dm_io_virtual_file_stats(null,null) IVFS

/*
-- P/ COMPARAR DEPOIS
select	TOP 1000 
		(A.IO - B.IO)/DATEDIFF(ss,B.Data,A.Data) IOPS,
		(A.TAXA - B.TAXA)/DATEDIFF(ss,B.Data,A.Data)/1024/1024.00 TAXA_MBs,
		A.Data,B.Data,A.Id_medicao_iops , B.Id_medicao_iops
from Traces..Medicao_IOPS A
join Traces..Medicao_IOPS B on A.Id_Medicao_IOPS = B.Id_Medicao_IOPS + 1
order by A.Id_medicao_iops desc
*/', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DIÁRIO - A CADA 10 SEGUNDOS', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=2, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20170627, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=180000
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
-- P/ COMPARAR DEPOIS
select	TOP 1000 
		(A.IO - B.IO)/DATEDIFF(ss,B.Data,A.Data) IOPS,
		(A.TAXA - B.TAXA)/DATEDIFF(ss,B.Data,A.Data)/1024/1024.00 TAXA_MBs,
		A.Data,B.Data,A.Id_medicao_iops , B.Id_medicao_iops
from Traces..Medicao_IOPS A
join Traces..Medicao_IOPS B on A.Id_Medicao_IOPS = B.Id_Medicao_IOPS + 1
order by A.Id_medicao_iops desc
*/


/*
DECLARE @SQLRestartDateTime Datetime, @TimeInSeconds Float

SELECT @SQLRestartDateTime = create_date FROM sys.databases WHERE database_id = 2

SET @TimeInSeconds = Datediff(s,@SQLRestartDateTime,GetDate())

SELECT   DB_NAME(IVFS.database_id) AS DatabaseName
   , MF.type_desc AS FileType
   , MF.name AS VirtualFileName
   , MF.Physical_Name AS StorageLocation
   , ROUND((num_of_reads + num_of_writes)/@TimeInSeconds,4) AS IOPS
   , ROUND((num_of_bytes_read + num_of_bytes_written)/@TimeInSeconds,2)/1024 AS MBPS
FROM sys.dm_io_virtual_file_stats(null,null) IVFS
JOIN sys.master_files MF ON IVFS.database_id = MF.database_id AND IVFS.file_id = MF.file_id
ORDER BY DatabaseName ASC, VirtualFileName ASC


SELECT   DB_NAME(IVFS.database_id) AS DatabaseName
   , ROUND((SUM(num_of_reads + num_of_writes))/@TimeInSeconds,4) AS IOPS
   , ROUND((SUM(num_of_bytes_read + num_of_bytes_written))/@TimeInSeconds,2) AS BPS
FROM sys.dm_io_virtual_file_stats(null,null) IVFS
GROUP BY db_name(IVFS.database_id)
ORDER BY DatabaseName ASC


SELECT   ROUND((SUM(num_of_reads + num_of_writes))/@TimeInSeconds,4) AS IOPS
   , ROUND((sum(num_of_bytes_read + num_of_bytes_written))/@TimeInSeconds,2)/1024/1024 AS MBPS
FROM sys.dm_io_virtual_file_stats(null,null) IVFS


SELECT
    SUM((IVFS.num_of_reads + IVFS.num_of_writes)/(IVFS.io_stall*1.00/1000)) as [Avg IO/s]
FROM
    sys.dm_io_virtual_file_stats(null,null) IVFS
   
   
select * from sys.dm_os_query_Stats
    
        
SELECT
    SUM((IVFS.num_of_reads + IVFS.num_of_bytes_written)/IVFS.io_stall) as [Avg IO/s]
FROM
    sys.dm_io_virtual_file_stats(null,null) IVFS
*/