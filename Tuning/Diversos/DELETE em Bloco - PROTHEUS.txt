/*
-- Script de Exclusão em Blocos - Diminui a ocorrência de Locks e crescimento elevado do Arquivo de Log

-- 1) Substituir (CTRL + H ) a string "NomeTabela" pelo nome da tabela que ira excluir os registros.
*/

-- Seleciona os registros que serão excluídos. Utiliza a coluna do índice Clustered (UNIQUE).
IF OBJECT_ID('tempdb..#Exclusao_NomeTabela') IS NOT NULL DROP TABLE #Exclusao_NomeTabela

SELECT R_E_C_N_O_
INTO #Exclusao_NomeTabela
FROM NomeTabela (NOLOCK)
WHERE D_E_L_E_T_ = '*'

-- Cria um índice para melhorar a performance
CREATE UNIQUE CLUSTERED INDEX SK01_Exclusao_NomeTabela 
ON #Exclusao_NomeTabela (R_E_C_N_O_)

-- Declaração e definição dos parâmetros do Loop
DECLARE 
	@Loop BIGINT, 
	@Max_Loop BIGINT, 
	@Qtd_Registros_Exclusao INT = 100000

-- Seleciona o menor e maior ID do Loop
SELECT @Loop = MIN(R_E_C_N_O_), @Max_Loop = MAX(R_E_C_N_O_)
FROM #Exclusao_NomeTabela

-- Loop para excluir os registros
WHILE (@Loop <= @Max_Loop)
BEGIN
	-- Exclui os registros da tabela de produção
	DELETE A
	FROM NomeTabela A
	JOIN #Exclusao_NomeTabela B ON A.R_E_C_N_O_ = B.R_E_C_N_O_
	WHERE 
		A.R_E_C_N_O_ >= @Loop 
		AND A.R_E_C_N_O_ < @Loop + @Qtd_Registros_Exclusao
		AND D_E_L_E_T_ = '*'			-- Considera apenas Registros marcados como excluídos na tabela
	
	-- Exclui os registros da tabela de controle do loop
	DELETE FROM #Exclusao_NomeTabela 
	WHERE 
		R_E_C_N_O_ >= @Loop 
		AND R_E_C_N_O_ < @Loop + @Qtd_Registros_Exclusao

	-- Incrementa o contador do Loop
	SET @Loop = @Loop + @Qtd_Registros_Exclusao
	
	-- Comando para evitar Locks demorados.
	WAITFOR DELAY '00:00:00.500'

	-- Descomentar a linha abaixo caso queria acompanhar o andamento do Loop
	-- PRINT @Loop
END