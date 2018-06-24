-- SQL 2000 e posteriores
SELECT B.name ,
case type when 'P' then 'Stored procedure'
when 'FN' then 'Function'
when 'TF' then 'Function'
when 'TR' then 'Trigger'
when 'V' then 'View'
else 'Outros Objetos'
end
FROM syscomments A (nolock)
JOIN sysobjects B (nolock) on A.Id = B.Id
WHERE A.Text like '%Nome_Objeto%'  --Objto a ser procurado
ORDER BY 2 DESC

-- 2005/2008
SELECT type_desc, obj.name AS SP_NAME,  sqlmod.definition AS SP_DEFINITION
FROM sys.sql_modules AS sqlmod
INNER JOIN sys.objects AS obj ON sqlmod.object_id = obj.object_id
WHERE sqlmod.definition LIKE '%Nome_Objeto%'  --Objto a ser procurado
ORDER BY type_desc
