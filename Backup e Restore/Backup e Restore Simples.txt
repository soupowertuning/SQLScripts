BACKUP DATABASE NOME_DATABASE 
TO disk = '\\Caminho\Nome_do_Arquivo.bak'
WITH INIT ,  NOUNLOAD ,  NAME = N'Descricaoo do backup', NOSKIP ,  STATS = 10, NOFORMAT

RESTORE DATABASE NOME_DATABASE  
FROM disk = '\\Caminho\Nome_do_Arquivo.bak'
WITH RECOVERY, Replace,stats= 10
