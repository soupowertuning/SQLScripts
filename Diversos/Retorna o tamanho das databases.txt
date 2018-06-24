if object_id('Tempdb..#tabelas') is not null drop table #tabelas

;with table_space_usage (schema_name,table_Name,index_Name,used,reserved,ind_rows,tbl_rows,type_Desc)
AS(
select s.name, o.name,coalesce(i.name,'heap'),p.used_page_Count*8,
p.reserved_page_count*8, p.row_count ,
case when i.index_id in (0,1) then p.row_count else 0 end, i.type_Desc
from sys.dm_db_partition_stats p
join sys.objects o on o.object_id = p.object_id
join sys.schemas s on s.schema_id = o.schema_id
left join sys.indexes i on i.object_id = p.object_id and i.index_id = p.index_id
where o.type_desc = 'user_Table' and o.is_Ms_shipped = 0
)

-- sp_spaceused
select t.schema_name, t.table_Name,t.index_name,sum(t.used) as used_in_kb,
sum(t.reserved) as reserved_in_kb,
case grouping (t.index_name) when 0 then sum(t.ind_rows) else sum(t.tbl_rows) end as rows,type_Desc
into #tabelas
from table_space_usage t
group by t.schema_name, t.table_Name,t.index_Name,type_Desc
with rollup
order by grouping(t.schema_name),t.schema_name,grouping(t.table_Name),t.table_Name,
grouping(t.index_Name),t.index_name

if object_id('Tempdb..#Resultado_Final') is not null drop table #Resultado_Final

select Schema_Name, Table_Name Name,sum(reserved_in_kb) [Reservado (KB)], sum(case when Type_Desc in ('CLUSTERED','HEAP') then reserved_in_kb else 0 end) [Dados (KB)], 
	sum(case when Type_Desc in ('NONCLUSTERED') then reserved_in_kb else 0 end) [Indices (KB)],
	max(rows) Qtd_Linhas		
into #Resultado_Final
from #tabelas
where index_Name is not null
		and Type_Desc is not null
group by Schema_Name, Table_Name
--having sum(reserved_in_kb) > 10000
order by 3 desc

select * from #Resultado_Final