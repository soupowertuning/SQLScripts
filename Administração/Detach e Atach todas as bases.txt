--detach de todas as bases
select
'if exists (select name
			from sys.databases 
			where State_Desc = ''ONLINE''
			and name = '''+A.Name+''' )
BEGIN
	ALTER DATABASE '+A.Name+' 
	SET SINGLE_USER WITH ROLLBACK IMMEDIATE 

	exec sp_detach_db '+A.Name+'		
END'
from sys.sysdatabases A 
where A.Name not in ('tempdb','master','model','msdb')



--Attach de todas as databases selecionadas
select 'if not exists (select name from sys.databases where State_Desc = ''ONLINE'' and name = '''+a.name+''' )
	BEGIN CREATE DATABASE '+a.name+'
		ON 
		(FILENAME = ''' + a.filename + '''), 
		(FILENAME = '''+ b.filename + ''') '
		+ case when C.fileid is null then '' else ',(FILENAME = '''+ C.filename + ''')  'end +
		' FOR ATTACH
	END',
				a.name, a.filename,b.name as 'Logical filename', b.filename 
from sys.sysdatabases a 
	join sys.sysaltfiles b on a.dbid = b.dbid 
	left join sys.sysaltfiles C on a.dbid = C.dbid and C.fileid = 3 
where b.fileid = 2  and a.Name not in ('tempdb','master','model','msdb')

