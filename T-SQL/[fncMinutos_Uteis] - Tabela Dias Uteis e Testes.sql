------------------------------------------------------------------------------------------------------------------
-- TABELA DIAS UTEIS
------------------------------------------------------------------------------------------------------------------
USE [Traces]

CREATE TABLE [dbo].[Dias_Uteis] (
	Dt_Referencia DATETIME
)

CREATE CLUSTERED INDEX [PK_Dias_Uteis]
ON [dbo].[Dias_Uteis] (Dt_Referencia)
WITH(FILLFACTOR = 90, DATA_COMPRESSION = PAGE)

-- INSERE DIAS UTEIS NA TABELA -> 2019 E 2020
DECLARE @Dt_Inicial DATETIME = '20190101', @Dt_Final DATETIME = '20210101'

WHILE (@Dt_Inicial < @Dt_Final)
BEGIN
	-- DESCONSIDERA SABADO E DOMINGO
	IF (DATEPART(WEEKDAY, @Dt_Inicial) NOT IN (7, 1) )
	BEGIN
		INSERT INTO [dbo].[Dias_Uteis] VALUES(@Dt_Inicial)
	END

	SELECT @Dt_Inicial = DATEADD(DAY, 1, @Dt_Inicial)
END

-- REMOVE ALGUNS FERIADOS
DELETE [dbo].[Dias_Uteis]
WHERE Dt_Referencia IN ('20190101','20191225','20200101','20201225')

SELECT * FROM [dbo].[Dias_Uteis]
ORDER BY Dt_Referencia


------------------------------------------------------------------------------------------------------------------
-- TESTES
------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
-- TABELA DE TESTES
------------------------------------------------------------------------------------------------------------------
-- DROP TABLE Teste_Minutos_Uteis

USE Traces

CREATE TABLE Teste_Minutos_Uteis (
	Id_Teste INT IDENTITY(1,1) NOT NULL,
	Dt_Referencia DATETIME NOT NULL
)

CREATE NONCLUSTERED INDEX SK01_Teste_Minutos_Uteis
ON Teste_Minutos_Uteis(Dt_Referencia)
WITH(FILLFACTOR=90, DATA_COMPRESSION = PAGE)

GO

INSERT INTO Teste_Minutos_Uteis
VALUES(GETDATE()-1)
GO 1000

INSERT INTO Teste_Minutos_Uteis
VALUES(GETDATE()-2)
GO 1000

SELECT * FROM Teste_Minutos_Uteis
ORDER BY Dt_Referencia


------------------------------------------------------------------------------------------------------------------
-- TESTES FUNCAO COM WHILE
------------------------------------------------------------------------------------------------------------------
USE Traces

SELECT 
	[dbo].[fncMinutos_Uteis_While] ('20200121 08:00', '20200121 12:00') AS Teste_1,
	[dbo].[fncMinutos_Uteis_While] ('20200121 06:00', '20200121 12:00') AS Teste_2,
	[dbo].[fncMinutos_Uteis_While] ('20200121 12:00', '20200121 18:00') AS Teste_3,
	[dbo].[fncMinutos_Uteis_While] ('20200121 12:00', '20200121 23:00') AS Teste_4,
	[dbo].[fncMinutos_Uteis_While] ('20200121 18:30', '20200121 20:00') AS Teste_5,
	[dbo].[fncMinutos_Uteis_While] ('20200121 08:30', '20200121 09:17') AS Teste_6,
	[dbo].[fncMinutos_Uteis_While] ('20200117 17:00', '20200120 09:30') AS Teste_7,
	[dbo].[fncMinutos_Uteis_While] ('20200121 08:00', '20200122 10:00') AS Teste_8

USE Traces

SET STATISTICS IO, TIME ON

DECLARE @Dt_Final DATETIME = GETDATE()

SELECT Dt_Referencia AS Dt_Inicial, @Dt_Final AS Dt_Final, [dbo].[fncMinutos_Uteis_While] (Dt_Referencia, @Dt_Final) AS Minutos_Uteis
FROM Teste_Minutos_Uteis
ORDER BY Minutos_Uteis

/*
SQL Server Execution Times:
   CPU time = 7844 ms,  elapsed time = 11151 ms.
*/

------------------------------------------------------------------------------------------------------------------
-- TESTES FUNCAO SEM WHILE
------------------------------------------------------------------------------------------------------------------
USE Traces

SELECT 
	[dbo].[fncMinutos_Uteis] ('20200121 08:00', '20200121 12:00') AS Teste_1,
	[dbo].[fncMinutos_Uteis] ('20200121 06:00', '20200121 12:00') AS Teste_2,
	[dbo].[fncMinutos_Uteis] ('20200121 12:00', '20200121 18:00') AS Teste_3,
	[dbo].[fncMinutos_Uteis] ('20200121 12:00', '20200121 23:00') AS Teste_4,
	[dbo].[fncMinutos_Uteis] ('20200121 18:30', '20200121 20:00') AS Teste_5,
	[dbo].[fncMinutos_Uteis] ('20200121 08:30', '20200121 09:17') AS Teste_6,
	[dbo].[fncMinutos_Uteis] ('20200117 17:00', '20200120 09:30') AS Teste_7,
	[dbo].[fncMinutos_Uteis] ('20200121 08:00', '20200122 10:00') AS Teste_8

USE Traces

SET STATISTICS IO, TIME ON

DECLARE @Dt_Final DATETIME = GETDATE()

SELECT Dt_Referencia AS Dt_Inicial, @Dt_Final AS Dt_Final, [dbo].[fncMinutos_Uteis] (Dt_Referencia, @Dt_Final) AS Minutos_Uteis
FROM Teste_Minutos_Uteis
ORDER BY Minutos_Uteis

/*
SQL Server Execution Times:
   CPU time = 187 ms,  elapsed time = 296 ms.
*/