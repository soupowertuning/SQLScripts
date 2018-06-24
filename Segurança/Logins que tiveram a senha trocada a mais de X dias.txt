--Mostra todos os logins que tiveram a senha trocada a mais de X dias:
SELECT name, LOGINPROPERTY([name],'PasswordLastSetTime')AS'SenhaTrocada'
FROM sys.sql_logins
WHERE LOGINPROPERTY([name],'PasswordLastSetTime') < DATEADD(dd, -60, GETDATE());