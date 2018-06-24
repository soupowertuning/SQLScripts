
select SCHEMA_NAME (o.SCHEMA_ID) SchemaName
  ,o.name ObjectName,i.name IndexName
  ,i.type_desc
  ,LEFT(list, ISNULL(splitter-1,len(list)))Columns
  , SUBSTRING(list, indCol.splitter+1, 1000) includedColumns--len(name) - splitter-1) columns
  , COUNT(1)over (partition by o.object_id)
from sys.indexes i
join sys.objects o on i.object_id= o.object_id
cross apply (select NULLIF(charindex('|',indexCols.list),0) splitter , list
             from (select cast((
                          select case when sc.is_included_column = 1 and sc.ColPos= 1 then'|'else '' end +
                                 case when sc.ColPos > 1 then ', ' else ''end + name
                            from (select sc.is_included_column, index_column_id, name
                                       , ROW_NUMBER()over (partition by sc.is_included_column
                                                            order by sc.index_column_id)ColPos
                                   from sys.index_columns  sc
                                   join sys.columns        c on sc.object_id= c.object_id
                                                            and sc.column_id = c.column_id
                                  where sc.index_id= i.index_id
                                    and sc.object_id= i.object_id) sc
                   order by sc.is_included_column
                           ,ColPos
                     for xml path (''),type) as varchar(max)) list)indexCols) indCol
where indCol.splitter is not null
order by SchemaName, ObjectName, IndexName
