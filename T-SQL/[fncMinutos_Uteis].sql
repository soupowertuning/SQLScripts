USE [Traces]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fncMinutos_Uteis] (@Dt_Inicial DATETIME, @Dt_Final DATETIME)
RETURNS BIGINT
AS 
BEGIN
	-- P/ TESTE
	--DECLARE @Dt_Inicial DATETIME = '2020-01-03 11:33:12.000', @Dt_Final DATETIME = '2020-01-07 19:15:50.000'

	DECLARE @Qt_Dias_Uteis BIGINT = 0, @Qt_Minutos_Uteis BIGINT = 0, @Dt_Referencia_08 DATETIME, @Dt_Referencia_18 DATETIME

	-- SE A DATA INICIAL FOR MAIOR DO QUE A DATA FINAL, DEVE RETORNAR 0
	IF ( @Dt_Inicial > @Dt_Final )
	BEGIN
		SELECT @Qt_Minutos_Uteis = 0
		RETURN @Qt_Minutos_Uteis
	END

	-- VALIDA SE AS DATAS SAO NO MESMO DIA
	IF ( CAST(@Dt_Inicial AS DATE) = CAST(@Dt_Final AS DATE) )
	BEGIN
		-- VALIDA SE É UM DIA UTIL
		IF EXISTS( SELECT Dt_Referencia FROM dbo.Dias_Uteis WITH(NOLOCK) WHERE Dt_Referencia = CAST(@Dt_Inicial AS DATE) )
		BEGIN
			-- SE A HORA DA DATA INICIAL FOR MAIOR DO QUE 18, DEVE RETORNAR 0
			IF ( DATEPART(HOUR,@Dt_Inicial) >= 18 )
			BEGIN
				SELECT @Qt_Minutos_Uteis = 0
				RETURN @Qt_Minutos_Uteis
			END 
			ELSE
			BEGIN
				-- DATA DE REFERENCIA AS 08:00 HORAS
				SELECT @Dt_Referencia_08 = DATEADD(HOUR, 8, CAST(CAST(@Dt_Inicial AS DATE) AS DATETIME))
				
				-- DATA DE REFERENCIA AS 18:00 HORAS
				SELECT @Dt_Referencia_18 = DATEADD(HOUR, 10, @Dt_Referencia_08)

				SELECT @Qt_Minutos_Uteis =
					DATEDIFF(MINUTE, @Dt_Inicial, @Dt_Final)
					
					-- DESCONSIDERA OS MINUTOS ENTRE A DATA INICIO E AS 08:00 HORAS				
					-	CASE WHEN DATEDIFF(MINUTE, @Dt_Inicial, @Dt_Referencia_08) > 0
							THEN
								DATEDIFF(MINUTE, @Dt_Inicial, @Dt_Referencia_08)
							ELSE
								0
						END
					
					-- DESCONSIDERA OS MINUTOS ENTRE AS 18:00 HORAS E A DATA FINAL
					-	CASE WHEN DATEDIFF(MINUTE, @Dt_Referencia_18, @Dt_Final) > 0
							THEN
								DATEDIFF(MINUTE, @Dt_Referencia_18, @Dt_Final)
							ELSE
								0
						END

				RETURN @Qt_Minutos_Uteis
			END
		END
		-- SE NAO FOR DIA UTIL, DEVE RETORNAR 0
		ELSE
		BEGIN
			SELECT @Qt_Minutos_Uteis = 0
			RETURN @Qt_Minutos_Uteis
		END
	END
	-- POSSUI MAIS DE UM DIA DE DIFERENCA ENTRE AS DATAS
	ELSE
	BEGIN
		-- RETORNA A QUANTIDADE DE DIAS UTEIS
		SELECT @Qt_Dias_Uteis = COUNT(*)
		FROM dbo.Dias_Uteis
		WHERE 
			Dt_Referencia >= CAST(@Dt_Inicial AS DATE)
			AND Dt_Referencia <= CAST(@Dt_Final AS DATE)
			
		-- TRANSFORMA OS DIAS UTEIS EM MINUTOS UTEIS
		-- 1 DIA UTIL = 10 HORAS UTEIS = 10 * 60 = 600 MINUTOS UTEIS
		SELECT @Qt_Minutos_Uteis = @Qt_Dias_Uteis * 600
		
		-------------------------------------------------------------------------------------
		-- DATA INICIAL
		-------------------------------------------------------------------------------------
		-- VALIDA SE É UM DIA UTIL
		IF EXISTS( SELECT Dt_Referencia FROM dbo.Dias_Uteis WITH(NOLOCK) WHERE Dt_Referencia = CAST(@Dt_Inicial AS DATE) )
		BEGIN
			-- SE A HORA DA DATA INICIAL FOR MAIOR DO QUE 18 HORAS, DEVE SUBTRAIR UM DIA INTEIRO
			IF ( DATEPART(HOUR,@Dt_Inicial) >= 18 )
			BEGIN
				SELECT @Qt_Minutos_Uteis -= 600				
			END 
			ELSE
			BEGIN
				-- DATA DE REFERENCIA AS 08:00 HORAS
				SELECT @Dt_Referencia_08 = DATEADD(HOUR, 8, CAST(CAST(@Dt_Inicial AS DATE) AS DATETIME))
				
				SELECT @Qt_Minutos_Uteis =
					@Qt_Minutos_Uteis
					--
					- CASE WHEN DATEDIFF(MINUTE, @Dt_Referencia_08, @Dt_Inicial) > 0
							THEN
								DATEDIFF(MINUTE, @Dt_Referencia_08, @Dt_Inicial)
							ELSE
								0
						END
			END
		END
		-- SE NAO FOR DIA UTIL, DEVE RETORNAR 0
		ELSE
		BEGIN
			SELECT @Qt_Minutos_Uteis = 0
		END

		-------------------------------------------------------------------------------------
		-- DATA FINAL
		-------------------------------------------------------------------------------------
		-- VALIDA SE É UM DIA UTIL
		IF EXISTS( SELECT Dt_Referencia FROM dbo.Dias_Uteis WITH(NOLOCK) WHERE Dt_Referencia = CAST(@Dt_Final AS DATE) )
		BEGIN
			-- SE A HORA DA DATA FINAL FOR MENOR DO QUE 08 HORAS, DEVE SUBTRAIR UM DIA INTEIRO
			IF ( DATEPART(HOUR,@Dt_Final) < 8 )
			BEGIN
				SELECT @Qt_Minutos_Uteis -= 600
			END 
			ELSE
			BEGIN
				-- DATA DE REFERENCIA AS 18:00 HORAS
				SELECT @Dt_Referencia_18 = DATEADD(HOUR, 18, CAST(CAST(@Dt_Final AS DATE) AS DATETIME))
				
				SELECT @Qt_Minutos_Uteis =
					@Qt_Minutos_Uteis
					--
					- CASE WHEN DATEDIFF(MINUTE, @Dt_Final, @Dt_Referencia_18) > 0
							THEN
								DATEDIFF(MINUTE, @Dt_Final, @Dt_Referencia_18)
							ELSE
								0
						END		
			END
		END
		-- SE NAO FOR DIA UTIL, DEVE RETORNAR 0
		ELSE
		BEGIN
			SELECT @Qt_Minutos_Uteis = 0
		END

		RETURN @Qt_Minutos_Uteis
	END

	RETURN @Qt_Minutos_Uteis
END