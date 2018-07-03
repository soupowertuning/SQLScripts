
select * from fn_trace_getinfo (null)

--Parando um trace que está em execução:

exec sp_trace_setstatus  @traceid = @Trace_Id,  @status = 0
exec sp_trace_setstatus  @traceid = @Trace_Id,  @status = 2
