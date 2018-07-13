use msdb

select (case notify_email_operator_id
		when 0 then 'Disabled'
		else 'Enabled'
		END)as notification, 
		name,
		description,
		(case enabled
		when 0 then 'Disabled'
		else 'Enabled'
		END)as status,
		date_created,
		date_modified
from dbo.sysjobs
where	/*enabled = 1							-- JOBs Habilitados		
		and */name not like 'DBA%'
		and name <> 'syspolicy_purge_history'
		--and notify_email_operator_id = 0	-- Sem Operador de E-mail
order by 1, 2
