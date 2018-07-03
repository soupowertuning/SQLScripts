SELECT name [Banco de Dados], MAX(CAST(dt AS SMALLDATETIME)) [Último Acesso]
FROM (
	SELECT d.name, MAX(last_user_seek) DT1, MAX(last_user_scan) DT2
		, MAX(last_user_lookup) DT3, MAX(last_user_update) DT4
		, (SELECT create_date FROM sys.databases WHERE database_id = 2) DT5
	FROM sys.dm_db_index_usage_stats v
		RIGHT JOIN sys.databases d
			ON v.database_id = d.database_id
	WHERE d.database_id > 4
	GROUP BY d.name
	) P
	UNPIVOT (dt FOR a IN (DT1, DT2, DT3, DT4, DT5)) AS UP
GROUP BY name
ORDER BY 2