-- Verifica Status das solicitações de envio de Email
select 
	top 50 sent_status, CASE sent_status
        WHEN 0 THEN 'Unsent'
        WHEN 1 THEN 'Sent'
        WHEN 2 THEN 'Failed'
        WHEN 3 THEN 'Retrying'
	END as sent_status_description, send_request_date, * 
from msdb.dbo.sysmail_mailitems 
order by 3 desc


-- Verifica Motivo Falha Envio Email
SELECT
    SEL.event_type,
    SEL.log_date,
    SEL.description,
    SF.mailitem_id,
    SF.recipients,
    SF.copy_recipients,
    SF.blind_copy_recipients,
    SF.subject,
    SF.body,
    SF.sent_status,
    SF.sent_date
FROM
    msdb.dbo.sysmail_faileditems AS SF JOIN
    msdb.dbo.sysmail_event_log AS SEL
        ON SF.mailitem_id = SEL.mailitem_id
order by log_date DESC


select top 50 sent_status,* from msdb.dbo.sysmail_unsentitems order by send_request_date desc


select top 50 sent_status,* from msdb.dbo.sysmail_faileditems order by send_request_date desc


-- TESTE ENVIO DE EMAIL
EXEC msdb.dbo.sp_send_dbmail    
		@profile_name = 'MSSQLServer',	
		@recipients = 'email@dominio.com.br', 		
		@subject = 'TESTE - ASSUNTO' ,    
		@body = 'TESTE - CORPO' ,
@body_format = 'HTML'