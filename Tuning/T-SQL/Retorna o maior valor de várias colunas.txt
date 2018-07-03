

--Fonte
https://www.mssqltips.com/sqlservertip/4067/find-max-value-from-multiple-columns-in-a-sql-server-table/


SELECT 
   ID, 
   (SELECT MAX(LastUpdateDate)
      FROM (VALUES (UpdateByApp1Date),(UpdateByApp2Date),(UpdateByApp3Date)) AS UpdateDate(LastUpdateDate)) 
   AS LastUpdateDate
FROM ##TestTable


DECLARE @RecVaga_id int, @Usuario_id INT, @MaiorData datetime

SET @RecVaga_id=359710
SET @Usuario_id=2206280

SELECT @MaiorData =
  (SELECT MAX(LastUpdateDate)
      FROM (VALUES (StatusNeg_Candidato_Date),(Status0_Candidato_Date),(Status1_Candidato_Date)
					,(Status2_Candidato_Date),(Status3_Candidato_Date),(Status4_Candidato_Date)) AS UpdateDate(LastUpdateDate))  
FROM _RIC_Recrutamento_VagaxRec
WHERE RecVaga_ID=@RecVaga_id And Usuario_ID=@Usuario_id

SELECT CASE WHEN @MaiorData = StatusNeg_Candidato_Date THEN 'Eliminado'
	 WHEN @MaiorData = Status0_Candidato_Date THEN 'Interessado'
	 WHEN @MaiorData = Status1_Candidato_Date THEN 'Participando'
	 WHEN @MaiorData = Status2_Candidato_Date THEN 'Desistente'
	 WHEN @MaiorData = Status3_Candidato_Date THEN 'Finalista'
	 WHEN @MaiorData = Status4_Candidato_Date THEN 'Efetivar_Contratado' END	
FROM _RIC_Recrutamento_VagaxRec
WHERE RecVaga_ID=@RecVaga_id And Usuario_ID=@Usuario_id