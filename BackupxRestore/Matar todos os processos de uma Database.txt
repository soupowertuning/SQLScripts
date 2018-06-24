Declare @SpId as varchar(5)

select Cast(spid as varchar(5))SpId
into #Processos
from master.dbo.sysprocesses A
     join master.dbo.sysdatabases B on A.DbId= B.DbId
where B.Name = 'FabricioLima'

while(select count(*) from #Processos) >0
begin
     set @SpId =(select top 1 SpID from #Processos)
  exec ('Kill '+      @SpId)
     delete from #Processos where SpID = @SpId
end