--Conferindo os Operators existentes
 select O.name,o.email_address,*
 FROM msdb.dbo.sysjobs A
 LEFT JOIN msdb.dbo.sysoperators O
 ON A.notify_email_operator_id = O.[id]
 where A.enabled = 1
 order by O.name


--Check to see if operator exists currently:
 SELECT [name], [id], [enabled]
 FROM msdb.dbo.sysoperators
 ORDER BY [name];
 
--Declare variables and set values:
 DECLARE @operator_id int
 
SELECT @operator_id = [id]
 FROM msdb.dbo.sysoperators
 WHERE name = 'Alerta_BD'
 
--Update the affected rows with new operator_id:
 UPDATE msdb.dbo.sysjobs
 SET notify_email_operator_id = @operator_id
 FROM msdb.dbo.sysjobs
 LEFT JOIN msdb.dbo.sysoperators O
 ON msdb.dbo.sysjobs.notify_email_operator_id = O.[id]
 WHERE O.[id] <> @operator_id;
 
