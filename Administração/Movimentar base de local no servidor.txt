
--------------------------------------------------------------------------------------------------------------------------------
--		Movimentação de Arquivo
--------------------------------------------------------------------------------------------------------------------------------
--	Para fazer deixar uma base offline é necessário matar todas as conexões que estão utilizando essa base de dados
-- https://technet.microsoft.com/en-us/library/gg452698.aspx

-- 2. Verificar se existe alguma conexão na database. Se existir, deve fazer matar com o KILL.
USE master 
Declare @SpId as varchar(5)

if(OBJECT_ID('tempdb..#Processos') is not null) drop table #Processos

select Cast(spid as varchar(5))SpId
into #Processos
from master.dbo.sysprocesses A
 join master.dbo.sysdatabases B on A.DbId = B.DbId
where B.Name ='TreinamentoDBA'

-- Mata as conexões
while (select count(*) from #Processos) >0
begin
 set @SpId = (select top 1 SpID from #Processos)
   exec ('Kill ' +  @SpId)
 delete from #Processos where SpID = @SpId
end

-- 3. Altera o status da database para OFFLINE:
ALTER DATABASE TreinamentoDBA SET OFFLINE

-- 4. Mova o arquivo (*.mdf, *.ldf, *.ndf) para o novo local e altere o FILENAME para o novo caminho

-- Busca o nome logico e o caminho dos arquivos de dados e log associados a database:
SELECT name, physical_name 
FROM sys.master_files 
WHERE database_id = DB_ID('TreinamentoDBA');

-- *.mdf
ALTER DATABASE TreinamentoDBA MODIFY FILE ( NAME = TreinamentoDBA, FILENAME = 'C:\TEMP\TreinamentoDBA.mdf')

-- *.ldf
ALTER DATABASE TreinamentoDBA MODIFY FILE ( NAME = TreinamentoDBA_log, FILENAME = 'C:\TEMP\TreinamentoDBA_log.ldf')

--Garantir que o usuário do SQL Server tem acesso aos arquivos de dados e logs na nova pasta

-- 5. Altera o status da database para ONLINE:
ALTER DATABASE TreinamentoDBA SET ONLINE

-- Conferindo o resultado após a alteração

-- Local dos arquivos
SELECT name, physical_name 
FROM sys.master_files 
WHERE database_id = DB_ID('TreinamentoDBA');

DBCC CHECKDB('TreinamentoDBA')
