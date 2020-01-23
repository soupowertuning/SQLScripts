USE [Traces]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fncMinutos_Uteis_While] (@Dt_Inicial DATETIME, @Dt_Final DATETIME)
RETURNS BIGINT 
AS
BEGIN
	DECLARE @Qt_Minutos BIGINT = 0
	
	-- Loop para somar minuto a minuto na data inicial até chegar na data final
	WHILE (@Dt_Inicial < @Dt_Final)
	BEGIN
		-- Valida se é um minuto 
		IF (
			DATEPART(WEEKDAY, @Dt_Inicial) NOT IN (1,7)										-- Desconsidera sábados e domingos
			AND (DATEPART(HOUR, @Dt_Inicial) >= 8 AND DATEPART(HOUR, @Dt_Inicial) < 18)		-- Valida se está entre as 8 e 18 horas
		)
		BEGIN
			-- Soma um minuto no resultado
			SELECT @Qt_Minutos = @Qt_Minutos + 1
		END

		-- Soma um minuto na data inicial
		SELECT @Dt_Inicial = DATEADD(MINUTE, 1, @Dt_Inicial)
	END

	-- Retorna a quantidade total de minutos úteis
	RETURN  @Qt_Minutos
END
GO