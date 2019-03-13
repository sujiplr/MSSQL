
CREATE PROCEDURE [dbo].[BackupStatusReport]
AS

BEGIN
	SET NOCOUNT ON
	DECLARE @check int
	SET @check=24
	DECLARE @FinalAge int
	DECLARE @hf int
	DECLARE @hd int
	DECLARE @servername nvarchar(60)
	DECLARE @dbname nvarchar(60)
	DECLARE @lastFullBackup datetime
	DECLARE @lastDiffBackup datetime
	DECLARE @NotBackedupSinceHrs int
	DECLARE @status nvarchar(30)

	DECLARE @table1 table (Servername nvarchar(60),  DBName nvarchar(60),
	LastFullBackup datetime, LastDiffBackup datetime,NotBackedupSince int,[Status] nvarchar(30))

	DECLARE c1 cursor for

		with bkp_t1
as
(
select CONVERT(varchar(60),@@SERVERNAME) as Servername, CONVERT(varchar(60),e.database_name) as DBname
FROM msdb..backupset e
              WHERE e.server_name = @@SERVERNAME  AND e.database_name NOT IN ('tempdb') AND 
                                                  e.database_name IN (SELECT Distinct name FROM master.sys.databases 
												  where database_id<>2 and is_read_only <> 1 and state_desc <> 'OFFLINE')
)
select distinct bkp_t1.Servername,bkp_t1.DBname, (SELECT  CONVERT(varchar(25),MAX(backup_finish_date) , 100)
              FROM msdb..backupset a
              WHERE a.database_name=bkp_t1.DBname AND a.server_name  = @@SERVERNAME and type='D' 
              GROUP BY a.database_name) Last_FullBackup,                 

              (SELECT CONVERT(varchar(25),MAX(backup_finish_date) , 100)
              FROM msdb..backupset c
              WHERE c.database_name=bkp_t1.DBname
              AND c.server_name  = @@SERVERNAME
              AND type='I' Group by c.database_name) Last_Diff_Backup,
              NULL as NotBackedupSinceHrs,
                                                  NULL as [Status]
                                                  from bkp_t1
	-- never backed up
	UNION ALL
		SELECT Distinct CONVERT(varchar(60),@@SERVERNAME) as Servername,
		CONVERT(varchar(60),name) as DBname,
		NULL, NULL,NULL as NotBackedupSinceHrs,NULL as [Status]
		FROM master..sysdatabases as record
		WHERE name not in (SELECT distinct database_name FROM msdb..backupset)and dbid<>2 order by 1,2

	 OPEN c1

		FETCH NEXT FROM c1 INTO @servername,@dbname,@LastFullBackup,@LastDiffBackup,@NotBackedupSinceHrs,@status

		WHILE @@FETCH_STATUS=0

			BEGIN
			   IF (@LastFullBackup IS NULL)     
				   BEGIN
						 SET @LastFullBackup='1900-01-01 00:00:00.000'
				   END
			   IF (@LastDiffBackup IS NULL)
				   BEGIN
						 SET @LastDiffBackup='1900-01-01 00:00:00.000'     
				   END

				SELECT @hf=datediff(hh,@LastFullBackup,GETDATE())     
				SELECT @hd=datediff(hh,@LastDiffBackup,GETDATE())

				IF (@hf<@hd)
				SET @FinalAge=@hf
				ELSE
				SET @FinalAge=@hd

				INSERT INTO @table1 values (@servername,@dbname,@LastFullBackup,@LastDiffBackup,@FinalAge,@status)

				FETCH NEXT FROM c1 INTO @servername,@dbname,@LastFullBackup,@LastDiffBackup,@NotBackedupSinceHrs,@status

			END

	UPDATE @table1 SET status = CASE
		WHEN NotBackedUpSince <=@check THEN 'Success'
		WHEN NotBackedUpSince > = @check THEN 'Failed/NotRun'        
	END

	UPDATE @table1 SET Status='Success' 
	WHERE DBName='master' AND NotBackedUpSince< =@check +144

	--IF OBJECT_ID('Tempdb..#Failed_Bkps') IS NOT NULL
	--DROP TABLE TEMPDB..#Failed_Bkps

	--TRUNCATE TABLE SysAdmin..Failed_Bkps

	----INSERT INTO SysAdmin..Failed_Bkps
	SELECT ServerName as 'SQLInstanceName',DBName as 'DatabaseName',LastFullBackup,LastDiffBackup, NotBackedupSince as 'LastBackupHrs',Status 
	FROM @table1 
	WHERE Status <> 'Success'

	--select SQLInstanceName,DatabaseName,LastFullBackup, LastDiffBackup, LastBackupHrs, Status from SysAdmin..Failed_Bkps --order by NotBackedUpSince desc 
END




