

-- Se o CLERK CACHESTORE_SQLCP tiver usando muita memória, pode retirar essas queries do Cache.
SELECT TOP 1000 *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE cp.cacheobjtype = N'Compiled Plan'
AND cp.objtype = N'Adhoc'
AND cp.usecounts <= 20

-- Para excluir os caches não reutilizados
-- DBCC FREEPROCCACHE (0x06000100512A062F904D420B0902000001000000000000000000000000000000000000000000000000000000)

CREATE procedure stpLimpa_Adhoc_Cache 
AS
BEGIN
	SET NOCOUNT ON

	if object_id('tempdb..#Temp_Trace') is not null
		drop table #Temp_Trace

	SELECT top 1000 IDENTITY(int,1,1) Id , plan_handle,size_in_bytes
	into #Temp_Trace
	FROM sys.dm_Exec_cached_plans AS cp
	WHERE cacheobjtype = 'Compiled Plan' 
		AND cp.objtype = 'Adhoc' 
		AND cp.usecounts < 20
		and size_in_bytes > 1000 -- in bytes
	order by size_in_bytes desc
	
	declare @plan_handle varbinary(64), @Loop int, @Qtd_Registros int

	set @Loop = 1
	select @Qtd_Registros = count(*) from #Temp_Trace

	while @Loop <= @Qtd_Registros
	begin
		select @plan_handle = plan_handle	 
		from #Temp_Trace
		where Id = @Loop
		
		DBCC FREEPROCCACHE (@plan_handle)
		
		set @Loop = @Loop + 1
	end
END