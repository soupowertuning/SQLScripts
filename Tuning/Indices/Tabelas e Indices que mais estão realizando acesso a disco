USE DATABASE_NAME

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
GO
DECLARE @statusMsg  VARCHAR(MAX) = ''



SET @statusMsg = 'Collecting duplicated index info...'
RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;

IF OBJECT_ID('tempdb.dbo.#tmpDuplicatedIndex') IS NOT NULL
    DROP TABLE #tmpDuplicatedIndex;

SELECT DISTINCT i.object_id, i.index_id
INTO #tmpDuplicatedIndex
FROM sys.tables AS t 
JOIN sys.indexes AS i
	ON t.object_id = i.object_id
JOIN sys.index_columns ic 
	ON ic.object_id = i.object_id 
		AND ic.index_id = i.index_id 
		AND ic.index_column_id = 1  
JOIN sys.columns AS c 
	ON c.object_id = ic.object_id 
		AND c.column_id = ic.column_id      
JOIN sys.schemas AS s 
	ON t.schema_id = s.schema_id
CROSS APPLY
(
	SELECT 
	   ind.index_id
	   ,ind.name
	FROM sys.indexes AS ind 
	JOIN sys.index_columns AS ico 
	   ON ico.object_id = ind.object_id
	   AND ico.index_id = ind.index_id
	   AND ico.index_column_id = 1  
	WHERE ind.object_id = i.object_id 
	   AND ind.index_id > i.index_id
	   AND ico.column_id = ic.column_id
) DupliIDX     

CREATE CLUSTERED INDEX ix1 ON #tmpDuplicatedIndex (object_id, index_id);

SET @statusMsg = 'Collecting cache index info...'
RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;

IF OBJECT_ID('tempdb.dbo.#tmpCacheMissingIndex1') IS NOT NULL
    DROP TABLE #tmpCacheMissingIndex1;

WITH XMLNAMESPACES
   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')

SELECT 
       --n.query('.//MissingIndex') AS 'Missing_Index_Cache_Info',
       --CONVERT(XML, n.value('(@StatementText)[1]', 'VARCHAR(4000)')) AS 'Missing_Index_Cache_SQL',
       --n.value('(//MissingIndexGroup/@Impact)[1]', 'FLOAT') AS impact,
       OBJECT_ID(n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)') + '.' +
           n.value('(//MissingIndex/@Schema)[1]', 'VARCHAR(128)') + '.' +
           n.value('(//MissingIndex/@Table)[1]', 'VARCHAR(128)')) AS OBJECT_ID
INTO #tmpCacheMissingIndex1
FROM
(
   SELECT query_plan
   FROM (
           SELECT DISTINCT plan_handle
           FROM sys.dm_exec_query_stats WITH(NOLOCK)
         ) AS qs
       OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp
   WHERE tp.query_plan.exist('//MissingIndex')=1
) AS tab (query_plan)
CROSS APPLY query_plan.nodes('//StmtSimple') AS q(n)
WHERE n.exist('QueryPlan/MissingIndexes') = 1;


IF OBJECT_ID('tempdb.dbo.#tmpCacheMissingIndex2') IS NOT NULL
    DROP TABLE #tmpCacheMissingIndex2;

SELECT OBJECT_ID, 
       COUNT(*) AS 'Number_of_missing_index_plans_cache'
  INTO #tmpCacheMissingIndex2
  FROM #tmpCacheMissingIndex1
  GROUP BY OBJECT_ID

CREATE CLUSTERED INDEX ix1 ON #tmpCacheMissingIndex2 (OBJECT_ID);


SET @statusMsg = 'Collecting BP usage info...'
RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;

IF OBJECT_ID('tempdb.dbo.#tmpBufferDescriptors') IS NOT NULL
    DROP TABLE #tmpBufferDescriptors;

SELECT allocation_unit_id,
       CONVERT(DECIMAL(18, 2), (COUNT(*) * 8) / 1024.) AS CacheSizeMB,
       CONVERT(DECIMAL(18, 2), (SUM(CONVERT(FLOAT, free_space_in_bytes)) / 1024.) / 1024.) AS FreeSpaceMB
INTO #tmpBufferDescriptors
FROM sys.dm_os_buffer_descriptors
WHERE dm_os_buffer_descriptors.database_id = DB_ID()
      AND dm_os_buffer_descriptors.page_type IN ( 'data_page', 'index_page' )
GROUP BY allocation_unit_id;

CREATE CLUSTERED INDEX ix1 ON #tmpBufferDescriptors (allocation_unit_id);


SET @statusMsg = 'Collecting fragmentation index info...'
RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;

IF OBJECT_ID('tempdb.dbo.#tmpIndexFrag') IS NOT NULL
    DROP TABLE #tmpIndexFrag;

SELECT *
INTO #tmpIndexFrag
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')
WHERE dm_db_index_physical_stats.alloc_unit_type_desc = 'IN_ROW_DATA';

CREATE CLUSTERED INDEX ix1
ON [dbo].#tmpIndexFrag (
                           [object_id],
                           [index_id]
                       );

SELECT DB_NAME() AS 'Database_Name',
       sc.name AS 'Schema_Name',
       t.name AS 'Table_Name',
       i.name AS 'Index_Name',
       i.type_desc AS 'Index_Type',
       p.rows AS 'Number_Rows',
       tSize.ReservedSizeInMB,
       tNumerOfIndexes.Cnt AS 'Number_Of_Indexes_On_Table',
       CONVERT(DECIMAL(18, 2), #tmpIndexFrag.avg_fragmentation_in_percent) AS 'Fragmentation_Percent',
       i.fill_factor,
       ISNULL(bp.CacheSizeMB, 0) AS 'Buffer_Pool_SpaceUsed_MB',
       ISNULL(bp.FreeSpaceMB, 0) AS 'Buffer_Pool_FreeSpace_MB',
       CASE
           WHEN #tmpDuplicatedIndex.object_id IS NULL THEN
               'N'
           ELSE
               'Y'
       END AS 'Duplicated_Index_Identified',
       CASE
           WHEN mid.database_id IS NULL THEN
               'N'
           ELSE
               'Y'
       END AS 'DMV_Missing_Index_Identified',
       mid.Number_of_missing_index_plans_DMV,
       CASE
           WHEN #tmpCacheMissingIndex2.Number_of_missing_index_plans_cache IS NULL THEN
               'N'
           ELSE
               'Y'
       END AS 'Cache_Missing_Index_Identified',
       #tmpCacheMissingIndex2.Number_of_missing_index_plans_cache,
       ius.user_updates AS [Total Writes], 
       ius.user_seeks + ius.user_scans + ius.user_lookups AS 'Number_of_Reads',
       CASE
           WHEN ius.user_seeks + ius.user_scans + ius.user_lookups = 0 THEN
               'Y'
           ELSE
               'N'
       END AS 'Index_was_never_used',
       CONVERT(XML, ISNULL(REPLACE(REPLACE(REPLACE(
                              (
                                  SELECT c.name AS 'columnName'
                                  FROM sys.index_columns AS sic
                                      JOIN sys.columns AS c
                                          ON c.column_id = sic.column_id
                                             AND c.object_id = sic.object_id
                                  WHERE sic.object_id = i.object_id
                                        AND sic.index_id = i.index_id
                                        AND is_included_column = 0
                                  ORDER BY sic.index_column_id
                                  FOR XML RAW
                              ),
                              '"/><row columnName="',
                              ', '
                                     ),
                              '<row columnName="',
                              ''
                             ),
                      '"/>',
                      ''
                     ),
              ''
             )) AS 'indexed_columns',
       CONVERT(XML, ISNULL(REPLACE(REPLACE(REPLACE(
                              (
                                  SELECT c.name AS 'columnName'
                                  FROM sys.index_columns AS sic
                                      JOIN sys.columns AS c
                                          ON c.column_id = sic.column_id
                                             AND c.object_id = sic.object_id
                                  WHERE sic.object_id = i.object_id
                                        AND sic.index_id = i.index_id
                                        AND is_included_column = 1
                                  ORDER BY sic.index_column_id
                                  FOR XML RAW
                              ),
                              '"/><row columnName="',
                              ', '
                                     ),
                              '<row columnName="',
                              ''
                             ),
                      '"/>',
                      ''
                     ),
              ''
             )) AS 'included_columns',
       i.is_unique,
       i.ignore_dup_key,
       i.is_primary_key,
       i.is_unique_constraint,
       i.is_padded,
       i.is_disabled,
       i.is_hypothetical,
       i.allow_row_locks,
       i.allow_page_locks,
       i.has_filter,
       i.filter_definition,
       t.create_date,
       t.modify_date,
       t.uses_ansi_nulls,
       t.is_replicated,
       t.has_replication_filter,
       t.text_in_row_limit,
       t.large_value_types_out_of_row,
       t.is_tracked_by_cdc,
       t.lock_escalation_desc,
       t.is_filetable,
       t.is_memory_optimized,
       t.durability_desc,
       --t.temporal_type_desc,
       --t.is_remote_data_archive_enabled,
       p.partition_number,
       p.data_compression_desc,
       ius.user_seeks,
       ius.user_scans,
       ius.user_lookups,
       ius.user_updates,
       ius.last_user_seek,
       ius.last_user_scan,
       ius.last_user_lookup,
       ius.last_user_update,
       ios.leaf_insert_count,
       ios.leaf_delete_count,
       ios.leaf_update_count,
       ios.leaf_ghost_count,
       ios.nonleaf_insert_count,
       ios.nonleaf_delete_count,
       ios.nonleaf_update_count,
       ios.leaf_allocation_count,
       ios.nonleaf_allocation_count,
       ios.leaf_page_merge_count,
       ios.nonleaf_page_merge_count,
       ios.range_scan_count,
       ios.singleton_lookup_count,
       ios.forwarded_fetch_count,
       ios.lob_fetch_in_pages,
       ios.lob_fetch_in_bytes,
       ios.lob_orphan_create_count,
       ios.lob_orphan_insert_count,
       ios.row_overflow_fetch_in_pages,
       ios.row_overflow_fetch_in_bytes,
       ios.column_value_push_off_row_count,
       ios.column_value_pull_in_row_count,
       ios.row_lock_count,
       ios.row_lock_wait_count,
       ios.row_lock_wait_in_ms,
       ios.page_lock_count,
       ios.page_lock_wait_count,
       ios.page_lock_wait_in_ms,
       ios.index_lock_promotion_attempt_count AS index_lock_escaltion_attempt_count,
       ios.index_lock_promotion_count AS index_lock_escaltion_count,
       ios.page_latch_wait_count,
       ios.page_latch_wait_in_ms,
       ios.page_io_latch_wait_count,
       ios.page_io_latch_wait_in_ms,
       ios.tree_page_latch_wait_count,
       ios.tree_page_latch_wait_in_ms,
       ios.tree_page_io_latch_wait_count,
       ios.tree_page_io_latch_wait_in_ms
FROM sys.indexes i WITH (NOLOCK)
    INNER JOIN sys.tables t
        ON t.object_id = i.object_id
    INNER JOIN sys.schemas sc WITH (NOLOCK)
        ON sc.schema_id = t.schema_id
    INNER JOIN sys.partitions AS p
        ON i.object_id = p.object_id
           AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units AS au
        ON au.container_id = p.hobt_id
       AND au.type_desc = 'IN_ROW_DATA'
    LEFT OUTER JOIN #tmpCacheMissingIndex2
      ON #tmpCacheMissingIndex2.OBJECT_ID = i.object_id
    LEFT OUTER JOIN #tmpDuplicatedIndex
       ON #tmpDuplicatedIndex.index_id = i.index_id
      AND #tmpDuplicatedIndex.object_id = i.object_id
    CROSS APPLY
(
    SELECT CONVERT(DECIMAL(18, 2), SUM((st.reserved_page_count * 8) / 1024.)) ReservedSizeInMB
    FROM sys.dm_db_partition_stats st
    WHERE i.object_id = st.object_id
          AND i.index_id = st.index_id
          AND p.partition_number = st.partition_number
) AS tSize
    LEFT OUTER JOIN sys.dm_db_index_usage_stats ius WITH (NOLOCK)
        ON ius.index_id = i.index_id
           AND ius.object_id = i.object_id
           AND ius.database_id = DB_ID()
    OUTER APPLY sys.dm_db_index_operational_stats(DB_ID(), i.object_id, i.index_id, 1) AS ios
    LEFT OUTER JOIN #tmpBufferDescriptors AS bp
        ON bp.allocation_unit_id = au.allocation_unit_id
    LEFT OUTER JOIN #tmpIndexFrag
        ON i.object_id = #tmpIndexFrag.object_id
           AND i.index_id = #tmpIndexFrag.index_id
    LEFT OUTER JOIN
    (
        SELECT database_id,
               object_id,
               COUNT(*) AS Number_of_missing_index_plans_DMV
        FROM sys.dm_db_missing_index_details
        GROUP BY database_id,
                 object_id
    ) AS mid
        ON mid.database_id = DB_ID()
           AND mid.object_id = i.object_id
    CROSS APPLY
(
    SELECT COUNT(*) AS Cnt
    FROM sys.indexes i1
    WHERE i.object_id = i1.object_id
) AS tNumerOfIndexes
WHERE OBJECTPROPERTY(i.[object_id], 'IsUserTable') = 1
ORDER BY tSize.ReservedSizeInMB DESC
GO
