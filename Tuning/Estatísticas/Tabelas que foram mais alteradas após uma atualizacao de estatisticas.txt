select TOP 100 B.name,A.Name,A.rowmodctr,*
from sys.sysindexes A with(nolock)
	join sys.sysobjects B with(nolock) on A.id = B.id
WHERE A.name IS NOT null
order by A.rowmodctr desc