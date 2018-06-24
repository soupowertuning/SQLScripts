--Conferir a Versão do SQL Server
SELECT @@version

-- Quantidade de cores disponíveis para o SQL Server
SELECT current_tasks_count,runnable_tasks_count,* 
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255
AND status = 'VISIBLE ONLINE'

--Já peguei casos do cliente ter 8 sockets configurados no SQL Server Standard, e o SQL estar utilizando apenas 4.