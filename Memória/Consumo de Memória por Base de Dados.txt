

--Memória por base de dados
SELECT  CASE database_id
          WHEN 32767 THEN 'ResourceDb'
          ELSE DB_NAME(database_id)
        END AS database_name ,
        COUNT(*) AS cached_pages_count ,
        COUNT(*) * .0078125 AS cached_megabytes /* Each page is 8kb, which is .0078125 of an MB */
FROM    sys.dm_os_buffer_descriptors
GROUP BY DB_NAME(database_id) ,
        database_id
ORDER BY cached_pages_count DESC ;


/*
--Se quiserem guardar um histórico disso

CREATE TABLE [dbo].[Log_Memoria_Databases](
	[database_name] [nvarchar](128) NULL,
	[cached_pages_count] [int] NULL,
	[cached_megabytes] [numeric](18, 7) NULL,
	[Dt_log] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[Log_Memoria_Databases] ADD  DEFAULT (getdate()) FOR [Dt_log]

insert  into Log_Memoria_Databases(database_name,cached_pages_count,cached_megabytes)
SELECT  CASE database_id
          WHEN 32767 THEN 'ResourceDb'
          ELSE DB_NAME(database_id)
        END AS database_name ,
        COUNT(*) AS cached_pages_count ,
        COUNT(*) * .0078125 AS cached_megabytes 
FROM    sys.dm_os_buffer_descriptors
GROUP BY DB_NAME(database_id) ,
        database_id
ORDER BY cached_pages_count DESC ;

*/