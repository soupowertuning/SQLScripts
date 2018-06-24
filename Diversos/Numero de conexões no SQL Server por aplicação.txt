select hostname,program_Name, count(*) qtd
from sysprocesses A 
where spid > 50
group by hostname,program_Name
order by 3 desc