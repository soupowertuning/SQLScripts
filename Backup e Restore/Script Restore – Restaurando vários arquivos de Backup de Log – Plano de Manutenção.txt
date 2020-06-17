SET NOCOUNT ON

---------------------------------------------------------------------------------------------------------------------------------
-- Parametros para realizar o Backup
--------------------------------------------------------------------------------------------------------------------------------
DECLARE @DatabaseDestino VARCHAR(8000), @Ds_Caminho_StandyBy VARCHAR(8000), @Ds_Pasta_Log VARCHAR(8000), @Nm_Arquivo_Log VARCHAR(8000),
		@Ds_Caminho_Backup_Full VARCHAR(8000), @Ds_Caminho_Backup_Diff VARCHAR(8000), @Ds_Extensao_Backup_Log VARCHAR(8000),
		@ComandoBackupFULL varchar(8000), @ComandoBackupDiferencial varchar(8000), @ComandoBackupLog varchar(8000),
		@DatabaseOrigem varchar(8000), @Ultimo_Backup_FULL datetime, @Ultimo_Backup_Diferencial datetime
		
select	@DatabaseOrigem = 'NomeDatabase',
		@DatabaseDestino = 'TesteRestore_NomeDatabase',
		@Ds_Caminho_Backup_Full = 'C:\SQLServer\Backup\NomeDatabase_Dados.bak',					-- Caminho \ Nome do Backup Full.
		@Ds_Caminho_Backup_Diff = NULL, --'C:\SQLServer\Backup\NomeDatabase_Diff_Dados.bak',	-- Caminho \ Nome do Backup Diferencial. Caso contrário, deve informar NULL.
		@Ds_Caminho_StandyBy =  NULL, --'C:\SQLServer\Backup\NomeDatabase_StandBy',				-- Informar o nome do Arquivo para o Standy By. Caso contrário, deve informar NULL.
		@Ds_Extensao_Backup_Log = '.trn',														-- Extensão dos Arquivos de Log. Informar o prefixo ".".
		@Ds_Pasta_Log = 'C:\SQLServer\Backup\NomeDatabase\'										-- Caminho da Pasta dos Arquivos de Log. Colocar a "\" no final.

------------------------------------------------------------------------------------------------------------------------
-- LISTA ARQUIVOS DE LOG
------------------------------------------------------------------------------------------------------------------------
-- FLAG DE CONTROLE DO CMDSHELL
DECLARE @Fl_Habilitar_CMDSHELL BIT = 0

-- SE A OPÇÃO CMDSHELL ESTIVER DESABILITADA, IRA HABILITAR TEMPORARIAMENTE E DESABILITAR DEPOIS
IF	(
		select value_in_use
		from sys.configurations
		where name in(	'xp_cmdshell')
	) = 0
BEGIN
	-- MARCA A FLAG PARA DESABILITAR O CMDSHELL NO FINAL DO SCRIPT
	SELECT @Fl_Habilitar_CMDSHELL = 1

	PRINT 'Desconsiderar essa mensagem:'

	EXEC sp_configure 'advanced options', 1
	RECONFIGURE

	PRINT 'Desconsiderar essa mensagem:'

	EXEC sp_configure 'xp_cmdshell', 1
	RECONFIGURE
END

-- LISTA OS ARQUIVOS DE LOG NA PASTA
DECLARE @Query VARCHAR(8000) = 'dir/ -C /4 /N "' + @Ds_Pasta_Log + '"'
 
DECLARE @Retorno TABLE (
    Linha INT IDENTITY(1, 1),
    Resultado VARCHAR(MAX)
)

IF (OBJECT_ID('tempdb..#Lista_Arquivos_Log') IS NOT NULL)
	DROP TABLE #Lista_Arquivos_Log

CREATE TABLE #Lista_Arquivos_Log (
    Linha INT IDENTITY(1, 1),
    Dt_Criacao DATETIME,
    Fl_Tipo BIT,
    Qt_Tamanho BIGINT,
    Ds_Arquivo VARCHAR(500)
)

INSERT INTO @Retorno
EXEC master.dbo.xp_cmdshell 
    @command_string = @Query

	
INSERT INTO #Lista_Arquivos_Log(Dt_Criacao, Fl_Tipo, Qt_Tamanho, Ds_Arquivo)
SELECT 
	CASE WHEN SUBSTRING(Resultado, 19, 2) <> '  '	-- DATA + HORA + AM/PM
		THEN
			CAST(SUBSTRING(Resultado, 7, 4) + SUBSTRING(Resultado, 1, 2) + SUBSTRING(Resultado, 4, 2) AS DATETIME) +
			CONVERT(DATETIME,CAST(SUBSTRING(Resultado, 13, 8) AS TIME)) 
		ELSE										-- DATA + HORA
			CONVERT(DATETIME, LEFT(Resultado, 17), 103)
	END AS Dt_Criacao,   
    1 AS Fl_Tipo, 
	CASE WHEN SUBSTRING(Resultado, 19, 2) <> '  '	-- DATA + HORA + AM/PM
		THEN
			LTRIM(SUBSTRING(LTRIM(Resultado), 21, 19))
		ELSE										-- DATA + HORA
			LTRIM(SUBSTRING(LTRIM(Resultado), 18, 19))
	END AS Qt_Tamanho,
	CASE WHEN SUBSTRING(Resultado, 19, 2) <> '  '	-- DATA + HORA + AM/PM
		THEN
			SUBSTRING(Resultado, CHARINDEX(LTRIM(SUBSTRING(LTRIM(Resultado), 21, 19)), Resultado, 18) + LEN(LTRIM(SUBSTRING(LTRIM(Resultado), 21, 19))) + 1, LEN(Resultado))
		ELSE										-- DATA + HORA
			SUBSTRING(Resultado, CHARINDEX(LTRIM(SUBSTRING(LTRIM(Resultado), 18, 19)), Resultado, 18) + LEN(LTRIM(SUBSTRING(LTRIM(Resultado), 18, 19))) + 1, LEN(Resultado))
	END AS Ds_Arquivo    
FROM 
    @Retorno
WHERE 
    Resultado IS NOT NULL
    AND Linha >= 6
    AND Linha < (SELECT MAX(Linha) FROM @Retorno) - 2
    AND Resultado NOT LIKE '%<DIR>%'
ORDER BY
    Ds_Arquivo


-- DESABILITA O OPÇÃO DO CMDSHELL
IF (@Fl_Habilitar_CMDSHELL = 1)
BEGIN
	EXEC sp_configure 'advanced options', 1
	RECONFIGURE

	PRINT 'Desconsiderar essa mensagem:'

	EXEC sp_configure 'xp_cmdshell', 0
	RECONFIGURE

	PRINT 'Desconsiderar essa mensagem:'

	EXEC sp_configure 'advanced options', 0
	RECONFIGURE
END

-- Exclui os arquivos que não são de Backup
DELETE #Lista_Arquivos_Log
WHERE RIGHT(Ds_Arquivo, len(@Ds_Extensao_Backup_Log)) <> @Ds_Extensao_Backup_Log

-- SELECT * FROM #Lista_Arquivos_Log

------------------------------------------------------------------------------------------------------------------------

-- https://dba.stackexchange.com/questions/12437/extracting-a-field-from-restore-headeronly

-- https://docs.microsoft.com/en-us/sql/t-sql/statements/restore-statements-headeronly-transact-sql

IF (OBJECT_ID('tempdb..#BackupHeader') IS NOT NULL)
	DROP TABLE #BackupHeader

CREATE TABLE #BackupHeader
( 
    BackupName varchar(MAX),
    BackupDescription varchar(256),
    BackupType varchar(256),        
    ExpirationDate varchar(256),
    Compressed varchar(256),
    Position varchar(256),
    DeviceType varchar(256),        
    UserName varchar(256),
    ServerName varchar(256),
    DatabaseName varchar(256),
    DatabaseVersion varchar(256),        
    DatabaseCreationDate varchar(256),
    BackupSize varchar(256),
    FirstLSN varchar(256),
    LastLSN varchar(256),        
    CheckpointLSN varchar(256),
    DatabaseBackupLSN varchar(256),
    BackupStartDate DATETIME,
    BackupFinishDate DATETIME,        
    SortOrder varchar(256),
    CodePage varchar(256),
    UnicodeLocaleId varchar(256),
    UnicodeComparisonStyle varchar(256),        
    CompatibilityLevel varchar(256),
    SoftwareVendorId varchar(256),
    SoftwareVersionMajor varchar(256),        
    SoftwareVersionMinor varchar(256),
    SoftwareVersionBuild varchar(256),
    MachineName varchar(256),
    Flags varchar(256),        
    BindingID varchar(256),
    RecoveryForkID varchar(256),
    Collation varchar(256),
    FamilyGUID varchar(256),        
    HasBulkLoggedData varchar(256),
    IsSnapshot varchar(256),
    IsReadOnly varchar(256),
    IsSingleUser varchar(256),        
    HasBackupChecksums varchar(256),
    IsDamaged varchar(256),
    BeginsLogChain varchar(256),
    HasIncompleteMetaData varchar(256),        
    IsForceOffline varchar(256),
    IsCopyOnly varchar(256),
    FirstRecoveryForkID varchar(256),
    ForkPointLSN varchar(256),        
    RecoveryModel varchar(256),
    DifferentialBaseLSN varchar(256),
    DifferentialBaseGUID varchar(256),        
    BackupTypeDescription varchar(256),
    BackupSetGUID varchar(256),
    CompressedBackupSize varchar(256),
	Containment tinyint,					-- Include this column if using SQL 2012
    KeyAlgorithm nvarchar(32),				-- Include this column if using SQL 2014
    EncryptorThumbprint varbinary(20),		-- Include this column if using SQL 2014
    EncryptorType nvarchar(32)				-- Include this column if using SQL 2014
)

IF (OBJECT_ID('tempdb..#BackupHeaderTemp') IS NOT NULL)
	DROP TABLE #BackupHeaderTemp

CREATE TABLE #BackupHeaderTemp
( 
    BackupName varchar(MAX),
    BackupDescription varchar(256),
    BackupType varchar(256),        
    ExpirationDate varchar(256),
    Compressed varchar(256),
    Position varchar(256),
    DeviceType varchar(256),        
    UserName varchar(256),
    ServerName varchar(256),
    DatabaseName varchar(256),
    DatabaseVersion varchar(256),        
    DatabaseCreationDate varchar(256),
    BackupSize varchar(256),
    FirstLSN varchar(256),
    LastLSN varchar(256),        
    CheckpointLSN varchar(256),
    DatabaseBackupLSN varchar(256),
    BackupStartDate DATETIME,
    BackupFinishDate DATETIME,        
    SortOrder varchar(256),
    CodePage varchar(256),
    UnicodeLocaleId varchar(256),
    UnicodeComparisonStyle varchar(256),        
    CompatibilityLevel varchar(256),
    SoftwareVendorId varchar(256),
    SoftwareVersionMajor varchar(256),        
    SoftwareVersionMinor varchar(256),
    SoftwareVersionBuild varchar(256),
    MachineName varchar(256),
    Flags varchar(256),        
    BindingID varchar(256),
    RecoveryForkID varchar(256),
    Collation varchar(256),
    FamilyGUID varchar(256),        
    HasBulkLoggedData varchar(256),
    IsSnapshot varchar(256),
    IsReadOnly varchar(256),
    IsSingleUser varchar(256),        
    HasBackupChecksums varchar(256),
    IsDamaged varchar(256),
    BeginsLogChain varchar(256),
    HasIncompleteMetaData varchar(256),        
    IsForceOffline varchar(256),
    IsCopyOnly varchar(256),
    FirstRecoveryForkID varchar(256),
    ForkPointLSN varchar(256),        
    RecoveryModel varchar(256),
    DifferentialBaseLSN varchar(256),
    DifferentialBaseGUID varchar(256),        
    BackupTypeDescription varchar(256),
    BackupSetGUID varchar(256),
    CompressedBackupSize varchar(256),
	Containment tinyint,					-- Include this column if using SQL 2012
    KeyAlgorithm nvarchar(32),				-- Include this column if using SQL 2014
    EncryptorThumbprint varbinary(20),		-- Include this column if using SQL 2014
    EncryptorType nvarchar(32)				-- Include this column if using SQL 2014
)

INSERT INTO #BackupHeader
exec ('RESTORE HEADERONLY FROM DISK = ''' + @Ds_Caminho_Backup_Full + '''')

-- Verifica a Data do Backup Full
select @Ultimo_Backup_FULL = BackupFinishDate 
from #BackupHeader 
where BackupType = 1

IF (@Ds_Caminho_Backup_Diff IS NOT NULL)
BEGIN
	INSERT INTO #BackupHeader
	exec ('RESTORE HEADERONLY FROM DISK = ''' + @Ds_Caminho_Backup_Diff + '''')
END

-- Verifica a Data do Backup Full
select @Ultimo_Backup_FULL = BackupFinishDate 
from #BackupHeader 
where BackupType = 1

-- Backup Diferencial - Se a data do diferencial for menor que o FULL, o valor fica NULL
SELECT @Ultimo_Backup_Diferencial = CASE WHEN BackupFinishDate > @Ultimo_Backup_FULL THEN BackupFinishDate ELSE NULL END
FROM #BackupHeader 
WHERE	BackupType = 5
		AND BackupStartDate >= @Ultimo_Backup_FULL
		
-- Exclui os Backups de Log Anteriores ao Backup Full
DELETE FROM #Lista_Arquivos_Log
WHERE Dt_Criacao < DATEADD(SECOND, -DATEPART(SECOND,ISNULL(@Ultimo_Backup_Diferencial, @Ultimo_Backup_FULL)), ISNULL(@Ultimo_Backup_Diferencial, @Ultimo_Backup_FULL))	-- Tratamento para incluir os backups de log no mesmo minuto do Backup Full/Diff

-- Verifica os Backups de Log no mesmo minuto do Backup Full/Diff
if(OBJECT_ID('tempdb..#temp_backup_log_files') IS NOT NULL)
	DROP TABLE #temp_backup_log_files

select * 
into #temp_backup_log_files
from #Lista_Arquivos_Log
where Dt_Criacao = DATEADD(SECOND, -DATEPART(SECOND,ISNULL(@Ultimo_Backup_Diferencial, @Ultimo_Backup_FULL)), ISNULL(@Ultimo_Backup_Diferencial, @Ultimo_Backup_FULL))

declare @Nm_Temp_Backup_Log VARCHAR(MAX), @Temp_BackupFinishDate DATETIME

while exists (select * from #temp_backup_log_files)
begin
	select top 1 @Nm_Temp_Backup_Log = Ds_Arquivo
	from #temp_backup_log_files
	
	truncate table #BackupHeaderTemp

	INSERT INTO #BackupHeaderTemp
	exec ('RESTORE HEADERONLY FROM DISK = ''' + @Ds_Pasta_Log + @Nm_Temp_Backup_Log + '''')

	select @Temp_BackupFinishDate = BackupFinishDate
	from #BackupHeaderTemp

	-- Atualiza a data de criação do Arquivo
	update #Lista_Arquivos_Log
	set Dt_Criacao = @Temp_BackupFinishDate
	where Ds_Arquivo = @Nm_Temp_Backup_Log
	
	delete #temp_backup_log_files
	where Ds_Arquivo = @Nm_Temp_Backup_Log
end

-- Exclui os Backups de Log Anteriores ao Backup Full/Diff
DELETE FROM #Lista_Arquivos_Log
WHERE Dt_Criacao < ISNULL(@Ultimo_Backup_Diferencial, @Ultimo_Backup_FULL)

-- select * from #Lista_Arquivos_Log

--------------------------------------------------------------------------------------------------------------------------------
-- RESTORE FULL
--------------------------------------------------------------------------------------------------------------------------------
PRINT '

-- FULL' + ' -- ' + CONVERT(VARCHAR(20), @Ultimo_Backup_FULL, 120) + '
RESTORE DATABASE ' + @DatabaseDestino + '
FROM DISK = ''' + @Ds_Caminho_Backup_Full + ''' 
WITH	NORECOVERY , STATS = 1,'


---------------------------------------------------------------------------------------------------------------------------------
-- Busca os nomes lógicos dos arquivos
--------------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Filelistonly') is not null drop table #Filelistonly

Create table #Filelistonly
(
	LogicalName          nvarchar(128),
	PhysicalName         nvarchar(260),
	[Type]               char(1),
	FileGroupName        nvarchar(128),
	Size                 numeric(20,0),
	MaxSize              numeric(20,0),
	FileID               bigint,
	CreateLSN            numeric(25,0),
	DropLSN              numeric(25,0),
	UniqueID             uniqueidentifier,
	ReadOnlyLSN          numeric(25,0),
	ReadWriteLSN         numeric(25,0),
	BackupSizeInBytes    bigint,
	SourceBlockSize      int,
	FileGroupID          int,
	LogGroupGUID         uniqueidentifier,
	DifferentialBaseLSN  numeric(25,0),
	DifferentialBaseGUID uniqueidentifier,
	IsReadOnl            bit,
	IsPresent            bit,
	TDEThumbprint        varbinary(32),		-- Remove this column if using SQL 2005
	SnapshotURL          nvarchar(360)		-- Include this column if using SQL 2016
)

INSERT INTO #Filelistonly
exec('RESTORE FILELISTONLY FROM DISK = ''' + @Ds_Caminho_Backup_Full + '''')

-- Logical and Fisical Names
DECLARE 
	@Move VARCHAR(MAX) = '',
	@FileID INT

/*
-- https://docs.microsoft.com/en-us/sql/t-sql/statements/restore-statements-filelistonly-transact-sql
Type -> The type of file, one of:

L = Microsoft SQL Server log file
D = SQL Server data file
F = Full Text Catalog
S = FileStream, FileTable, or In-Memory OLTP container
*/

-- Tratamento para gerar o comando MOVE
WHILE EXISTS (SELECT TOP 1 * FROM #Filelistonly)
BEGIN
	SELECT @FileID = FileID
	from #Filelistonly
	order by FileID
		
	select 	 
		@Move = REPLICATE(' ', 8) + 'MOVE ' 			 
					 + QUOTENAME(LogicalName,'''''') + ' TO '					 
					 + CASE
						WHEN FileID = 1		-- DATA FILE - PRIMARY
							THEN QUOTENAME(REPLACE(PhysicalName,'.mdf', '_' + @DatabaseDestino + '.mdf'),'''''')
						WHEN Type = 'S'	-- FileStream, FileTable, or In-Memory OLTP container
							THEN QUOTENAME(PhysicalName + '_' + @DatabaseDestino,'''''')
							--THEN '''' + PhysicalName + '_' + @DatabaseDestino + ''''
						WHEN Type <> 'L'	-- DATA FILE - SECUNDARY
							THEN QUOTENAME(REPLACE(PhysicalName,'.ndf', '_' + @DatabaseDestino + '.ndf'),'''''')
						ELSE				-- LOG FILE
							QUOTENAME(REPLACE(PhysicalName,'.ldf', '_' + @DatabaseDestino + '.ldf'),'''''')
					 END
					 + CASE WHEN FileID <> 1 THEN ', ' ELSE ' ' END --+ CHAR(10)
	from #Filelistonly
	where FileID = @FileID

	PRINT @Move	

	delete #Filelistonly
	where FileID = @FileID
END

--------------------------------------------------------------------------------------------------------------------------------
--	RESTORE DIFERENCIAL
--------------------------------------------------------------------------------------------------------------------------------
IF (@Ultimo_Backup_Diferencial IS NOT NULL)
BEGIN
	PRINT '

-- DIFERENCIAL' + ' -- ' + CONVERT(VARCHAR(20), @Ultimo_Backup_Diferencial, 120) + '
RESTORE DATABASE ' + @DatabaseDestino + ' 
FROM DISK = ''' + @Ds_Caminho_Backup_Diff + ''' 
WITH NORECOVERY, STATS = 1' 
END


---------------------------------------------------------------------------------------------------------------------------------
--	RESTORE LOG
--------------------------------------------------------------------------------------------------------------------------------
PRINT '

-- LOG
'

IF (OBJECT_ID('tempdb..#Lista_Arquivos_Log_Ordenado') IS NOT NULL)
	DROP TABLE #Lista_Arquivos_Log_Ordenado

CREATE TABLE #Lista_Arquivos_Log_Ordenado (
    Linha INT IDENTITY(1, 1),
    Dt_Criacao DATETIME,
    Fl_Tipo BIT,
    Qt_Tamanho BIGINT,
    Ds_Arquivo VARCHAR(500)
)

INSERT INTO #Lista_Arquivos_Log_Ordenado
SELECT Dt_Criacao, Fl_Tipo, Qt_Tamanho, Ds_Arquivo
FROM #Lista_Arquivos_Log
ORDER BY Dt_Criacao, Ds_Arquivo

DECLARE @LINHA_LOOP INT

while exists ( select TOP 1 NULL from #Lista_Arquivos_Log_Ordenado)
begin
	SELECT @LINHA_LOOP = MIN(Linha)
	FROM #Lista_Arquivos_Log_Ordenado
		
	SELECT @ComandoBackupLog = 
		'RESTORE LOG '+ @DatabaseDestino +' from disk = ''' + @Ds_Pasta_Log + [Ds_Arquivo] + ''' WITH FILE = 1' + 
		+ CASE WHEN @Ds_Caminho_StandyBy IS NOT NULL THEN ', STANDBY = N''' + @Ds_Caminho_StandyBy + '''' ELSE ', NORECOVERY' END
		+ ' -- ' + CONVERT(VARCHAR(20), Dt_Criacao, 120)
	from #Lista_Arquivos_Log_Ordenado
	WHERE Linha = @LINHA_LOOP
	order by Dt_Criacao

	PRINT @ComandoBackupLog

	delete from #Lista_Arquivos_Log_Ordenado WHERE Linha = @LINHA_LOOP
end

PRINT ''
PRINT ''
PRINT '-- Comando para deixar a base ONLINE'
PRINT 'RESTORE DATABASE ' + @DatabaseDestino + ' WITH RECOVERY'

print ''
print '-- Comando para alterar o recovery model da base restaurada'
print 'ALTER DATABASE ' + @DatabaseDestino +  ' SET RECOVERY SIMPLE'
print ''

print '-- Comando para validar se a base está OK'
print 'DBCC CHECKDB(''' + @DatabaseDestino +  ''')'
print ''

print '-- Comando para excluir a base de teste'
print '-- DROP DATABASE ' + @DatabaseDestino