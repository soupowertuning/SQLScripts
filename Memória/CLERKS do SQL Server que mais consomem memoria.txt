
-- TOP CLERKS ordenado pelo consumo de memória
--SQL Server 2005/2008/R2 version
SELECT TOP(10) [type] as [Memory Clerk Name], SUM(single_pages_kb)/1024 AS [SPA Memory (MB)]
FROM sys.dm_os_memory_clerks
GROUP BY [type]
ORDER BY SUM(single_pages_kb) DESC;

-- SQL Server 2012 version
SELECT TOP(10) [type] as [Memory Clerk Name], SUM(pages_kb)/1024 AS [SPA Memory (MB)]
FROM sys.dm_os_memory_clerks
GROUP BY [type]
ORDER BY SUM(pages_kb) DESC;