SELECT
    [sJOB].[name] AS [JobName] ,
    CASE [sJOB].[enabled]
      WHEN 1 THEN 'Yes'
      WHEN 0 THEN 'No'
    END AS [IsEnabled] ,
    [sJOB].[date_created] AS [JobCreatedOn] ,
    [sJOB].[date_modified] AS [JobLastModifiedOn] ,
    [sJSTP].[step_id] AS [StepNo] ,
    [sJSTP].[step_name] AS [StepName] ,
    [sDBP].[name] AS [JobOwner] ,
    [sCAT].[name] AS [JobCategory] ,
    [sJOB].[description] AS [JobDescription] ,
    CASE [sJSTP].[subsystem]
      WHEN 'ActiveScripting' THEN 'ActiveX Script'
      WHEN 'CmdExec' THEN 'Operating system (CmdExec)'
      WHEN 'PowerShell' THEN 'PowerShell'
      WHEN 'Distribution' THEN 'Replication Distributor'
      WHEN 'Merge' THEN 'Replication Merge'
      WHEN 'QueueReader' THEN 'Replication Queue Reader'
      WHEN 'Snapshot' THEN 'Replication Snapshot'
      WHEN 'LogReader' THEN 'Replication Transaction-Log Reader'
      WHEN 'ANALYSISCOMMAND' THEN 'SQL Server Analysis Services Command'
      WHEN 'ANALYSISQUERY' THEN 'SQL Server Analysis Services Query'
      WHEN 'SSIS' THEN 'SQL Server Integration Services Package'
      WHEN 'TSQL' THEN 'Transact-SQL script (T-SQL)'
      ELSE sJSTP.subsystem
    END AS [StepType] ,
    [sPROX].[name] AS [RunAs] ,
    [sJSTP].[database_name] AS [Database] ,
    REPLACE(REPLACE(REPLACE([sJSTP].[command], CHAR(10) + CHAR(13), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [ExecutableCommand] ,
    CASE [sJSTP].[on_success_action]
      WHEN 1 THEN 'Quit the job reporting success'
      WHEN 2 THEN 'Quit the job reporting failure'
      WHEN 3 THEN 'Go to the next step'
      WHEN 4 THEN 'Go to Step: ' + QUOTENAME(CAST([sJSTP].[on_success_step_id] AS VARCHAR(3))) + ' ' + [sOSSTP].[step_name]
    END AS [OnSuccessAction] ,
    [sJSTP].[retry_attempts] AS [RetryAttempts] ,
    [sJSTP].[retry_interval] AS [RetryInterval (Minutes)] ,
    CASE [sJSTP].[on_fail_action]
      WHEN 1 THEN 'Quit the job reporting success'
      WHEN 2 THEN 'Quit the job reporting failure'
      WHEN 3 THEN 'Go to the next step'
      WHEN 4 THEN 'Go to Step: ' + QUOTENAME(CAST([sJSTP].[on_fail_step_id] AS VARCHAR(3))) + ' ' + [sOFSTP].[step_name]
    END AS [OnFailureAction],
    CASE
        WHEN [sSCH].[schedule_uid] IS NULL THEN 'No'
        ELSE 'Yes'
      END AS [IsScheduled],
    [sSCH].[name] AS [JobScheduleName],
    CASE 
        WHEN [sSCH].[freq_type] = 64 THEN 'Start automatically when SQL Server Agent starts'
        WHEN [sSCH].[freq_type] = 128 THEN 'Start whenever the CPUs become idle'
        WHEN [sSCH].[freq_type] IN (4,8,16,32) THEN 'Recurring'
        WHEN [sSCH].[freq_type] = 1 THEN 'One Time'
    END [ScheduleType], 
    CASE [sSCH].[freq_type]
        WHEN 1 THEN 'One Time'
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN 'Weekly'
        WHEN 16 THEN 'Monthly'
        WHEN 32 THEN 'Monthly - Relative to Frequency Interval'
        WHEN 64 THEN 'Start automatically when SQL Server Agent starts'
        WHEN 128 THEN 'Start whenever the CPUs become idle'
  END [Occurrence], 
  CASE [sSCH].[freq_type]
        WHEN 4 THEN 'Occurs every ' + CAST([freq_interval] AS VARCHAR(3)) + ' day(s)'
        WHEN 8 THEN 'Occurs every ' + CAST([freq_recurrence_factor] AS VARCHAR(3)) + ' week(s) on '
                + CASE WHEN [sSCH].[freq_interval] & 1 = 1 THEN 'Sunday' ELSE '' END
                + CASE WHEN [sSCH].[freq_interval] & 2 = 2 THEN ', Monday' ELSE '' END
                + CASE WHEN [sSCH].[freq_interval] & 4 = 4 THEN ', Tuesday' ELSE '' END
                + CASE WHEN [sSCH].[freq_interval] & 8 = 8 THEN ', Wednesday' ELSE '' END
                + CASE WHEN [sSCH].[freq_interval] & 16 = 16 THEN ', Thursday' ELSE '' END
                + CASE WHEN [sSCH].[freq_interval] & 32 = 32 THEN ', Friday' ELSE '' END
                + CASE WHEN [sSCH].[freq_interval] & 64 = 64 THEN ', Saturday' ELSE '' END
        WHEN 16 THEN 'Occurs on Day ' + CAST([freq_interval] AS VARCHAR(3)) + ' of every ' + CAST([sSCH].[freq_recurrence_factor] AS VARCHAR(3)) + ' month(s)'
        WHEN 32 THEN 'Occurs on '
                 + CASE [sSCH].[freq_relative_interval]
                    WHEN 1 THEN 'First'
                    WHEN 2 THEN 'Second'
                    WHEN 4 THEN 'Third'
                    WHEN 8 THEN 'Fourth'
                    WHEN 16 THEN 'Last'
                   END
                 + ' ' 
                 + CASE [sSCH].[freq_interval]
                    WHEN 1 THEN 'Sunday'
                    WHEN 2 THEN 'Monday'
                    WHEN 3 THEN 'Tuesday'
                    WHEN 4 THEN 'Wednesday'
                    WHEN 5 THEN 'Thursday'
                    WHEN 6 THEN 'Friday'
                    WHEN 7 THEN 'Saturday'
                    WHEN 8 THEN 'Day'
                    WHEN 9 THEN 'Weekday'
                    WHEN 10 THEN 'Weekend day'
                   END
                 + ' of every ' + CAST([sSCH].[freq_recurrence_factor] AS VARCHAR(3)) + ' month(s)'
    END AS [Recurrence], 
    CASE [sSCH].[freq_subday_type]
        WHEN 1 THEN 'Occurs once at ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_start_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        WHEN 2 THEN 'Occurs every ' + CAST([sSCH].[freq_subday_interval] AS VARCHAR(3)) + ' Second(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_start_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')+ ' & ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_end_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        WHEN 4 THEN 'Occurs every ' + CAST([sSCH].[freq_subday_interval] AS VARCHAR(3)) + ' Minute(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_start_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')+ ' & ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_end_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        WHEN 8 THEN 'Occurs every ' + CAST([sSCH].[freq_subday_interval] AS VARCHAR(3)) + ' Hour(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_start_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')+ ' & ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_end_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
    END [Frequency], 
    STUFF(STUFF(CAST([sSCH].[active_start_date] AS VARCHAR(8)), 5, 0, '-'), 8, 0, '-') AS [ScheduleUsageStartDate], 
    STUFF(STUFF(CAST([sSCH].[active_end_date] AS VARCHAR(8)), 5, 0, '-'), 8, 0, '-') AS [ScheduleUsageEndDate], 
    [sSCH].[date_created] AS [ScheduleCreatedOn], 
    [sSCH].[date_modified] AS [ScheduleLastModifiedOn],
    CASE [sJOB].[delete_level]
        WHEN 0 THEN 'Never'
        WHEN 1 THEN 'On Success'
        WHEN 2 THEN 'On Failure'
        WHEN 3 THEN 'On Completion'
    END AS [JobDeletionCriterion]
FROM
    [msdb].[dbo].[sysjobsteps] AS [sJSTP]
    INNER JOIN [msdb].[dbo].[sysjobs] AS [sJOB] ON [sJSTP].[job_id] = [sJOB].[job_id]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sOSSTP] ON [sJSTP].[job_id] = [sOSSTP].[job_id] AND [sJSTP].[on_success_step_id] = [sOSSTP].[step_id]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sOFSTP] ON [sJSTP].[job_id] = [sOFSTP].[job_id] AND [sJSTP].[on_fail_step_id] = [sOFSTP].[step_id]
    LEFT JOIN [msdb].[dbo].[sysproxies] AS [sPROX] ON [sJSTP].[proxy_id] = [sPROX].[proxy_id]
    LEFT JOIN [msdb].[dbo].[syscategories] AS [sCAT] ON [sJOB].[category_id] = [sCAT].[category_id]
    LEFT JOIN [msdb].[sys].[database_principals] AS [sDBP] ON [sJOB].[owner_sid] = [sDBP].[sid]
    LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH] ON [sJOB].[job_id] = [sJOBSCH].[job_id]
    LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH] ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]
ORDER BY
    [JobName] ,
    [StepNo]