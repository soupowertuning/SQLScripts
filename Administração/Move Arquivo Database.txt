-- https://technet.microsoft.com/en-us/library/gg452698.aspx

USE master 

-- 1. Busca o nome logico e o caminho dos arquivos de dados e log associados a database:
SELECT name, physical_name 
FROM sys.master_files 
WHERE database_id = DB_ID('TESTE_LUIZ');

-- Verifica o status da database
SELECT name, state_desc
FROM sys.databases
WHERE name = 'TESTE_LUIZ'


-- 2. Verificar se existe alguma conexão na database. Se existir, deve fazer matar com o KILL.
Declare @SpId as varchar(5)

if(OBJECT_ID('tempdb..#Processos') is not null) drop table #Processos

select Cast(spid as varchar(5))SpId
into #Processos
from master.dbo.sysprocesses A
 join master.dbo.sysdatabases B on A.DbId = B.DbId
where B.Name ='TESTE_LUIZ'

-- select * from #Processos

-- Mata as conexões
while (select count(*) from #Processos) >0
begin
 set @SpId = (select top 1 SpID from #Processos)
   exec ('Kill ' +  @SpId)
 delete from #Processos where SpID = @SpId
end


-- 3. Altera o status da database para OFFLINE:
ALTER DATABASE TESTE_LUIZ SET OFFLINE


-- 4. Mova o arquivo (*.mdf, *.ldf, *.ndf) para o novo local e altere o FILENAME para o novo caminho
-- *.mdf
ALTER DATABASE TESTE_LUIZ MODIFY FILE ( NAME = TESTE_LUIZ, FILENAME = 'C:\Luiz Vitor\Novo Caminho\TESTE_LUIZ.mdf')

-- *.ldf
ALTER DATABASE TESTE_LUIZ MODIFY FILE ( NAME = TESTE_LUIZ_log, FILENAME = 'C:\Luiz Vitor\Novo Caminho\TESTE_LUIZ_log.ldf')


-- 5. Altera o status da database para ONLINE:
ALTER DATABASE TESTE_LUIZ SET ONLINE


-- Conferindo o resultado após a alteração
USE master 

-- Local dos arquivos
SELECT name, physical_name 
FROM sys.master_files 
WHERE database_id = DB_ID('TESTE_LUIZ');

-- Verifica o status da database
SELECT name, state_desc
FROM sys.databases
WHERE name = 'TESTE_LUIZ'