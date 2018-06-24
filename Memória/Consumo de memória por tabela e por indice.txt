
--Memória por índice
SELECT COUNT(*) AS cached_pages_count,COUNT(*)/128.0000 MB,
name AS BaseTableName, IndexName,
IndexTypeDesc
FROM sys.dm_os_buffer_descriptors AS bd
	INNER JOIN	(
				SELECT s_obj.name, s_obj.index_id,
				s_obj.allocation_unit_id, s_obj.OBJECT_ID,
				i.name IndexName, i.type_desc IndexTypeDesc
				FROM
					(SELECT OBJECT_NAME(OBJECT_ID) AS name,	index_id ,
						allocation_unit_id, OBJECT_ID
					 FROM sys.allocation_units AS au
					    INNER JOIN sys.partitions AS p ON au.container_id = p.hobt_id	AND (au.TYPE = 1 OR au.TYPE = 3)
					 UNION ALL
					 SELECT OBJECT_NAME(OBJECT_ID) AS name,
						index_id, allocation_unit_id, OBJECT_ID
					 FROM sys.allocation_units AS au
						INNER JOIN sys.partitions AS p ON au.container_id = p.partition_id	AND au.TYPE = 2
					) AS s_obj
					LEFT JOIN sys.indexes i ON i.index_id = s_obj.index_id
			    	AND i.OBJECT_ID = s_obj.OBJECT_ID 
			    ) AS obj ON bd.allocation_unit_id = obj.allocation_unit_id
WHERE database_id = DB_ID()
GROUP BY name, index_id, IndexName, IndexTypeDesc
ORDER BY cached_pages_count DESC;