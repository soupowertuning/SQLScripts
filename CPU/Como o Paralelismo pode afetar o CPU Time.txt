/*
Referência:
https://luizlima.net/dicas-de-tuning-como-o-paralelismo-pode-afetar-o-cpu-time
*/

SET STATISTICS TIME ON

--------------------------------------------------------------------------------------------------------------------------------
-- TESTES PARALELISMO
--------------------------------------------------------------------------------------------------------------------------------
USE Traces

EXEC sp_spaceused TESTE_COLLATION_TABELA_1

-- SEM PARALELISMO
SELECT * 
FROM TESTE_COLLATION_TABELA_1 TAB1
JOIN TESTE_COLLATION_TABELA_1 TAB2 ON TAB1.ID = TAB2.ID
JOIN TESTE_COLLATION_TABELA_1 TAB3 ON TAB2.ID = TAB3.ID
JOIN TESTE_COLLATION_TABELA_1 TAB4 ON TAB3.ID = TAB4.ID
ORDER BY TAB1.ENDERECO
OPTION (MAXDOP 1)

/*
SQL Server Execution Times:
   CPU time = 3062 ms,  elapsed time = 7790 ms.
*/

-- COM PARALELISMO
USE Traces

SELECT * 
FROM TESTE_COLLATION_TABELA_1 TAB1
JOIN TESTE_COLLATION_TABELA_1 TAB2 ON TAB1.ID = TAB2.ID
JOIN TESTE_COLLATION_TABELA_1 TAB3 ON TAB2.ID = TAB3.ID
JOIN TESTE_COLLATION_TABELA_1 TAB4 ON TAB3.ID = TAB4.ID
ORDER BY TAB1.ENDERECO

/*
SQL Server Execution Times:
   CPU time = 9152 ms,  elapsed time = 7408 ms.
*/

--------------------------------------------------------------------------------------------------------------------------------
-- TESTES "COST THRESHOLD FOR PARALLELISM" E "MAX DEGREE OF PARALLELISM"
--------------------------------------------------------------------------------------------------------------------------------
-- Segue abaixo um script de exemplo para alterar os valores dessas configurações.

EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'35'
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO


USE Traces

SELECT * 
FROM TESTE_COLLATION_TABELA_1 TAB1
ORDER BY NOME

/*
-- RESULTADO - COST THRESHOLD FOR PARALLELISM = 35

SQL Server Execution Times:
   CPU time = 515 ms,  elapsed time = 3294 ms.
*/

EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'20'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO

/*
-- RESULTADO - COST THRESHOLD FOR PARALLELISM = 20

SQL Server Execution Times:
   CPU time = 672 ms,  elapsed time = 2850 ms.
*/

SELECT * 
FROM TESTE_COLLATION_TABELA_1 TAB1
ORDER BY NOME

-- RESULTADO - MAX DEGREE OF PARALLELISM = 4
/*
SQL Server Execution Times:
	CPU time = 905 ms,  elapsed time = 2918 ms.
*/

-- RESULTADO - MAX DEGREE OF PARALLELISM = 2
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max degree of parallelism', N'2'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO

/*
SQL Server Execution Times:
	CPU time = 750 ms,  elapsed time = 2984 ms.
*/

-- RESULTADO - MAX DEGREE OF PARALLELISM = 1
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max degree of parallelism', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO

/*
SQL Server Execution Times:
	CPU time = 484 ms,  elapsed time = 3030 ms.
*/