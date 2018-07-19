
-- queries mais custosas
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;

WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
core AS (
	SELECT
		eqp.query_plan AS [QueryPlan],
		ecp.plan_handle [PlanHandle],
		q.[Text] AS [Statement],
		n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)') AS OptimizationLevel ,
		ISNULL(CAST(n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') as float),0) AS SubTreeCost ,
		ecp.usecounts [UseCounts],
		ecp.size_in_bytes [SizeInBytes]
	FROM
		sys.dm_exec_cached_plans AS ecp
		CROSS APPLY sys.dm_exec_query_plan(ecp.plan_handle) AS eqp
		CROSS APPLY sys.dm_exec_sql_text(ecp.plan_handle) AS q
		CROSS APPLY query_plan.nodes ('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn ( n )
)

SELECT TOP 100
	QueryPlan,
	PlanHandle,
	[Statement],
	OptimizationLevel,
	SubTreeCost,
	UseCounts,
	SubTreeCost * UseCounts [GrossCost],
	SizeInBytes
FROM
	core
ORDER BY
	GrossCost DESC
	--SubTreeCost DESC
