
--Compilação
-- Query demorada se tiver muita memória. Rodar em horário mais tranquilo 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH XMLNAMESPACES 
(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT TOP 10
CompileTime_ms,
CompileCPU_ms,
CompileMemory_KB,
qs.execution_count,
qs.total_elapsed_time/1000 AS duration_ms,
qs.total_worker_time/1000 as cputime_ms,
(qs.total_elapsed_time/qs.execution_count)/1000 AS avg_duration_ms,
(qs.total_worker_time/qs.execution_count)/1000 AS avg_cputime_ms,
qs.max_elapsed_time/1000 AS max_duration_ms,
qs.max_worker_time/1000 AS max_cputime_ms,
SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
(CASE qs.statement_end_offset
WHEN -1 THEN DATALENGTH(st.text)
ELSE qs.statement_end_offset
END - qs.statement_start_offset) / 2 + 1) AS StmtText,
query_hash,
query_plan_hash
FROM
(
SELECT 
c.value('xs:hexBinary(substring((@QueryHash)[1],3))', 'varbinary(max)') AS QueryHash,
c.value('xs:hexBinary(substring((@QueryPlanHash)[1],3))', 'varbinary(max)') AS QueryPlanHash,
c.value('(QueryPlan/@CompileTime)[1]', 'int') AS CompileTime_ms,
c.value('(QueryPlan/@CompileCPU)[1]', 'int') AS CompileCPU_ms,
c.value('(QueryPlan/@CompileMemory)[1]', 'int') AS CompileMemory_KB,
qp.query_plan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
CROSS APPLY qp.query_plan.nodes('ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS n(c)
) AS tab
JOIN sys.dm_exec_query_stats AS qs
ON tab.QueryHash = qs.query_hash
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY CompileTime_ms DESC
OPTION(RECOMPILE, MAXDOP 1);