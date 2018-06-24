;with tab(session_id, host_name, login_name, totalalocadomb, text)
as(
SELECT a.session_id,
b.host_name,
b.login_name,
( user_objects_alloc_page_count + internal_objects_alloc_page_count ) * 1.0 / 128 AS totalalocadomb,
d.TEXT
FROM sys.dm_db_session_space_usage a
JOIN sys.dm_exec_sessions b ON a.session_id = b.session_id
JOIN sys.dm_exec_connections c ON c.session_id = b.session_id
CROSS APPLY sys.Dm_exec_sql_text(c.most_recent_sql_handle) AS d
WHERE a.session_id > 50
--AND ( user_objects_alloc_page_count + internal_objects_alloc_page_count ) * 1.0 / 128 > 10 -- Ocupam mais de 10 MB
)
select * from tab
union all
select null,null,'TOTAL ALOCADO',sum(totalalocadomb),null from tab
