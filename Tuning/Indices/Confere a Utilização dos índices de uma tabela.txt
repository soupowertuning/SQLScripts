
select getdate(), o.Name,i.name, s.user_seeks,s.user_scans,s.user_lookups, s.user_Updates, 
	isnull(s.last_user_seek,isnull(s.last_user_scan,s.last_User_Lookup)) Ultimo_acesso,fill_factor
from sys.dm_db_index_usage_stats s
	 join sys.indexes i on i.object_id = s.object_id and i.index_id = s.index_id
	 join sys.sysobjects o on i.object_id = o.id
where s.database_id = db_id() and o.name in ('NOMETABELA') --and i.name = 'SK02_Telefone_Cliente'
order by s.user_seeks + s.user_scans + s.user_lookups desc
