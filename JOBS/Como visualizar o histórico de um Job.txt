SELECT A.Step_Id,B.Name, A.Message, A.Run_Date,A.run_time,A.run_duration,A.run_status
FROM msdb.dbo.Sysjobhistory A
JOIN msdb.dbo.Sysjobs B ON A.Job_Id = B.Job_Id
WHERE B.Name like '%NOME JOB%'
AND A.Run_Date >= '20180624' -- Data em que o job foi executado.
ORDER BY step_id