-- Monitoramento de fila de disco
SELECT DB_NAME(mf.database_id) AS [Database]
		, mf.physical_name
		, r.io_pending
		, r.io_pending_ms_ticks
		, r.io_type
		, fs.num_of_reads
		, fs.num_of_writes
		, GETDATE()
FROM sys.dm_io_pending_io_requests AS r
INNER JOIN sys.dm_io_virtual_file_stats(null,null) AS fs ON r.io_handle = fs.file_handle 
INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id AND fs.file_id = mf.file_id
ORDER BY r.io_pending, r.io_pending_ms_ticks DESC