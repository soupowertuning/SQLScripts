-- Estatasticas com mais de 30 dias sem atualização
SELECT  [LastUpdate] = STATS_DATE(object_id, stats_id), 
        [Table] = OBJECT_NAME(object_id), 
        [Statistic] = A.name ,C.rowmodctr, 'UPDATE STATISTICS ' + OBJECT_NAME(object_id) + ' ' + A.name+ ' WITH FULLSCAN'
FROM sys.stats A
	join sys.sysobjects B with(nolock) on A.object_id = B.id
	join sys.sysindexes C with(nolock) on C.id = B.id and A.name = C.Name
WHERE STATS_DATE(object_id, stats_id) < getdate()-30	
--and C.rowmodctr > 1000 
	and substring(OBJECT_NAME(object_id),1,3) not in ('sys','dtp')
	and substring( OBJECT_NAME(object_id) , 1,1) <> '_' -- elimina tabelas temporarias
order by C.rowmodctr desc