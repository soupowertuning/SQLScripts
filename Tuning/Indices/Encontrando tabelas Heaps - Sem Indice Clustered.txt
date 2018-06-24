SELECT *  FROM sys.tables

WHERE OBJECTPROPERTY(object_id,'TableHasClustIndex') = 0
