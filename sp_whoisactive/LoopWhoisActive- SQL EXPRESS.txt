
if OBJECT_ID('Resultado_WhoisActive') is not null
	drop table Resultado_WhoisActive
CREATE TABLE Resultado_WhoisActive (   Dt_Log datetime,[dd hh:mm:ss.mss] varchar(8000) NULL,[database_name] nvarchar(128) NULL,
   [session_id]       smallint NOT NULL,
    blocking_session_id       smallint  NULL,
   [sql_text] xml NULL,[login_name] nvarchar(128) NOT NULL,[wait_info] nvarchar(4000) NULL,
      [status] varchar(30) NOT NULL,[percent_complete] varchar(30) NULL,[host_name] nvarchar(128) NULL,[sql_command] xml NULL,[CPU] varchar(100),
	  [reads] varchar(100),[writes] varchar(100)
    )      


USE TESTE

SET NOCOUNT ON

declare @DataFim datetime

set @DataFim = GETDATE()
while @DataFim < '20160527 18:00'
begin

	EXEC sp_WhoIsActive @get_outer_command = 1,
				@output_column_list = '[collection_time][d%][session_id][blocking_session_id][sql_text][login_name][wait_info][status][percent_complete]
		  [host_name][database_name][sql_command][CPU][reads][writes]',
		@destination_table = 'Resultado_WhoisActive'

	waitfor delay '00:00:05'
	set @DataFim = GETDATE()

end