SET NOCOUNT ON

-- Referencia de onde veio esse script. Fizemos algumas adaptações:
--http://www.sqlservercentral.com/scripts/Administration/99339/

-- OBS!!!!! Garanta que seu SQL Server tem o recuros IFI habilitado. Caso contrário, o crescimento do MDF pode ficar lento.

/*

--Script para conferir o crescimento dos arquivos de dados e logs.
SELECT   
    SD.database_id,   
    SD.name DBName,
	 SF.name FileName,  
	(SF.size/128.0) ActualSize,
	SF.growth ,
    CASE SF.status & 0x100000  
			WHEN 1048576 THEN 'Percentage'  
			WHEN 0 THEN 'MB'  
    END AS 'GROWTH Option'  ,
		SF.maxsize
FROM sys.sysaltfiles SF  
JOIN sys.databases SD ON SD.database_id = SF.dbid
WHERE 
	 state_desc = 'ONLINE'
	and SD.name NOT IN  ('master','msdb','model','tempdb')

*/
IF object_id('tempdb..#ConfigAutoGrowth') IS NOT NULL
    DROP TABLE #ConfigAutoGrowth  
GO    
CREATE TABLE #ConfigAutoGrowth  
(  
Database_id		INT,  
Nm_Database		VARCHAR(MAX),
group_id		INT,
MaxSize			INT,
size_MB			INT,
vFileName		VARCHAR(max),  
vGrowthOption   VARCHAR(12)  
)  
GO  
-- Inserting data into staging table  
INSERT INTO #ConfigAutoGrowth  
SELECT   
    SD.database_id,   
    SD.name,
	SF.groupid,
	SF.maxsize,
	(SF.size/128.0),
    SF.name,  
    CASE SF.status & 0x100000  
			WHEN 1048576 THEN 'Percentage'  
			WHEN 0 THEN 'MB'  
    END AS 'GROWTH Option'  
FROM sys.sysaltfiles SF  
JOIN sys.databases SD ON SD.database_id = SF.dbid
WHERE
	((SF.growth = 10 AND (SF.status & 0x100000 = 1048576))
	OR
	(SF.growth = 1 AND (SF.status & 0x100000 = 0))
	)
	and state_desc = 'ONLINE'
	and SD.name NOT IN  ('master','msdb','model','tempdb')
GO  

--select * from #ConfigAutoGrowth

--select * from #ConfigAutoGrowth
IF EXISTS (SELECT TOP 1 * FROM #ConfigAutoGrowth)
BEGIN 
	-- Dynamically alters the file to set auto growth option to fixed mb   
	DECLARE @name VARCHAR ( max ) -- Database Name  
	DECLARE @dbid INT -- DBID 
	DECLARE @typeFile INT 
	DECLARE @maxSizeFile INT
	DECLARE @sizeFile INT
	DECLARE @vFileName VARCHAR ( max ) -- Logical file name  
	DECLARE @vGrowthOption VARCHAR ( max ) -- Growth option  
	DECLARE @Query VARCHAR(max) -- Variable to store dynamic sql  
	
	DECLARE db_cursor CURSOR FAST_FORWARD FOR  
	SELECT Database_id,Nm_Database, group_id, MaxSize, size_MB, vFileName,vGrowthOption  
	FROM #ConfigAutoGrowth  
	
	PRINT 'USE master'+ CHAR(13) + CHAR(10) +'GO' 

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @dbid,@name,@typeFile,@maxSizeFile,@sizeFile,@vFileName,@vGrowthOption    
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT	'ALTER DATABASE '+ '[' + @name + ']' +
				' MODIFY FILE ( NAME = '+ '''' + @vFileName + ''''+ 
				', FILEGROWTH = ' +
				CASE @typeFile
					WHEN 1 THEN (CASE
										WHEN @sizeFile < 512 THEN '100MB'  
										WHEN @sizeFile Between 512 and 1024 THEN  '200MB'
										WHEN @sizeFile Between 1024 and 5120 THEN '500MB'
										WHEN @sizeFile Between 5120 and 102400 THEN  '1000MB'
										WHEN @sizeFile Between 102400 and 512000 THEN  '5000MB'
										WHEN @sizeFile > 512000 THEN  '10000MB'
									END
								)
					WHEN 0 THEN	(CASE
										WHEN @sizeFile < 512 THEN '50MB'  
										WHEN @sizeFile Between 512 and 1024 THEN  '100MB'
										WHEN @sizeFile Between 1024 and 3072 THEN '500MB'
										WHEN @sizeFile > 3072 THEN  '800MB'
									END
								)
				END
				+
				CASE 
					WHEN @maxSizeFile <> -1 THEN ', MAXSIZE = UNLIMITED '
					ELSE ' '
				END
				+ ')'
				+ CHAR(13) + CHAR(10) + 'GO'
			
  
	FETCH NEXT FROM db_cursor INTO @dbid,@name,@typeFile,@maxSizeFile,@sizeFile,@vFileName,@vGrowthOption    
	END  
	CLOSE db_cursor -- Closing the curson  
	DEALLOCATE db_cursor  -- deallocating the cursor  
END
--Dropping the staging table  
DROP TABLE #ConfigAutoGrowth   
GO
