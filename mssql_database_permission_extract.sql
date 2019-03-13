select * from (
select * from(
 SELECT 'IF (SELECT name FROM sys.database_principals WHERE name = ''' + dp.name + ''') IS NULL' + CHAR(13) + 'BEGIN' + CHAR(13) +
         'CREATE USER ' + QUOTENAME(dp.name) + 
         /*CASE 
         WHEN SUSER_SID(dp.name) IS NULL THEN ''
         ELSE ' FOR LOGIN ' + QUOTENAME(dp.name)
         END +*/
         CASE
         WHEN SUSER_SNAME(dp.sid) IS NULL THEN ' WITHOUT LOGIN'
         ELSE ' FOR LOGIN ' + QUOTENAME(SUSER_SNAME(dp.sid)) 
         END + 
         CASE          
         WHEN dp.default_schema_name IS NULL AND dp.type <> 'G' THEN ' WITH DEFAULT_SCHEMA = [dbo]'
         ELSE ' WITH DEFAULT_SCHEMA = [' + dp.default_schema_name + ']'
         END + CHAR(13) + 'END'  command
         FROM sys.database_principals dp LEFT OUTER JOIN
         sys.schemas sch ON dp.principal_id = sch.principal_id
         WHERE  exists(SELECT 1  FROM sys.database_principals dp1 WHERE dp.principal_id=dp1.principal_id and type IN ('U', 'G', 'S') AND principal_id > 4) AND dp.TYPE IN ('U', 'G', 'S') AND dp.principal_id > 4     
         ) a  where a.command is not null

--=======================================================
--script all schemas
--=======================================================

      --Script the permission grants on the schemas  
union all	  
      SELECT  CHAR(13) + dp.state_desc COLLATE latin1_general_ci_as + ' ' + 
      dp.permission_name + ' ON ' + dp.class_desc + '::' + QUOTENAME(sch.name) + 
      ' TO ' + QUOTENAME(dp2.name) + ' AS ' + QUOTENAME(dp3.name) 
	  
      FROM sys.database_permissions dp 
      INNER JOIN sys.schemas sch ON dp.grantor_principal_id = sch.principal_id
      INNER JOIN sys.database_principals dp2 ON dp.grantee_principal_id = dp2.principal_id
      INNER JOIN sys.database_principals dp3 ON dp.grantor_principal_id = dp3.principal_id
      WHERE dp.class = 3  --dp.major_id BETWEEN 1 AND 8
      

--========================================================
--script database roles from the database
--========================================================
union all
         SELECT 'CREATE ROLE ' + QUOTENAME(dp.name) + ' AUTHORIZATION ' + QUOTENAME(dp2.name) + CHAR(13)
		  
         FROM sys.database_principals dp INNER JOIN sys.database_principals dp2 
         ON dp.owning_principal_id = dp2.principal_id
         WHERE dp.type = 'R' AND dp.is_fixed_role <> 1 AND dp.principal_id > 4

--=========================================================
--script Application roles from the database
--=========================================================
union all
      SELECT 'CREATE APPLICATION ROLE ' + dp.name + ' WITH DEFAULT_SCHEMA = ' + 
      QUOTENAME(dp.default_schema_name) + ', PASSWORD = N''P@ssw0rd1''' + CHAR(10)
	   
      FROM sys.database_principals dp
      WHERE dp.type = 'A' AND dp.is_fixed_role <> 1 AND dp.principal_id > 4

--===============================================================
--got the roles so now we need to get any nested role permissions
--===============================================================
union all
      SELECT 'EXEC sp_addrolemember ''' + dp2.name + ''', ''' + dp.name + '''' + CHAR(10)
	   
      FROM sys.database_principals dp 
      INNER JOIN sys.database_role_members drm
      ON dp.principal_id = drm.member_principal_id 
      INNER JOIN sys.database_principals dp2 
      ON drm.role_principal_id = dp2.principal_id
      WHERE dp.type = 'R'


--================================================================
--Scripting all user connection grants
--================================================================
union all
      SELECT  dpm.state_desc COLLATE Latin1_General_CI_AS + ' ' + 
      dpm.permission_name COLLATE Latin1_General_CI_AS + ' TO ' + QUOTENAME(dp.name) + CHAR(13)
	   
      FROM sys.database_permissions dpm INNER JOIN sys.database_principals dp 
      ON dpm.grantee_principal_id = dp.principal_id
      WHERE dp.principal_id > 4 AND dpm.class = 0 --AND dpm.type = 'CO'


--=================================================================
--Now script all the database roles the user have permissions to
--=================================================================
union all
      SELECT  'EXEC sp_addrolemember ''' + dp.name + ''', ''' + dp2.name + '''' + CHAR(13)
	   
      FROM sys.database_principals dp
      INNER JOIN sys.database_role_members drm ON dp.principal_id = drm.role_principal_id
      INNER JOIN sys.database_principals dp2 ON drm.member_principal_id = dp2.principal_id
      WHERE dp2.principal_id > 4 AND dp2.type <> 'R'
) a 

--=================================================================
--Now all the object level permissions
--=================================================================
union all  
  SELECT CASE dbpe.[state] WHEN 'W' THEN 'GRANT'
      ELSE dbpe.state_desc COLLATE Latin1_General_CI_AS
      END + ' ' +  dbpe.permission_name COLLATE Latin1_General_CI_AS + ' ON [' + sch.name + '].[' +  OBJECT_NAME(dbpe.major_id)  + '] TO [' + dbpr.name 
      + CASE dbpe.[state] WHEN 'W' THEN '] WITH GRANT OPTION'  ELSE ']' END 
	   
      FROM sys.database_permissions dbpe INNER JOIN sys.database_principals dbpr 
      ON dbpr.principal_id = dbpe.grantee_principal_id
      INNER JOIN sys.objects obj ON dbpe.major_id = obj.object_id
      INNER JOIN sys.schemas sch ON obj.schema_id = sch.schema_id
      WHERE obj.type NOT IN ('IT','S','X') 
