-- Index compression (clustered index or non-clustered index)
SELECT [s].[name] AS [Schema],
	   [t].[name] AS [Table], 
       [i].[name] AS [Index],  
       [p].[partition_number] AS [Partition],
       [p].[data_compression_desc] AS [Compression], 
       [i].[fill_factor],
       [p].[rows],
			 'ALTER INDEX [' + [i].[name] + '] ON [' + [s].[name] + '].[' + [t].[name] + 
			 '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE' +
			 CASE WHEN [i].[fill_factor] BETWEEN 1 AND 89 THEN ', FILLFACTOR = 90' ELSE '' END + ' )' AS Ds_Comando
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] 
     ON [t].[object_id] = [p].[object_id]
INNER JOIN sys.indexes AS [i] 
     ON [i].[object_id] = [p].[object_id] AND i.index_id = p.index_id
INNER JOIN sys.schemas AS [s]
		 ON [t].[schema_id] = [s].[schema_id]
WHERE [p].[index_id] > 0
			AND [i].[name] IS NOT NULL
			AND [p].[rows] > 10000
			AND [p].[data_compression_desc] = 'NONE'
ORDER BY [p].[rows]									-- PARA VERIFICAR O TAMANHO DOS INDICES
--ORDER BY [s].[name], [t].[name], [i].[name]		-- ORDENA POR TABELA PARA PODER RODAR EM PARALELO
	
-- Data (table) compression (heap)
SELECT DISTINCT 
			 [t].[name] AS [Table],
       [p].[data_compression_desc] AS [Compression], 
       --[i].[fill_factor],
       'ALTER TABLE [' + [s].[name] + '].[' + [t].[name] + '] REBUILD WITH (DATA_COMPRESSION = PAGE)' AS Ds_Comando
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] 
     ON [t].[object_id] = [p].[object_id]
INNER JOIN sys.indexes AS [i] 
     ON [i].[object_id] = [p].[object_id]
INNER JOIN sys.schemas AS [s]
		 ON [t].[schema_id] = [s].[schema_id]
WHERE [p].[index_id]  = 0
			AND [p].[rows] > 10000
			AND [p].[data_compression_desc] = 'NONE'
