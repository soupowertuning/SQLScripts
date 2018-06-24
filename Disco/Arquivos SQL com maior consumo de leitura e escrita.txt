--leitura
	SELECT TOP 5 DB_NAME(database_id) AS [Database Name]
			, file_id 
			, io_stall_read_ms
			, num_of_reads
			, CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms]
		
			, io_stall_read_ms + io_stall_write_ms AS [io_stalls]
			, num_of_reads + num_of_writes AS [total_io]
			, CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) AS [avg_io_stall_ms]
			, GETDATE() as [Dt_Registro]
	FROM sys.dm_io_virtual_file_stats(null,null)
	order by 5 desc


--escrita
	SELECT TOP 5 DB_NAME(database_id) AS [Database Name]
			, file_id 
				, io_stall_write_ms
			, num_of_writes
			, CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms]
			, io_stall_read_ms + io_stall_write_ms AS [io_stalls]
			, num_of_reads + num_of_writes AS [total_io]
			, CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) AS [avg_io_stall_ms]
			, GETDATE() as [Dt_Registro]
	FROM sys.dm_io_virtual_file_stats(null,null)
	order by 5 desc


--caso de um valor alto na coluna [avg_io_stall_ms], confira os contadores abeixo no Perfmon.
Avg Disk Sec/Read - Validar se a latência do disco está dentro da expectativa. Em geral, adotam-se valores máximos de 50 a 100ms como tempo de respostas para o disco de dados. Uma sugestão de tempos:
  
      <1ms : inacreditável
      <3ms : excelente
      <5ms : muito bom
      <10ms : dentro do esperado
      <20ms : razoável
      <50ms : limite
      >100ms : ruim
      > 1 seg : contenção severa de disco
      > 15 seg : problemas graves com o storage

     
Avg Disk Sec/Write - Validar se a latência do disco está dentro da expectativa. Ignore esse valor para os discos de dados. Utilize esse contador para os discos de log com latências reduzidas:
  
      <1ms : excelente
      <3ms : bom
      <5ms : razoável
      <10ms : limite
      >20ms : ruim
      > 1 seg : contenção severa de disco
      > 15 seg : problemas graves com o storage