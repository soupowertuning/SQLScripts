select *
from msdb.dbo.sysmail_profile p 
join msdb.dbo.sysmail_profileaccount pa on p.profile_id = pa.profile_id 
join msdb.dbo.sysmail_account a on pa.account_id = a.account_id 
join msdb.dbo.sysmail_server s on a.account_id = s.account_id