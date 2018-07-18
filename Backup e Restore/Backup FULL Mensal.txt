USE [Traces]
GO
/****** Object:  StoredProcedure [dbo].[stpBackup_Databases_Disco]    Script Date: 12/06/2014 15:46:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE procedure [dbo].[stpBackup_Databases_Disco_Mensal]
	AS
	
		declare @Backup_Databases table (Nm_database varchar(500))
		declare @Nm_Database varchar(500), @Nm_Caminho varchar(5000)
	
		insert into @Backup_Databases
		select Name
		from sys.databases
		where Name not in ('tempdb') AND state_desc = 'ONLINE'		
			
		

		while exists (select null from @Backup_Databases)
		begin
			
			select top 1 @Nm_Database = Nm_database from @Backup_Databases order by Nm_database
			
			set @Nm_Database = @Nm_Database
			
				set @Nm_Caminho = 'D:\BKP_DADOS\Mensal\' + @Nm_Database+ '_'+
				replace(CONVERT(VARCHAR, GETDATE(), 103),'/','_') + '_Dados.bak'
			
			exec traces.dbo.stpBackup_Full_Database @Nm_Caminho, @Nm_Database, @Nm_Caminho --o último parametro corresponde a descrição do bkp
			
			delete from @Backup_Databases where Nm_database = @Nm_Database
		End