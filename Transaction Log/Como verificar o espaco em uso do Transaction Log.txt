-- Verifica a utilização dos arquivos de Log das databases
-- Caso a performance counters esteja vazia, tem que resolver esse problema antes.
SELECT db.[name] AS [Database Name],
       db.recovery_model_desc AS [Recovery Model],
       db.log_reuse_wait_desc AS [Log Reuse Wait Description],
       ls.cntr_value AS [Log Size (KB)],
       lu.cntr_value AS [Log Used (KB)],
       CAST(CAST(lu.cntr_value AS FLOAT) / CASE
                                               WHEN CAST(ls.cntr_value AS FLOAT) = 0 THEN
                                                   1
                                               ELSE
                                                   CAST(ls.cntr_value AS FLOAT)
                                           END AS DECIMAL(18, 2)) * 100 AS [Log Used %],
       db.[compatibility_level] AS [DB Compatibility Level],
       db.page_verify_option_desc AS [Page Verify Option]

FROM sys.databases AS db
    INNER JOIN sys.dm_os_performance_counters AS lu
        ON db.name = lu.instance_name
    INNER JOIN sys.dm_os_performance_counters AS ls
        ON db.name = ls.instance_name
WHERE lu.counter_name LIKE '%Log File(s) Used Size (KB)%'
      AND ls.counter_name LIKE '%Log File(s) Size (KB)%';

	  
/* select * from sys.dm_os_performance_counters

-- Esse comando também pode ser utilizado

dbcc sqlperf(logspace)

*/