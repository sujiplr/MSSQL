------ Attach SQL Commands   --Run the below block and take the result before doing dettach .. 

----- After dettach process once the files are back please run the result xomamnds for attaching it

DECLARE     @cmd        VARCHAR(MAX), 
            @dbname     VARCHAR(200), 
            @prevdbname VARCHAR(200) 

SELECT @cmd = '', @dbname = ';', @prevdbname = '' 

CREATE TABLE #Attach 
    (Seq        INT IDENTITY(1,1) PRIMARY KEY, 
     dbname     SYSNAME NULL, 
     fileid     INT NULL, 
     filename   VARCHAR(1000) NULL, 
     TxtAttach  VARCHAR(MAX) NULL 
) 

INSERT INTO #Attach 
SELECT DISTINCT DB_NAME(dbid) AS dbname, fileid, filename, CONVERT(VARCHAR(MAX),'') AS TxtAttach 
FROM master.dbo.sysaltfiles 
WHERE dbid IN (SELECT dbid FROM master.dbo.sysaltfiles  
            WHERE SUBSTRING(filename,1,1) IN ('E','F')) 
            AND DATABASEPROPERTYEX( DB_NAME(dbid) , 'Status' ) in ('ONLINE','OFFLINE') 
            AND DB_NAME(dbid) NOT IN ('master','tempdb','msdb','model') 
ORDER BY dbname, fileid, filename 

UPDATE #Attach 
SET @cmd = TxtAttach =   
            CASE WHEN dbname <> @prevdbname  
            THEN CONVERT(VARCHAR(200),'exec sp_attach_db @dbname = N''' + dbname + '''') 
            ELSE @cmd 
            END +',@filename' + CONVERT(VARCHAR(10),fileid) + '=N''' + filename +'''', 
    @prevdbname = CASE WHEN dbname <> @prevdbname THEN dbname ELSE @prevdbname END, 
    @dbname = dbname 
FROM #Attach  WITH (INDEX(0),TABLOCKX) 
 OPTION (MAXDOP 1) 

SELECT TxtAttach 
FROM 
(SELECT dbname, MAX(TxtAttach) AS TxtAttach FROM #Attach  
 GROUP BY dbname) AS x 

DROP TABLE #Attach 
GO 



------ Dettach SQL Commands
--1 . Take the output of the below command and run it. This will make the databases offline

SELECT DISTINCT 'ALTER DATABASE ' + DB_NAME(dbid) + ' SET OFFLINE with rollback immediate;' 
FROM master.dbo.sysaltfiles 
WHERE SUBSTRING(filename,1,1) IN ('E','F') 
AND DATABASEPROPERTYEX( DB_NAME(dbid) , 'Status' ) = 'ONLINE' 
AND DB_NAME(dbid) NOT IN ('master','tempdb','msdb','model');






--1 . Take the output of the below command and run it. This will dettach the databases

SELECT DISTINCT'exec sp_detach_db ''' + DB_NAME(dbid) + ''';' 
FROM master.dbo.sysaltfiles 
WHERE SUBSTRING(filename,1,1) IN ('E','F') 
AND DATABASEPROPERTYEX( DB_NAME(dbid) , 'Status' ) in ('ONLINE','OFFLINE')
AND DB_NAME(dbid) NOT IN ('master','tempdb','msdb','model');
