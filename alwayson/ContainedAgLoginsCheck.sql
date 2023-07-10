/*
  Este script foi criado como uma POC no vídeo da PowerTuning sobre Contained Availability Groups
  Ele usa o linkd server para conectar no ambiente de cada AG e exibe em quais ambientes um login existe ou não existe
  O script é livre para usar, mas, lembre-se de manter os créditos para a PowerTuning.
  Vídeo: https://www.youtube.com/watch?v=8uCDl1zIrBY
*/

DECLARE
	@LinkedName nvarchar(500) = '_ContainedAgCheck'



DROP TABLE IF EXISTS #AgList;

-- Get all contained ag 
select 
	 AgName				= ag.name 
	 ,PrimaryReplica	= r.replica_server_name
	 ,Seq = IDENTITY(int,1,1)
into 
	#AgList
from 
	sys.availability_groups AS ag 
	INNER JOIN  
	sys.dm_hadr_availability_replica_states AS ars 
		ON ag.group_id = ars.group_id 
	INNER JOIN
	sys.availability_replicas r
		on r.replica_id = ars.replica_id
WHERE
	ag.is_contained = 1
	and 
	ars.role = 1

declare
	@exec nvarchar(200)
	,@Seq int =0
	,@col_AgName nvarchar(300)
	,@AgMaster nvarchar(200)
	,@ServerName sysname

set @exec = @LinkedName+'...sp_executesql';

set @Seq = 0;
set @ServerName = @@SERVERNAME;


DROP TABLE IF EXISTS #Logins;

CREATE TABLE #Logins (
	LoginName sysname
	,LoginSid varbinary(max)
	,ServerList nvarchar(max)
)	

DROP TABLE IF EXISTS #AgLogins;
select * into #AgLogins from #Logins

-- Careega todos os logins do srver atual!
INSERT INTO #Logins(LoginName,LoginSid,ServerList)
select name,sid,@@SERVERNAME from sys.sql_logins;


WHILE 1 = 1
BEGIN

	select top 1
		@Seq = Seq
		,@col_AgName = AgName
		,@AgMaster = AgName+'_master'
	from
		#AgList
	where
		Seq > @Seq
	ORDER BY
		Seq 
	IF @@ROWCOUNT = 0
		BREAK;


	-- Recreate temporary linked server
	if exists(select * from sys.servers where name = @LinkedName)
		exec master.dbo.sp_dropserver @LinkedName,'droplogins'


	EXEC master.dbo.sp_addlinkedserver
		@server = @LinkedName, 
		@srvproduct=N'',
		@provider=N'SQLNCLI',
		@datasrc=@ServerName,
		@catalog=@AgMaster
		,@provstr='APP=ScriptContainedAgCheck'

	EXEC master.dbo.sp_serveroption @server=@LinkedName, @optname=N'data access', @optvalue=N'true'
	EXEC master.dbo.sp_serveroption @server=@LinkedName, @optname=N'rpc', @optvalue=N'true'
	EXEC master.dbo.sp_serveroption @server=@LinkedName, @optname=N'rpc out', @optvalue=N'true'
	EXEC master.dbo.sp_serveroption @server=@LinkedName, @optname=N'collation compatible', @optvalue=N'false'
	EXEC master.dbo.sp_serveroption @server=@LinkedName, @optname=N'remote proc transaction promotion', @optvalue=N'false';

	
	truncate table #AgLogins;

	insert into #AgLogins(LoginName,LoginSid,ServerList)
	exec @exec N'select name,sid,@AgName from sys.sql_logins'
			,N'@AgName sysname'
			,@AgName = @col_AgName
	;

END


MERGE
	#Logins L
USING
	#AgLogins al
ON
	AL.LoginName = L.LoginName
	AND
	AL.LoginSid = L.LoginSid
WHEN MATCHED THEN 
	UPDATE SET ServerList += ','+AL.ServerList
WHEN NOT MATCHED THEN
	INSERT (LoginName,LoginSid,ServerList) VALUES(AL.LoginName,AL.LoginSid,AL.ServerList)
;

SELECT
	*
FROM
	#Logins
WHERE
	LoginName not like '##%'


