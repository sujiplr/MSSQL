1.	Find out the sql handle for the SP . One of the SQL SQl was getting in hung in respective to this SQL handle.

SELECT cp.plan_handle, cp.objtype, cp.usecounts, 
DB_NAME(st.dbid) AS [DatabaseName]
FROM sys.dm_exec_cached_plans AS cp CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st 
WHERE OBJECT_NAME (st.objectid)
LIKE N'%<sql part>%'

2.	Considering the above , cleared the SQL handle and ran the SP again, which got completed in 4 sec.

DBCC FREEPROCCACHE (0x050009007CB8ED1FA0BE0D850100000001000000000000000000000000000000000000000000000000000000)
