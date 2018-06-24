-- Procura por uma string dentro dos Jobs
SELECT name NOME_JOB, step_name ,command CODIGO, last_run_date
FROM msdb.dbo.sysjobs A
join msdb.dbo.sysjobsteps B on A.Job_id = B.Job_Id
WHERE command like '%String%'
ORDER BY name