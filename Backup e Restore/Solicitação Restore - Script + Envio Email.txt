/*
------------------------------------------------------------------------------------------------------------------------
INSTRUÇÕES - IMPORTANTE:
------------------------------------------------------------------------------------------------------------------------
1) Alterar os parâmetros iniciais - linha 33

2) Alterar os parâmetros do RESTORE - linha 153

3) Validar se o RECOVERY MODEL precisa ser alterado para SIMPLE - Base de Teste - linha 178


4) Fazer o REPLACE nos e-mails abaixo pelos e-mails desejados.

email@dominio.com.br;email2@dominio.com.br


5) Profile E-mail - Conferir se vai precisar fazer o REPLACE também

@profile_name = 'MSSQLServer'
*/

USE Traces

GO

------------------------------------------------------------------------------------------------------------------------
-- DECLARA E SETA AS VARIAVEIS
------------------------------------------------------------------------------------------------------------------------
DECLARE @Nm_Database_Restaurada VARCHAR(200), @Ds_Caminho_Backup VARCHAR(500), @Ds_Email VARCHAR(500), @Ds_Email_Body VARCHAR(5000),
		@Dt_Inicial DATETIME, @Dt_Final DATETIME, @Dt_Backup DATETIME, @Nm_Database_Backup VARCHAR(200)
		
SELECT 
	@Nm_Database_Restaurada = 'NomeDatabaseRestaurada',
	@Ds_Caminho_Backup = 'C:\SQLServer\Backup\NomeDatabase_Dados.bak',
	@Ds_Email = 'email@dominio.com.br;email2@dominio.com.br'

------------------------------------------------------------------------------------------------------------------------
-- BUSCA A DATA DO BACKUP
------------------------------------------------------------------------------------------------------------------------
DECLARE @SQLComand VARCHAR(2000)
SET @SQLComand = 'RESTORE HEADERONLY FROM DISK = ''' + @Ds_Caminho_Backup + ''''

-- SELECT @SQLComand

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

INSERT INTO #BackupHeader
EXEC(@SQLComand)

-- SELECT * FROM #BackupHeader

-- Seta a variavel com a data do Backup e o nome da database
SELECT 
	@Dt_Backup = BackupFinishDate,
	@Nm_Database_Backup = DatabaseName
FROM #BackupHeader

------------------------------------------------------------------------------------------------------------------------
-- MATA CONEXOES NA DATABASE QUE SERA RESTAURADA, CASO ELA JA EXISTA
------------------------------------------------------------------------------------------------------------------------
IF EXISTS ( SELECT name FROM sys.databases WHERE name = @Nm_Database_Restaurada )
BEGIN
	-- Mata as Conexões da Database
	DECLARE @SPID as VARCHAR(5)

	IF(OBJECT_ID('tempdb..#Processos') IS NOT NULL) 
		DROP TABLE #Processos

	SELECT CAST(spid as VARCHAR(5)) AS spid
	INTO #Processos
	FROM master.dbo.sysprocesses A
	JOIN master.dbo.sysdatabases B on A.dbid = B.dbid
	WHERE B.name = @Nm_Database_Restaurada
		and spid > 50	-- APENAS PROCESSOS DE USUARIO

	-- SELECT * FROM #Processos

	WHILE ( (SELECT COUNT(*) FROM #Processos) > 0 )
	BEGIN
		SET @SPID = (SELECT TOP 1 spid FROM #Processos)
		EXEC ('Kill ' +  @SPID)
		DELETE FROM #Processos WHERE spid = @SPID
	END
END

-- Guarda o tempo inicial
SELECT @Dt_Inicial = GETDATE()

------------------------------------------------------------------------------------------------------------------------
-- EXECUTA O RESTORE - ATENÇÃO!!! VERIFICAR O SCRIPT E ALTERAR PARA O SEU CASO ESPECIFICO!
------------------------------------------------------------------------------------------------------------------------
-- 1) RESTORE SOBRESCREVENDO UMA DATABASE JÁ EXISTENTE
--RESTORE DATABASE @Nm_Database_Restaurada
--FROM DISK = @Ds_Caminho_Backup
--WITH RECOVERY, REPLACE, STATS = 1

-- 2) RESTORE DE UMA NOVA DATABASE
-- Apenas para validar o nome lógico dos arquivos de dados e logs
--RESTORE FILELISTONLY
--FROM DISK = @Ds_Caminho_Backup

-- Restore criando uma nova Database
--RESTORE DATABASE @Nm_Database_Restaurada
--FROM DISK = @Ds_Caminho_Backup
--WITH RECOVERY, REPLACE, STATS = 1,
--	MOVE 'TESTE_IFI' TO 'C:\SQLServer\Data\TesteRestore_TESTE_IFI2.mdf',
--	MOVE 'TESTE_IFI_log' TO 'C:\SQLServer\Log\TesteRestore_TESTE_IFI_log.ldf'
--	MOVE 'Traces_index' TO 'C:\CaminhoDatabase\NomeDatabase_index.ndf',
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- ENVIA O EMAIL
------------------------------------------------------------------------------------------------------------------------
IF(@@ERROR = 0)
BEGIN
	-- OBS: SE FOR BASE DE HOMOLOGAÇÃO, ALTERAR O RECOVERY MODEL PARA SIMPLE PARA EVITAR QUE O ARQUIVO DE LOG CRESÇA MUITO E NÃO PRECISAR FAZER BACKUP DE LOG.
	SET @SQLComand = 'ALTER DATABASE ' + @Nm_Database_Restaurada + ' SET RECOVERY SIMPLE'
	EXEC(@SQLComand)
	
	-- Guarda o tempo final
	SELECT @Dt_Final = GETDATE()
	
	-- Descrição do Email
	SELECT @Ds_Email_Body = 
	'O Restore foi executado com sucesso!<br/><br/>
	' + '<b>Informações Restore:</b><br/><br/>		
	' + '<b>Servidor:</b> '		+ @@SERVERNAME								+ '<br/><br/>' + '	
	' + '<b>Database Restaurada:</b> '		+ @Nm_Database_Restaurada		+ '<br/><br/>' + '
	' + '<b>Data Inicial:</b> ' + CONVERT(VARCHAR(20), @Dt_Inicial, 120)	+ '<br/><br/>' + '
	' + '<b>Data Final:</b> '	+ CONVERT(VARCHAR(20), @Dt_Final, 120)		+ '<br/><br/>' + '
	' + '<b>Duração:</b>
	' + RIGHT('00' + CAST( (DATEDIFF(SECOND, @Dt_Inicial, @Dt_Final) / 3600) AS VARCHAR(2)), 2)		+ ' Hora(s) ' +
		RIGHT('00' + CAST( (DATEDIFF(SECOND, @Dt_Inicial, @Dt_Final) / 60 % 60) AS VARCHAR(2)), 2)	+ ' Minuto(s) ' +
		RIGHT('00' + CAST( (DATEDIFF(SECOND, @Dt_Inicial, @Dt_Final) % 60) AS VARCHAR(2)), 2)		+ ' Segundo(s) ' + '<br/><br/><br/>' + '
	' + '<b>Informações Backup:</b><br/><br/>
	' + '<b>Nome Database:</b> '		+ @Nm_Database_Backup				+ '<br/><br/>' + '
	' + '<b>Arquivo Backup:</b> '		+ @Ds_Caminho_Backup				+ '<br/><br/>' + '
	' + '<b>Data Backup:</b> '		+ CONVERT(VARCHAR(20), @Dt_Backup, 120)	+ '<br/><br/><br/>' +

	-- Inclui um logo da empresa no final do e-mail
	'<a href="http://www.fabriciolima.net" target=”_blank”> 
		<img	src="http://www.fabriciolima.net/wp-content/uploads/2016/04/Logo_Fabricio-Lima_horizontal.png"
				height="100" width="400"/>
	</a>'

	EXEC msdb.dbo.sp_send_dbmail    
			@profile_name = 'MSSQLServer',	
			@recipients = @Ds_Email,
			@subject = '[Banco de Dados] Solicitação Restore' ,    
			@body = @Ds_Email_Body,    
			@body_format = 'HTML'
END
ELSE
BEGIN
	-- Guarda o tempo final
	SELECT @Dt_Final = GETDATE()
	
	-- Descrição do Email
	SELECT @Ds_Email_Body = 
	'O Restore falhou! Verifique o motivo do erro!<br/><br/><br/>' +
	
	-- Inclui um logo da empresa no final do e-mail
	'<a href="http://www.fabriciolima.net" target=”_blank”> 
		<img	src="http://www.fabriciolima.net/wp-content/uploads/2016/04/Logo_Fabricio-Lima_horizontal.png"
				height="100" width="400"/>
	</a>'

	EXEC msdb.dbo.sp_send_dbmail    
			@profile_name = 'MSSQLServer',	
			@recipients = @Ds_Email,
			@subject = '[Banco de Dados] Solicitação Restore - FALHA!' ,    
			@body = @Ds_Email_Body,    
			@body_format = 'HTML'
END