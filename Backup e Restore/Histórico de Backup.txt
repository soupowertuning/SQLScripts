--------------------------------------------------------------------------------------------------------------------------------
--	Query para conferir o histórico de Backups que foram executados
--------------------------------------------------------------------------------------------------------------------------------
SELECT	database_name, name,backup_start_date, datediff(mi, backup_start_date, backup_finish_date) [tempo (min)],
		position, server_name, recovery_model, isnull(logical_device_name, ' ') logical_device_name, device_type, 
		type, cast(backup_size/1024/1024 as numeric(15,2)) [Tamanho (MB)], B.is_copy_only
FROM msdb.dbo.backupset B
	  INNER JOIN msdb.dbo.backupmediafamily BF ON B.media_set_id = BF.media_set_id
where backup_start_date >=  dateadd(hh, -24 ,getdate()  )
  and type in ('D','I')
--	and database_name = 'NomeDatabase'
order by backup_start_date desc

--	Guardem muito bem essa query que utilizaram uma infinidade de vezes como DBA para conferir Backups!!!
--	D = FULL, I = Diferencial, L = Log


/*
https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-backup-devices-transact-sql


Coluna device_type

2 = Disk

3 = Diskette (obsolete)

5 = Tape

6 = Pipe (obsolete)

7 = Virtual device (for optional use by third-party backup vendors)

Typically, only disk (2) and tape (5) are used.

De <https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-backup-devices-transact-sql> 
*/