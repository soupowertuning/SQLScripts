--PLE ao vivo
SELECT * 
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Page life expectancy'
AND object_name LIKE '%Buffer Manager%'


--Valores de referência:		
/*	<10 : excessivamente baixo, podendo gerar erros, asserts e dumps
	<300 : baixo
	1000: razoável
	5000 : bom
*/
