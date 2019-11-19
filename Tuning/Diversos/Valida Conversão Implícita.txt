SELECT TOP ( 50 )
    DB_NAME(B.[dbid]) AS [Database],
    B.[text] AS [Consulta],
    A.total_worker_time AS [Total Worker Time],
    A.total_worker_time / A.execution_count AS [Avg Worker Time],
    A.max_worker_time AS [Max Worker Time],
    A.total_elapsed_time / A.execution_count AS [Avg Elapsed Time],
    A.max_elapsed_time AS [Max Elapsed Time],
    A.total_logical_reads / A.execution_count AS [Avg Logical Reads],
    A.max_logical_reads AS [Max Logical Reads],
    A.execution_count AS [Execution Count],
    A.creation_time AS [Creation Time],
    C.query_plan AS [Query Plan]
FROM
    sys.dm_exec_query_stats AS A WITH ( NOLOCK )
    CROSS APPLY sys.dm_exec_sql_text(A.plan_handle) AS B
    CROSS APPLY sys.dm_exec_query_plan(A.plan_handle) AS C
WHERE
    CAST(C.query_plan AS NVARCHAR(MAX)) LIKE ( '%CONVERT_IMPLICIT%' )
    AND B.[dbid] = DB_ID()
    AND B.[text] NOT LIKE '%sys.dm_exec_sql_text%' -- Não pegar a própria consulta
ORDER BY
    A.total_worker_time DESC