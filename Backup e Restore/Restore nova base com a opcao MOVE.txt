--descobrindo o nome dos arquivos lógicos do SQL
RESTORE FILELISTONLY FROM DISK = 'CaminhoBackup'

--Resturando a base para um novo caminho
RESTORE DATABASE Nome_Database
FROM DISK= 'CaminhoBackup' WITH RECOVERY,stats=1,
MOVE 'LogicalName' TO 'NovoCaminho.mdf',
MOVE 'LogicalName_log' TO 'NovoCaminho.ldf'