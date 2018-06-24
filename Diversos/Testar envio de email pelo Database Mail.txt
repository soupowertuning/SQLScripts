--Email simples
EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'MSSQLServer', --coloque sei profile aqui
@recipients = 'XXX@fabriciolima.net', --coloque seu e-mail aqui
@body = 'Se você receber esse e-mail, o recurso Database Mail está funcionando',
@subject = 'Verificação do Recurso Database Mail'

--conferir o status dos emails enviados
select top 5 sent_status,* from msdb.dbo.sysmail_mailitems order by send_request_date desc
select top 5 sent_status,* from msdb.dbo.sysmail_unsentitems order by send_request_date desc
select top 5 sent_status,* from msdb.dbo.sysmail_faileditems order by send_request_date desc
