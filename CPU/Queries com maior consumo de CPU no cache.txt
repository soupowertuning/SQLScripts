--Queries do Cache com maior consumo de CPU
if object_id('tempdb..#Temp_Trace') is not null drop table #Temp_Trace

sELECT TOP 50 total_worker_time ,  sql_handle,execution_count,last_execution_time,last_worker_time
into #Temp_Trace
FROM sys.dm_exec_query_stats A
where last_elapsed_time > 20
 and last_execution_time > dateadd(ss,-600,getdate()) --ultimos 5 min
order by A.total_worker_time desc

select distinct A.*, B.*, DB.name
from #Temp_Trace A
cross apply sys.dm_exec_sql_text (sql_handle) B
join sys.databases DB on B.dbid = DB.database_id
order by 1 DESC
