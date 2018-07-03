-- Missing Index
-- Query de missed index que já vem o tamanho da tabela

SELECT 
	dm_mid.database_id AS DatabaseID,
	dm_migs.avg_user_impact*(dm_migs.user_seeks+dm_migs.user_scans) Avg_Estimated_Impact,
	dm_migs.last_user_seek AS Last_User_Seek,
	OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) AS [TableName],
	'CREATE NONCLUSTERED INDEX ['
	+ OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) +'W01]'+
	' ON ' + dm_mid.statement+ ' (' + ISNULL (dm_mid.equality_columns,'')
	+ CASE WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns IS NOT NULL THEN ',' ELSE'' END
	+ ISNULL (dm_mid.inequality_columns, '')
	+ ')'+ ISNULL (' INCLUDE (' + dm_mid.included_columns + ')', '') + ' WITH(FILLFACTOR=90)'AS Create_Statement,dm_migs.user_seeks,dm_migs.user_scans,
	X.rowcnt,X.tamanho
FROM sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs ON dm_migs.group_handle = dm_mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid ON dm_mig.index_handle = dm_mid.index_handle
LEFT JOIN (
  select object_name(id) Nome_Tabela,rowcnt,dpages*8 as tamanho from sysindexes
  where indid in (1,0) and objectproperty(id,'isusertable')=1
   ) X on OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) = X.Nome_Tabela
WHERE 
	dm_mid.database_ID = DB_ID()
	--and dm_migs.last_user_seek >= '20180101
ORDER BY Avg_Estimated_Impact DESC
