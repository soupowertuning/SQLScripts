
CREATE TABLE Insert_Identity(
 Id int identity(1,1),
 Data datetime)

SET IDENTITY_INSERT Insert_Identity On
insert into Insert_Identity (Id, Data)
values(10,GETDATE())

SET IDENTITY_INSERT Insert_Identity Off

-- Teste
select * from Insert_Identity

-- Após desabilitar essa opçãoo o insert abaixo gera um erro
insert into Insert_Identity (Id, Data)
values(10,GETDATE())