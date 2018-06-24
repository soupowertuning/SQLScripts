
a
-- analisar a utilização do tempdb
SELECT a.name AS LogicalName,
'SizeinMB' = (size/128)
,fileproperty(a.name, 'spaceused' )/128 as UsedinMB
,(size/128) -fileproperty (a.name,'SpaceUsed')/128 AS FreeInMB
,'Free%'=cast (((a.size/128.0)-fileproperty(a.name,'SpaceUsed')/128.0)/(a.size/128.0)*100 as numeric(15))
, ((a.size/128.0)-fileproperty(a.name,'SpaceUsed')/128.0) / SUM ((a.size/128.0)-(fileproperty(a.name,'SpaceUsed')/128)) OVER (PARTITION BY fg.data_space_id) As [PropFree%]
,fg.name
FROM sysfiles a LEFT join sys.filegroups fg 
ON a.groupid = fg.data_space_id


----- arquivo para testar a carga no TEMPDB
  USE TempDB;
GO
 SELECT TOP 1000000000
        IDENTITY(INT,1,1) AS RowNum
   INTO #StressTempDB
   FROM Master.sys.All_Columns ac1,
        Master.sys.All_Columns ac2,
        Master.sys.All_Columns ac3;
GO


select @@version

-- habilitar os dois trace flags abaixo caso seja uma versão de SQL inferior ao SQL 2016.
DBCC TRACEOFF (1118, -1);
DBCC TRACEON (1118, -1);
DBCC TRACESTATUS(1118,-1)
DBCC TRACESTATUS(1117,-1)


-- Alterar o caminho do tempdb quando preciso
SELECT name, physical_name AS CurrentLocationFROM sys.master_filesWHERE database_id = DB_ID(N'tempdb');--Altere o local de cada arquivo usando ALTER DATABASE.USE master;

GO
ALTER DATABASE tempdb
MODIFY FILE (NAME = tempdev, FILENAME = 'G:\tempdb.mdf');
GO
ALTER DATABASE tempdb
MODIFY FILE (NAME = templog, FILENAME = 'I:\templog.ldf');
GO--Reinicie a instância do SQL Server.


-- Caso precise reduzir o tamanho do mdf principal antes de aumentar os arquivos
DBCC FREEPROCCACHE
CHECKPOINT

USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdev' , 2000)
GO


--Realizando a alteração para vários arquivos
USE [master]
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev', FILEGROWTH = 1 GB )
GO

USE [master]; 
GO 
alter database tempdb modify file (name='tempdev', size = 5 GB);
GO

USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME = N'D:\DADOS\tempdev2.ndf' , 
SIZE = 5 GB , FILEGROWTH = 1 GB);

ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME = N'D:\DADOS\tempdev3.ndf' , 
SIZE = 5 GB , FILEGROWTH = 1 GB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME = N'D:\DADOS\tempdev4.ndf' ,
 SIZE =5 GB , FILEGROWTH = 1 GB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME = N'D:\DADOS\tempdev5.ndf' ,
 SIZE = 5 GB , FILEGROWTH = 1 GB);
 ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME = N'D:\DADOS\tempdev6.ndf' ,
 SIZE = 5 GB , FILEGROWTH = 1 GB);
 ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME = N'D:\DADOS\tempdev7.ndf' ,
 SIZE = 5 GB , FILEGROWTH = 1 GB);
 ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME = N'D:\DADOS\tempdev8.ndf' ,
 SIZE = 5 GB , FILEGROWTH = 1 GB);



------------ para reduzir a quantidade de arquivos do tempdb

GO
DBCC DROPCLEANBUFFERS
GO
DBCC FREEPROCCACHE
GO
DBCC FREESESSIONCACHE
GO
DBCC FREESYSTEMCACHE ( 'ALL')
GO

USE [tempdb];
GO
DBCC SHRINKFILE (temp8, EMPTYFILE);
ALTER DATABASE [tempdb]  REMOVE FILE temp8

DBCC SHRINKFILE (temp7, EMPTYFILE);
ALTER DATABASE [tempdb]  REMOVE FILE temp7

DBCC SHRINKFILE (temp6, EMPTYFILE);
ALTER DATABASE [tempdb]  REMOVE FILE temp6

DBCC SHRINKFILE (temp5, EMPTYFILE);
ALTER DATABASE [tempdb]  REMOVE FILE temp5