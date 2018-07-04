
/*

Use Traces
--conferir se ja tem o log criado
select max(Dt_Registro) from Historico_Permissoes

-- Nivel de servidor
select name,* from sys.syslogins
where sysadmin = 1
and status = 9

use Traces
--nivel de base
select @@servername, name,Nm_Database,DbRole
 from Historico_Permissoes
where Dt_Registro = '20180704'
--and DbRole = 'db_owner'  
and (Nm_Database is not null) 
order by name,Nm_Database,DbRole desc

--nivel objeto
select  @@servername,  grantor,Grantee ,Name_DB, Permission,Type_Desc,Obj_Name
from Historico_Permissoes_Objetos
where Dt_Registro = '20180704'
order by grantor,Grantee ,Name_DB, Permission,Type_Desc,Obj_Name
*/

Use Traces
GO
if object_id('Historico_Permissoes') is not null
	drop table Historico_Permissoes
GO
CREATE TABLE [dbo].[Historico_Permissoes](
	[name] [varchar](250) NOT NULL,
	[sysadmin] [int] NULL,
	[isntgroup] [int] NULL,
	[Nm_Database] [varchar](250) NULL,
	[DbRole] [varchar](250) NULL,
	[create_date] [datetime] NULL,
	[Dt_Registro] [date] DEFAULT (getdate()) 
) ON [PRIMARY]

GO
if object_id('stpHistorico_Permissoes') is not null
	drop procedure stpHistorico_Permissoes
GO
			
				CREATE procedure stpHistorico_Permissoes
				AS
				BEGIN
					--Criação de uma tabela auxiliar que armazena as permissões correntes dos usuários
							if OBJECT_ID('tempdb..##Permissoes') is not null
								drop table ##Permissoes
						
								CREATE TABLE [dbo].##Permissoes(
										[name] [sysname] NOT NULL,
										[sysadmin] [int] NULL,
										[isntgroup] [int] NULL,
										[Nm_Database] [nvarchar](128) NULL,
										[DbRole] [sysname] NULL,
										[create_date] [datetime] NULL,
										[MemberSID] [varbinary](85) NULL
								) ON [PRIMARY]
							    
							--Query que popula a tabela _Permissoes com as permissões de todos os logins das databases
							exec sp_MSforeachdb '
							Use [?]
							insert into ##Permissoes
							select L.name, L.sysadmin, L.isntgroup, U.Nm_Database,U.DbRole, U.create_date, U.MemberSID    
							from sys.syslogins L
								left join   (select DB_NAME() as Nm_Database,DbRole = g.name, MemberName = u.name, u.create_date, MemberSID = u.sid
												 from sys.database_principals u 
													   join sys.database_role_members m on u.principal_id = m.member_principal_id
													   join sys.database_principals g on g.principal_id = m.role_principal_id) as U
											 on L.name collate SQL_Latin1_General_CP1_CI_AI = U.MemberName
								left join ##Permissoes C on C.name = L.name and isnull(C.Nm_Database,'''') = isnull(U.Nm_Database,'''')
							where L.name not like (''##MS_%'') and C.name is null
						
							'

			
							--Populando a tabela que armazena o historico das permissões de todos os usuários
							insert into [dbo].[Historico_Permissoes] (name,sysadmin,isntgroup,Nm_Database,DbRole,create_date)
							select A.name, A.sysadmin, A.isntgroup, A.Nm_Database, A.DbRole, A.create_date
							from (
							select name, sysadmin, isntgroup, Nm_Database, DbRole, create_date
							from ##Permissoes
							where Nm_Database is not null
							union
							select name, sysadmin, isntgroup, Nm_Database, DbRole, create_date
							from ##Permissoes
							where name not in (select name from _Permissoes where Nm_Database is not null)
							and (sysadmin = 1 or Nm_Database is not null)
							 ) A
								left join [Historico_Permissoes] B on A.name = B.name and B.Dt_Registro = CAST(getdate() as DATE)
							where B.name is null					
							
				END


GO
if object_id('Historico_Permissoes_Objetos') is not null
	drop table Historico_Permissoes_Objetos
GO
CREATE TABLE [dbo].[Historico_Permissoes_Objetos](
	[Name_DB] [varchar](250) NULL,
	[Permission] [varchar](100) NULL,
	[Type_Desc] [varchar](500) NULL,
	[Obj_Name] [varchar](500) NULL,
	[Grantor] [varchar](500) NULL,
	[Grantee] [varchar](500) NULL,
	[Dt_Registro] [date] DEFAULT (getdate()) NULL
) ON [PRIMARY]

GO


if object_id('stpHistorico_Permissoes_Objetos') is not null
	drop procedure stpHistorico_Permissoes_Objetos
GO

CREATE procedure stpHistorico_Permissoes_Objetos
AS
begin

	if OBJECT_ID('tempdb..##Historico_Permissoes_Objetos') is not null drop table ##Historico_Permissoes_Objetos

	CREATE TABLE ##Historico_Permissoes_Objetos(
		[Name_DB] [varchar](100) NULL,
		[Permission] [varchar](100) NULL,
		[Type_Desc] [varchar](500) NULL,
		[Obj_Name] [varchar](500) NULL,
		[Grantor] [varchar](500) NULL,
		[Grantee] [varchar](500) NULL,
		[Dt_Registro] [date] NULL
	) ON [PRIMARY]

	DECLARE @ndbs TINYINT, @i TINYINT, @database VARCHAR(50), @tsql NVARCHAR(MAX);
	DECLARE @tab table(Id TINYINT IDENTITY(1,1), Nome VARCHAR(30))

	SELECT @ndbs = COUNT(*) FROM sys.databases where name not in ('model','tempdb') and state_desc='ONLINE'
	insert into @tab SELECT name FROM sys.databases 
	where name not in ('model','tempdb') and state_desc='ONLINE'


	SET @i = 1;
	WHILE (@i <= @ndbs)
	BEGIN
		  SELECT @database = Nome	FROM @tab      WHERE Id = @i
			
		  SET @tsql = N'
		insert into ##Historico_Permissoes_Objetos (Name_DB,Permission,Type_Desc,Obj_Name,Grantor,Grantee)
		SELECT ''' + @database + ''', prmssn.permission_name AS [Permission], 
			sp.type_desc, sp.name, grantor_principal.name AS [Grantor], grantee_principal.name AS [Grantee] 
				FROM [' + @database + '].sys.all_objects AS sp 
				INNER JOIN [' + @database + '].sys.database_permissions AS prmssn 
					ON prmssn.major_id=sp.object_id AND prmssn.minor_id=0 AND prmssn.class=1 
				INNER JOIN [' + @database + '].sys.database_principals AS grantor_principal 
					ON grantor_principal.principal_id = prmssn.grantor_principal_id 
				INNER JOIN [' + @database + '].sys.database_principals AS grantee_principal 
					ON grantee_principal.principal_id = prmssn.grantee_principal_id 
				WHERE (SCHEMA_NAME(sp.schema_id)=''dbo'') 
				ORDER BY sp.type';
	      
		  EXEC sp_executesql @tsql;
		  SET @i = @i + 1;
	END

	insert into Historico_Permissoes_Objetos (Name_DB,Permission,Type_Desc,Obj_Name,Grantor,Grantee)
	select A.Name_DB,A.Permission,A.Type_Desc,A.Obj_Name,A.Grantor,A.Grantee 
	from ##Historico_Permissoes_Objetos A
		left join Historico_Permissoes_Objetos B on A.Name_DB = B.Name_DB and A.Permission  = B.Permission
			and A.Type_Desc = B.Type_Desc and A.Obj_Name = B.Obj_Name and A.Grantor = B.Grantor and A.Grantee  = B.Grantee
			and CAST(getdate() as DATE) = B.Dt_Registro
	where B.Name_DB is null

END

GO
	
USE [msdb]
GO

/****** Object:  Job [DBA - Carga Histórico Acessos Databases]    Script Date: 04/27/2014 13:20:08 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 04/27/2014 13:20:08 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Historico de Permissoes', 
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
/****** Object:  Step [DBA - Carga Histórico Acessos Databases]    Script Date: 04/27/2014 13:20:08 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - Historico de Permissoes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec stpHistorico_Permissoes_Objetos

exec stpHistorico_Permissoes', 
		@database_name=N'Traces', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Carga Acesso Databases', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20140427, 
		@active_end_date=99991231, 
		@active_start_time=12500, 
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








