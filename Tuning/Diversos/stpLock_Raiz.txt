USE master

GO

--------------------------------------------------------------------------------------------------------------------------------
-- DATABASE:	Traces
-- OBJETIVO:	Armazenar de forma separada nossas rotinas e logs de monitoramento do banco de dados
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
--	1.1) Alterar o caminho para um local existente no seu servidor.
--------------------------------------------------------------------------------------------------------------------------------
CREATE DATABASE [Traces] 
	ON  PRIMARY ( 
		NAME = N'Traces', FILENAME = N'C:\SQLServer\Data\Traces.mdf' , 
		SIZE = 102400KB , FILEGROWTH = 102400KB 
	)
	LOG ON ( 
		NAME = N'Traces_log', FILENAME = N'C:\SQLServer\Log\Traces_log.ldf' , 
		SIZE = 30720KB , FILEGROWTH = 30720KB 
	)
GO

--------------------------------------------------------------------------------------------------------------------------------
-- 1.2) Utilizar o Recovery Model SIMPLE, pois não tem muito impacto perder 1 dia de informação nessa base de log.
--------------------------------------------------------------------------------------------------------------------------------
ALTER DATABASE [Traces] SET RECOVERY SIMPLE

GO

USE [Traces]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:	stpLock_Raiz
-- OBJETIVO:	Retornar apenas os processos envolvidos em Locks no Banco de Dados.
--------------------------------------------------------------------------------------------------------------------------------
/*
Pré-Requisitos:
Segue abaixo alguns pré-requisitos para o funcionamento dessa procedure:

1)	SQL Server: Compatível com a versão 2008 ou superior. 

OBS: Não testei na versão 2005.

2)	Procedure “sp_whoisactive” – Adam Machanic.
Essa procedure é utilizada para retornar os processos que estão sendo executados no banco de dados. Ela é uma mão na roda para todo DBA e muito útil no meu dia a dia.

Download: http://whoisactive.com/downloads/

3)	Criação da base “Traces”.
Em nossas Consultorias, sempre criamos uma base chamada “Traces” para armazenar de forma separada nossas rotinas e logs de monitoramento do banco de dados. Dessa forma, não impactamos nenhuma base do cliente. 

OBS: Você também pode utilizar outro nome para essa base. Basta alterar no script de criação disponibilizado nesse post.
*/

CREATE PROCEDURE [dbo].[stpLock_Raiz]
AS
BEGIN
	-- Cria a tabela que ira armazenar os dados dos processos
	IF ( OBJECT_ID('tempdb..#Resultado_WhoisActive') IS NOT NULL )
		DROP TABLE #Resultado_WhoisActive
  
	CREATE TABLE #Resultado_WhoisActive (  
		[dd hh:mm:ss.mss]  VARCHAR(20),
		[database_name]   NVARCHAR(128),  
		[login_name]   NVARCHAR(128),
		[host_name]    NVARCHAR(128),
		[start_time]   DATETIME,
		[status]    VARCHAR(30),
		[session_id]   INT,
		[blocking_session_id] INT,
		[wait_info]    VARCHAR(MAX),
		[open_tran_count]  INT,
		[CPU]     VARCHAR(MAX),
		[reads]     VARCHAR(MAX),
		[writes]    VARCHAR(MAX),  
		[sql_command]   XML  
	)   
	
	---------------------------------------------------------------------------------------------------------------------------
	-- Carrega os Dados da sp_whoisactive
	--------------------------------------------------------------------------------------------------------------------------------
	-- Retorna todos os processos que estão sendo executados no momento
	EXEC [dbo].[sp_whoisactive]
		@get_outer_command = 1,
		@output_column_list = '[dd hh:mm:ss.mss][database_name][login_name][host_name][start_time][status][session_id][blocking_session_id][wait_info][open_tran_count][CPU][reads][writes][sql_command]',
		@destination_table = '#Resultado_WhoisActive'

	-- Altera a coluna que possui o comando SQL
	ALTER TABLE #Resultado_WhoisActive
	ALTER COLUMN [sql_command] VARCHAR(MAX)
 
	UPDATE #Resultado_WhoisActive
	SET [sql_command] = REPLACE( REPLACE( REPLACE( REPLACE( CAST([sql_command] AS VARCHAR(1000)), '<?query --', ''), '--?>', ''), '&gt;', '>'), '&lt;', '')  

	--------------------------------------------------------------------------------------------------------------------------------
	-- Verifica o Nivel dos Locks
	--------------------------------------------------------------------------------------------------------------------------------
	ALTER TABLE #Resultado_WhoisActive
	ADD Nr_Nivel_Lock TINYINT 

	-- Nivel 0
	UPDATE A
	SET Nr_Nivel_Lock = 0
	FROM #Resultado_WhoisActive A
	WHERE blocking_session_id IS NULL AND session_id IN ( SELECT DISTINCT blocking_session_id 
				FROM #Resultado_WhoisActive WHERE blocking_session_id IS NOT NULL)

	UPDATE A
	SET Nr_Nivel_Lock = 1
	FROM #Resultado_WhoisActive A
	WHERE	Nr_Nivel_Lock IS NULL
			AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 0)

	UPDATE A
	SET Nr_Nivel_Lock = 2
	FROM #Resultado_WhoisActive A
	WHERE	Nr_Nivel_Lock IS NULL
			AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 1)

	UPDATE A
	SET Nr_Nivel_Lock = 3
	FROM #Resultado_WhoisActive A
	WHERE	Nr_Nivel_Lock IS NULL
			AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 2)

	-- Tratamento quando não tem um Lock Raiz
	IF NOT EXISTS(select * from #Resultado_WhoisActive where Nr_Nivel_Lock IS NOT NULL)
	BEGIN
		UPDATE A
		SET Nr_Nivel_Lock = 0
		FROM #Resultado_WhoisActive A
		WHERE session_id IN ( SELECT DISTINCT blocking_session_id 
			FROM #Resultado_WhoisActive WHERE blocking_session_id IS NOT NULL)
          
		UPDATE A
		SET Nr_Nivel_Lock = 1
		FROM #Resultado_WhoisActive A
		WHERE	Nr_Nivel_Lock IS NULL
				AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 0)

		UPDATE A
		SET Nr_Nivel_Lock = 2
		FROM #Resultado_WhoisActive A
		WHERE	Nr_Nivel_Lock IS NULL
				AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 1)

		UPDATE A
		SET Nr_Nivel_Lock = 3
		FROM #Resultado_WhoisActive A
		WHERE	Nr_Nivel_Lock IS NULL
				AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 2)
	END

	-- Retorna o resultado -- incluir nivel
	SELECT
		CAST(Nr_Nivel_Lock AS VARCHAR)       AS [Nr_Nivel_Lock],
		ISNULL([dd hh:mm:ss.mss], '-')       AS [Duração], 
		ISNULL([database_name], '-')       AS [database_name],
		ISNULL([login_name], '-')        AS [login_name],
		ISNULL([host_name], '-')        AS [host_name],
		ISNULL(CONVERT(VARCHAR(20), [start_time], 120), '-') AS [start_time],
		ISNULL([status], '-')         AS [status],
		ISNULL(CAST([session_id] AS VARCHAR), '-')    AS [session_id],
		ISNULL(CAST([blocking_session_id] AS VARCHAR), '-')  AS [blocking_session_id],
		ISNULL([wait_info], '-')        AS [Wait],
		ISNULL(CAST([open_tran_count] AS VARCHAR), '-')   AS [open_tran_count],
		ISNULL([CPU], '-')          AS [CPU],
		ISNULL([reads], '-')         AS [reads],
		ISNULL([writes], '-')         AS [writes],
		[sql_command]
	FROM #Resultado_WhoisActive
	WHERE Nr_Nivel_Lock IS NOT NULL
	ORDER BY [Nr_Nivel_Lock], [start_time] 
END

GO

--------------------------------------------------------------------------------------------------------------------------------
-- SCRIPT TESTE
--------------------------------------------------------------------------------------------------------------------------------
-- QUERY 1
USE Traces
WAITFOR DELAY '00:10:00'

-- QUERY 2
USE Traces
CREATE TABLE TABELA_1 (ID INT) INSERT INTO TABELA_1 VALUES(1)
CREATE TABLE TABELA_2 (ID INT) INSERT INTO TABELA_2 VALUES(2)

GO

BEGIN TRAN

	UPDATE TABELA_1
	SET ID = 3
	WHERE ID = 1

-- ROLLBACK

-- QUERY 3
USE Traces
WAITFOR DELAY '00:10:00'

-- QUERY 4
USE Traces

BEGIN TRAN

	UPDATE TABELA_2
	SET ID = 4
	WHERE ID = 2

	UPDATE TABELA_1
	SET ID = 4
	WHERE ID = 1

-- ROLLBACK

-- QUERY 5
USE Traces
WAITFOR DELAY '00:10:00'

-- QUERY 6
USE Traces

BEGIN TRAN

	UPDATE TABELA_2
	SET ID = 6
	WHERE ID = 2

-- ROLLBACK

--------------------------------------------------------------------------------------------------------------------------------
-- VERIFICAÇÃO DO RESULTADO
--------------------------------------------------------------------------------------------------------------------------------

-- Essa procedure pode ser executada através qualquer database
EXEC sp_whoisactive

USE Traces

EXEC stpLock_Raiz

-- OBS: APOS VERIFICAR O RESULTADO, LEMBRE DE FINALIZAR E FECHAR TODAS AS QUERIES DO TESTE PARA NÃO DEIXAR PROCESSOS BLOQUEADOS NO BANCO DE DADOS!