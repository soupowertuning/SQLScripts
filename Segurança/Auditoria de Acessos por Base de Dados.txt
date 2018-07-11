
-- nivel servidor
		select name from sys.syslogins
		where sysadmin = 1
		and status = 9

-- nivel database (logar na base)
		SELECT p.name, p.type_desc, pp.name, pp.type_desc, pp.is_fixed_role
		FROM sys.database_role_members roles 
			JOIN sys.database_principals p ON roles.member_principal_id = p.principal_id
			JOIN sys.database_principals pp ON roles.role_principal_id = pp.principal_id
		ORDER BY 1

-- nivel objeto (logar na base)
		SELECT  prmssn.permission_name AS [Permission], 
			sp.type_desc, sp.name, grantor_principal.name AS [Grantor], grantee_principal.name AS [Grantee] 
				FROM sys.all_objects AS sp 
				INNER JOIN sys.database_permissions AS prmssn 
					ON prmssn.major_id=sp.object_id AND prmssn.minor_id=0 AND prmssn.class=1 
				INNER JOIN sys.database_principals AS grantor_principal 
					ON grantor_principal.principal_id = prmssn.grantor_principal_id 
				INNER JOIN sys.database_principals AS grantee_principal 
					ON grantee_principal.principal_id = prmssn.grantee_principal_id 
				WHERE (SCHEMA_NAME(sp.schema_id)='dbo') 
				ORDER BY sp.type
