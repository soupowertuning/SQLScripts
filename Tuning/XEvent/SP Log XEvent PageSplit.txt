/*
/*
SELECT db.name,o.name,i.name,ps.Dt_PageSplit
FROM Traces.dbo.Log_PageSplit ps
JOIN sys.indexes AS i    ON ps.object_id = i.object_id        AND ps.index_id = i.index_id
JOIN sys.objects AS o    ON ps.object_id = o.object_id
JOIN sys.databases AS db ON ps.database_id = db.database_id
where i.name = 'SE1010_PK'

*/

SELECT top 20 db.name,o.name,i.name,i.fill_factor,count(*) Qtd_PageSplit
FROM Traces.dbo.Log_PageSplit ps
JOIN sys.indexes AS i    ON ps.object_id = i.object_id        AND ps.index_id = i.index_id
JOIN sys.objects AS o    ON ps.object_id = o.object_id
JOIN sys.databases AS db ON ps.database_id = db.database_id
GROUP BY db.name,o.name,i.name,i.fill_factor
order by 5 DESC

select datepart(hh,Dt_PageSplit),datepart(n,Dt_PageSplit),count(*)
FROM Traces.dbo.Log_PageSplit ps
group by datepart(hh,Dt_PageSplit),datepart(n,Dt_PageSplit)
order by 3 desc



*/
TRUNCATE TABLE Log_PageSplit

CREATE TABLE [dbo].Log_PageSplit(
	[object_id] [INT] NOT NULL,
	[index_id] [INT] NOT NULL,
	[Dt_PageSplit] [DATETIME] NULL,
	[database_id] [TINYINT] NULL
) ON [PRIMARY]


	CREATE CLUSTERED INDEX SK01_Log_PageSplit ON Log_PageSplit(Dt_PageSplit) WITH(FILLFACTOR=90)


ALTER PROCEDURE [stpXEvent_PageSplit]
AS
BEGIN
	-- Stop your Extended Events session
	ALTER EVENT SESSION TrackPageSplits ON SERVER
	STATE = STOP;
	
	INSERT INTO Log_PageSplit([object_id],[index_id],Dt_PageSplit,[database_id])
	SELECT  i.object_id,
		i.index_id,   
		tab.[timestamp],
		tab.database_id
	FROM (
			SELECT
			DATEADD(mi,
			DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
			xevents.event_data.value('(event/@timestamp)[1]', 'datetime')) AS [timestamp],
			xevents.event_data.value('(event/data[@name="database_id"]/value)[1]', 'tinyint') AS database_id,
		--	xevents.event_data.value('(event/data[@name="context"]/text)[1]', 'varchar(100)') AS context,
			xevents.event_data.value('(event/data[@name="alloc_unit_id"]/value)[1]', 'varchar(100)') AS alloc_unit_id
			from sys.fn_xe_file_target_read_file
			('H:\SQL Server\Databases\Traces\TrackPageSplits*.xel',
			'H:\SQL Server\Databases\Traces\TrackPageSplits*.xem',
			null, null)
			cross apply (select CAST(event_data as XML) as event_data) as xevents
			
	) AS tab
	JOIN DADOSADV.sys.allocation_units AS au   ON tab.alloc_unit_id = au.allocation_unit_id
	JOIN DADOSADV.sys.partitions AS p    ON au.container_id = p.partition_id
	JOIN DADOSADV.sys.indexes AS i    ON p.object_id = i.object_id        AND p.index_id = i.index_id
	JOIN DADOSADV.sys.objects AS o    ON p.object_id = o.object_id
	LEFT JOIN Log_PageSplit PS ON PS.object_id = i.object_id AND PS.index_id = i.index_id AND PS.database_id = tab.database_id AND PS.Dt_PageSplit = tab.[timestamp]
	WHERE o.is_ms_shipped = 0
		AND PS.object_id IS null
			
	-- Clean up your session from the server
	DROP EVENT SESSION TrackPageSplits ON SERVER;


	CREATE EVENT SESSION [TrackPageSplits]
	ON    SERVER
	ADD EVENT sqlserver.transaction_log(
		WHERE operation = 11  -- LOP_DELETE_SPLIT 
		  AND 	 database_id = 9 -- CHANGE THIS BASED ON TOP SPLITTING DATABASE!
	)
	ADD TARGET package0.asynchronous_file_target
	(set filename = 'H:\SQL Server\Databases\Traces\TrackPageSplits.xel' ,
	metadatafile = 'H:\SQL Server\Databases\Traces\TrackPageSplits.xem',
	max_file_size = 500,
	max_rollover_files = 5
			)
	WITH (MAX_DISPATCH_LATENCY = 5SECONDS)


	-- Start the session
	ALTER EVENT SESSION [TrackPageSplits]
	ON SERVER STATE = START
END
GO

	
	CREATE EVENT SESSION [TrackPageSplits]
	ON    SERVER
	ADD EVENT sqlserver.transaction_log(
		WHERE operation = 11  -- LOP_DELETE_SPLIT 
		  AND 	 database_id = 9 -- CHANGE THIS BASED ON TOP SPLITTING DATABASE!
	)
	ADD TARGET package0.asynchronous_file_target
	(set filename = 'H:\SQL Server\Databases\Traces\TrackPageSplits.xel' ,
	metadatafile = 'H:\SQL Server\Databases\Traces\TrackPageSplits.xem',
	max_file_size = 500,
	max_rollover_files = 5
			)
	WITH (MAX_DISPATCH_LATENCY = 5SECONDS)


	-- Start the session
	ALTER EVENT SESSION [TrackPageSplits]
	ON SERVER STATE = START


	select * from sys.databases



/*

/*
/*
SELECT db.name,o.name,i.name,ps.Dt_PageSplit
FROM Traces.dbo.Log_PageSplit ps
JOIN sys.indexes AS i    ON ps.object_id = i.object_id        AND ps.index_id = i.index_id
JOIN sys.objects AS o    ON ps.object_id = o.object_id
JOIN sys.databases AS db ON ps.database_id = db.database_id
--where i.name = 'SE1010_PK'


*/

SELECT db.name,o.name,i.name,i.fill_factor,count(*) Qtd_PageSplit,
	'ALTER INDEX '+i.name+ ' ON ' +  o.name + ' REBUILD WITH(DATA_COMPRESSION=PAGE,FILLFACTOR=90)'
FROM Traces.dbo.Log_PageSplit ps
JOIN sys.indexes AS i    ON ps.object_id = i.object_id        AND ps.index_id = i.index_id
JOIN sys.objects AS o    ON ps.object_id = o.object_id
JOIN sys.databases AS db ON ps.database_id = db.database_id
where datepart(hh,Dt_PageSplit) between 9 and 17
--and Dt_PageSplit >= '20171130' and Dt_PageSplit < '20171231' 
and i.fill_factor = 0
GROUP BY db.name,o.name,i.name,i.fill_factor
order by 5 DESC

select datepart(hh,Dt_PageSplit),datepart(n,Dt_PageSplit),count(*)
FROM Traces.dbo.Log_PageSplit ps
where datepart(hh,Dt_PageSplit) between 8 and 17
and Dt_PageSplit >= '20171129' and Dt_PageSplit < '20171130' 
group by datepart(hh,Dt_PageSplit),datepart(n,Dt_PageSplit)
order by 3 desc



*/
TRUNCATE TABLE Log_PageSplit

CREATE TABLE [dbo].Log_PageSplit(
	[object_id] [INT] NOT NULL,
	[index_id] [INT] NOT NULL,
	[Dt_PageSplit] [DATETIME] NULL,
	[database_id] [TINYINT] NULL
) ON [PRIMARY]


	CREATE CLUSTERED INDEX SK01_Log_PageSplit ON Log_PageSplit(Dt_PageSplit) WITH(FILLFACTOR=90)


ALTER PROCEDURE [stpXEvent_PageSplit]
AS
BEGIN
	-- Stop your Extended Events session
	ALTER EVENT SESSION TrackPageSplits ON SERVER
	STATE = STOP;
	
	INSERT INTO Log_PageSplit([object_id],[index_id],Dt_PageSplit,[database_id])
	SELECT  i.object_id,
		i.index_id,   
		tab.[timestamp],
		tab.database_id
	FROM (
			SELECT
			DATEADD(mi,
			DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
			xevents.event_data.value('(event/@timestamp)[1]', 'datetime')) AS [timestamp],
			xevents.event_data.value('(event/data[@name="database_id"]/value)[1]', 'tinyint') AS database_id,
		--	xevents.event_data.value('(event/data[@name="context"]/text)[1]', 'varchar(100)') AS context,
			xevents.event_data.value('(event/data[@name="alloc_unit_id"]/value)[1]', 'varchar(100)') AS alloc_unit_id
			from sys.fn_xe_file_target_read_file
			('H:\SQL Server\Databases\Traces\TrackPageSplits*.xel',
			'H:\SQL Server\Databases\Traces\TrackPageSplits*.xem',
			null, null)
			cross apply (select CAST(event_data as XML) as event_data) as xevents
			
	) AS tab
	JOIN DADOSADV.sys.allocation_units AS au   ON tab.alloc_unit_id = au.allocation_unit_id
	JOIN DADOSADV.sys.partitions AS p    ON au.container_id = p.partition_id
	JOIN DADOSADV.sys.indexes AS i    ON p.object_id = i.object_id        AND p.index_id = i.index_id
	JOIN DADOSADV.sys.objects AS o    ON p.object_id = o.object_id
	LEFT JOIN Log_PageSplit PS ON PS.object_id = i.object_id AND PS.index_id = i.index_id AND PS.database_id = tab.database_id AND PS.Dt_PageSplit = tab.[timestamp]
	WHERE o.is_ms_shipped = 0
		AND PS.object_id IS null
			
	-- Clean up your session from the server
	DROP EVENT SESSION TrackPageSplits ON SERVER;


	CREATE EVENT SESSION [TrackPageSplits]
	ON    SERVER
	ADD EVENT sqlserver.transaction_log(
		WHERE operation = 11  -- LOP_DELETE_SPLIT 
		  AND 	 database_id = 9 -- CHANGE THIS BASED ON TOP SPLITTING DATABASE!
	)
	ADD TARGET package0.asynchronous_file_target
	(set filename = 'H:\SQL Server\Databases\Traces\TrackPageSplits.xel' ,
	metadatafile = 'H:\SQL Server\Databases\Traces\TrackPageSplits.xem',
	max_file_size = 500,
	max_rollover_files = 5
			)
	WITH (MAX_DISPATCH_LATENCY = 5SECONDS)


	-- Start the session
	ALTER EVENT SESSION [TrackPageSplits]
	ON SERVER STATE = START
END
GO

	
	CREATE EVENT SESSION [TrackPageSplits]
	ON    SERVER
	ADD EVENT sqlserver.transaction_log(
		WHERE operation = 11  -- LOP_DELETE_SPLIT 
		  AND 	 database_id = 9 -- CHANGE THIS BASED ON TOP SPLITTING DATABASE!
	)
	ADD TARGET package0.asynchronous_file_target
	(set filename = 'H:\SQL Server\Databases\Traces\TrackPageSplits.xel' ,
	metadatafile = 'H:\SQL Server\Databases\Traces\TrackPageSplits.xem',
	max_file_size = 500,
	max_rollover_files = 5
			)
	WITH (MAX_DISPATCH_LATENCY = 5SECONDS)


	-- Start the session
	ALTER EVENT SESSION [TrackPageSplits]
	ON SERVER STATE = START


	select * from sys.databases



*/
