WITH DB_CPU_Statistics
AS
(SELECT pa.DatabaseID, DB_NAME(pa.DatabaseID) AS [Database Name], SUM(qs.total_worker_time/1000) AS [CPU_Time_Ms]
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY (SELECT CONVERT(INT, value) AS [DatabaseID]
FROM sys.dm_exec_plan_attributes(qs.plan_handle)
WHERE attribute = N'dbid') AS pa
GROUP BY DatabaseID)
SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [CPU Ranking],
[Database Name], [CPU_Time_Ms] AS [CPU Time (ms)],
CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPU Percent]
FROM DB_CPU_Statistics
WHERE DatabaseID <> 32767 -- ResourceDB
ORDER BY [CPU Ranking] OPTION (RECOMPILE);