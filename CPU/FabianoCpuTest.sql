USE tempdb
GO

-- Garantir que ha memória suficiente


-- Gerar uma tabela com a massa de dados suficiente pro teste e estatíticas manipuladas pra enganar o SQL e ele gerar paralelismo.
	IF OBJECT_ID('#TabTest1') IS NOT NULL
	   DROP TABLE #TabTest1;
	CREATE TABLE #TabTest1(Col1 CHAR(500));
	INSERT INTO #TabTest1
	SELECT TOP 20000000 --> --> Você pode ajustar a quantidade de linhas conforme o ambiente. Isso impacta na memoria requerida.
		   CONVERT(CHAR(100), 'Test, fixed data to be used on test') AS Col1
	FROM master.dbo.sysobjects A,
		 master.dbo.sysobjects B,
		 master.dbo.sysobjects C,
		 master.dbo.sysobjects D
	OPTION (MAXDOP 1);
	GO
	UPDATE STATISTICS #TabTest1 WITH ROWCOUNT = 100000, PAGECOUNT = 10000

-- Garantir que toda a tabela vai estar em memória.
SELECT COUNT(*) FROM #TabTest1


SET STATISTICS IO, TIME ON
GO

	-- Ajustar o maxdop de 2 em 2 e ir comparando co o outro
	print 'MAXDOP 1'
	SELECT TOP 100 * FROM #TabTest1
	ORDER BY Col1
	OPTION (MAXDOP 1)
	
	print 'MAXDOP 2'
	SELECT TOP 100 * FROM #TabTest1
	ORDER BY Col1
	OPTION (MAXDOP 2)
	
	print 'MAXDOP 4'
	SELECT TOP 100 * FROM #TabTest1
	ORDER BY Col1
	OPTION (MAXDOP 4)

SET STATISTICS IO, TIME OFF
GO
