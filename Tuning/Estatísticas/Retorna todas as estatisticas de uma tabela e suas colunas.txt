-- Retorna todas as estat?sticas de uma tabela com suas colunas
SELECT OBJECT_NAME(sc2.object_id) AS TableName , s.name AS StatisticsName , s.stats_id , s.auto_created , 
	ColList = SUBSTRING((SELECT ( ', ' + c1.name )
						FROM sys.stats_columns sc1 JOIN sys.columns c1 
						ON sc1.object_id = c1.object_id
						AND sc1.column_id = c1.column_id 
						WHERE sc1.object_id = sc2.object_id 
						AND sc1.stats_id = s.stats_id 
						ORDER BY sc1.stats_id, sc1.stats_column_id, c1.name                          
						FOR XML PATH( '' ) ), 3, 4000 ) 
FROM sys.stats_columns sc2 
	JOIN sys.columns c2 ON sc2.object_id = c2.object_id AND sc2.column_id = c2.column_id  
	JOIN sys.stats s ON sc2.object_id = s.object_id AND sc2.stats_id = s.stats_id 
--WHERE sc2.object_id = object_id('Tablename') -- Colocar o nome da tabela aqui
GROUP BY  sc2.object_id, s.name , s.stats_id , s.auto_created 
ORDER BY SUBSTRING((SELECT ( ', ' + c1.name )
						FROM sys.stats_columns sc1 JOIN sys.columns c1 
						ON sc1.object_id = c1.object_id
						AND sc1.column_id = c1.column_id 
						WHERE sc1.object_id = sc2.object_id 
						AND sc1.stats_id = s.stats_id 
						ORDER BY sc1.stats_id, sc1.stats_column_id, c1.name                          
						FOR XML PATH( '' ) ), 3, 4000 ) 