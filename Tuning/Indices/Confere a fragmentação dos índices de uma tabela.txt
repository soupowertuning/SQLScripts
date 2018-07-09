Declare @Nm_Tabela varchar(50)
Set @Nm_Tabela = ''
select getdate(), @@servername,  db_Name(db_id()), @Nm_Tabela , B.Name, avg_fragmentation_in_percent,page_Count,fill_factor	
from sys.dm_db_index_physical_stats(db_id(),object_Id(@Nm_Tabela),null,null,null) A
	join sys.indexes B on a.object_id = B.Object_id and A.index_id = B.index_id
where Page_Count > 1000 
