--Script para verificar o caminho dos arquivos de dados e logs das databases
select a.name, b.name as 'Logical filename', b.filename 
from sys.sysdatabases a 
	inner join sys.sysaltfiles b on a.dbid = b.dbid 
order by A.name
