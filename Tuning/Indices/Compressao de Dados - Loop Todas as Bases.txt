USE [Traces]

IF (OBJECT_ID('tempdb..##TEMP_POWER_COMPRESSAO_DADOS') IS NOT NULL)
	DROP TABLE ##TEMP_POWER_COMPRESSAO_DADOS

CREATE TABLE ##TEMP_POWER_COMPRESSAO_DADOS(
	[Nm_Database] [varchar](256)  NOT NULL,
	[Schema] [sysname] NOT NULL,
	[Table] [sysname] NOT NULL,
	[Index] [sysname] NULL,
	[Partition] [int] NOT NULL,
	[Compression] [nvarchar](60) NULL,
	[fill_factor] [tinyint] NOT NULL,
	[rows] [bigint] NULL,
	[Ds_Comando] [nvarchar](480) NULL
) ON [PRIMARY]
GO

IF (OBJECT_ID('tempdb..##TEMP_POWER_COMPRESSAO_DADOS_HEAP') IS NOT NULL)
	DROP TABLE ##TEMP_POWER_COMPRESSAO_DADOS_HEAP

CREATE TABLE ##TEMP_POWER_COMPRESSAO_DADOS_HEAP (
	[Nm_Database] [varchar](256)  NOT NULL,
	[Table] [sysname] NOT NULL,
	[Compression] [nvarchar](60) NULL,
	[Ds_Comando] [nvarchar](312) NOT NULL
) ON [PRIMARY]
GO

DECLARE @SQL VARCHAR(max) , @DB sysname

DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR  
SELECT A.[name]  
FROM master.sys.databases A
--LEFT JOIN [dbo].[Ignore_Databases] B ON A.[name] COLLATE SQL_Latin1_General_CP1_CI_AI = B.[Nm_Database]
WHERE 
	A.[name] NOT IN ('tempdb','ReportServerTempDB','model','master','msdb') 
	and A.state_desc = 'ONLINE'
	--and B.[Nm_Database] IS NULL		-- DESCONSIDERAR DATABASES
	
ORDER BY A.[name]
	         
	OPEN curDB  
	FETCH NEXT FROM curDB INTO @DB  
	WHILE @@FETCH_STATUS = 0  
	   BEGIN  
		   SELECT @SQL = 'USE [' + @DB +']' + CHAR(13) + 
			 '
			
			;INSERT INTO ##TEMP_POWER_COMPRESSAO_DADOS
SELECT ''' + @DB + ''' AS [Nm_Database],
	   [s].[name] AS [Schema],
	   [t].[name] AS [Table], 
       [i].[name] AS [Index],  
       [p].[partition_number] AS [Partition],
       [p].[data_compression_desc] AS [Compression], 
       [i].[fill_factor],
       [p].[rows],
			 ''ALTER INDEX ['' + [i].[name] + ''] ON [' + @DB + '].['' + [s].[name] + ''].['' + [t].[name] + 
			 ''] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE'' +
			 CASE WHEN [i].[fill_factor] BETWEEN 1 AND 89 THEN '', FILLFACTOR = 90'' ELSE '''' END + '' )'' AS Ds_Comando
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
			AND [p].[data_compression_desc] = ''NONE''
--ORDER BY [p].[rows]									-- PARA VERIFICAR O TAMANHO DOS INDICES
--ORDER BY [s].[name], [t].[name], [i].[name]		-- ORDENA POR TABELA PARA PODER RODAR EM PARALELO
	
-- Data (table) compression (heap)
INSERT INTO ##TEMP_POWER_COMPRESSAO_DADOS_HEAP
SELECT DISTINCT 
	   ''' + @DB + ''' AS [Nm_Database],
	   [t].[name] AS [Table],
       [p].[data_compression_desc] AS [Compression], 
       --[i].[fill_factor],
       ''ALTER TABLE [' + @DB + '].['' + [s].[name] + ''].['' + [t].[name] + ''] REBUILD WITH (DATA_COMPRESSION = PAGE)'' AS Ds_Comando
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] 
     ON [t].[object_id] = [p].[object_id]
INNER JOIN sys.indexes AS [i] 
     ON [i].[object_id] = [p].[object_id]
INNER JOIN sys.schemas AS [s]
		 ON [t].[schema_id] = [s].[schema_id]
WHERE [p].[index_id]  = 0
			AND [p].[rows] > 10000
			AND [p].[data_compression_desc] = ''NONE''
				
		 '            
		exec (@SQL )
	   
		set @SQL = ''
	   
		FETCH NEXT FROM curDB INTO @DB  
	END  
	   
CLOSE curDB  
DEALLOCATE curDB

SELECT * FROM ##TEMP_POWER_COMPRESSAO_DADOS
ORDER BY rows

SELECT * FROM ##TEMP_POWER_COMPRESSAO_DADOS_HEAP
ORDER BY [Nm_Database], [Table]