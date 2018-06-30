Select 
	destination_database_name, 
    restore_date,
    database_name as Source_database,
    physical_device_name as Backup_file_used_to_restore,
    bs.user_name,
    bs.machine_name
from msdb.dbo.restorehistory rh 
inner join msdb.dbo.backupset bs on rh.backup_set_id=bs.backup_set_id
inner join msdb.dbo.backupmediafamily bmf on bs.media_set_id =bmf.media_set_id
--where Destination_database_name = 'NomeDatabase'
ORDER BY [rh].[restore_date] DESC