/*

> SQL 2016

SELECT  @@SERVERNAME AS [Server Name] ,
        RIGHT(@@version, LEN(@@version) - 3 - CHARINDEX(' ON ', @@VERSION)) AS [OS Info] ,
        LEFT(@@VERSION, CHARINDEX('-', @@VERSION) - 2) + ' '
        + CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(300)) AS [SQL Server Version] ,
        service_account ,
        instant_file_initialization_enabled
FROM    sys.dm_server_services
WHERE   servicename LIKE 'SQL Server (%'

*/
USE master;
SET NOCOUNT ON

-- *** WARNING: Undocumented commands used in this script !!! *** --

--Exit if a database named DummyTestDB exists
IF DB_ID('DummyTestDB') IS NOT NULL
BEGIN
  RAISERROR('A database named DummyTestDB already exists, exiting script', 20, 1) WITH LOG
END

--Temptable to hold output from sp_readerrorlog
IF OBJECT_ID('tempdb..#SqlLogs') IS NOT NULL DROP TABLE #SqlLogs
GO
CREATE TABLE #SqlLogs(LogDate datetime2(0), ProcessInfo VARCHAR(20), TEXT VARCHAR(MAX))

--Turn on trace flags 3004 and 3605
DBCC TRACEON(3004, 3605, -1) WITH NO_INFOMSGS

--Create a dummy database to see the output in the SQL Server Errorlog
CREATE DATABASE DummyTestDB 
GO

--Turn off trace flags 3004 and 3605
DBCC TRACEOFF(3004, 3605, -1) WITH NO_INFOMSGS

--Remove the DummyDB
DROP DATABASE DummyTestDB;

--Now go check the output in the SQL Server Error Log File
--This can take a while if you have a large errorlog file
INSERT INTO #SqlLogs(LogDate, ProcessInfo, TEXT)
EXEC sp_readerrorlog 0, 1, 'Zeroing'

IF EXISTS(
           SELECT * FROM #SqlLogs
           WHERE TEXT LIKE 'Zeroing completed%'
            AND TEXT LIKE '%DummyTestDB.mdf%'
            AND LogDate > DATEADD(HOUR, -1, LogDate)
        )
   BEGIN
    PRINT 'We do NOT have instant file initialization.'
    PRINT 'Grant the SQL Server services account the ''Perform Volume Maintenance Tasks'' security policy.'
   END
ELSE
   BEGIN
    PRINT 'We have instant file initialization.'
   END

