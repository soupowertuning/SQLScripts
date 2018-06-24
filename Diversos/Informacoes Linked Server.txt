SELECT ss.server_id 
,ss.name 
,'Server ' = Case ss.Server_id 
when 0 then 'Current Server' 
else 'Remote Server' 
end 
,ss.product 
,ss.provider 
,ss.catalog 
,'Local Login ' = case sl.uses_self_credential 
when 1 then 'Uses Self Credentials' 
else ssp.name 
end 
,'Remote Login Name' = sl.remote_name 
,'RPC Out Enabled' = case ss.is_rpc_out_enabled 
when 1 then 'True' 
else 'False' 
end 
,'Data Access Enabled' = case ss.is_data_access_enabled 
when 1 then 'True' 
else 'False' 
end 
,ss.modify_date 
FROM sys.Servers ss 
LEFT JOIN sys.linked_logins sl 
ON ss.server_id = sl.server_id 
LEFT JOIN sys.server_principals ssp 
ON ssp.principal_id = sl.local_principal_id
