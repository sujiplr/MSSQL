WITH IO_Per_DB_Per_File
AS
(SELECT 
    DB_NAME(dmivfs.database_id) AS DatabaseName
  , CONVERT(DECIMAL(12,2), SUM(num_of_bytes_read + num_of_bytes_written) / 1024 / 1024) AS FileSizeMb
  , CONVERT(DECIMAL(12,2), SUM(num_of_bytes_read) / 1024 / 1024) AS TotalReadInMB
  , CONVERT(DECIMAL(12,2), SUM(num_of_bytes_written) / 1024 / 1024) AS TotalWriteInMB
  , CASE WHEN dmmf.type_desc = 'ROWS' THEN 'Data File' WHEN dmmf.type_desc = 'LOG' THEN 'Log File' END AS DataFileOrLogFile
FROM sys.dm_io_virtual_file_stats(NULL, NULL) dmivfs
JOIN sys.master_files dmmf ON dmivfs.file_id = dmmf.file_id AND dmivfs.database_id = dmmf.database_id
GROUP BY dmivfs.database_id, dmmf.type_desc,DB_NAME(dmivfs.database_id))
SELECT 
    DatabaseName
  , DataFileOrLogFile
  , FileSizeMb
  , TotalReadInMB
  , TotalWriteInMB
  , CAST(FileSizeMb / SUM(FileSizeMb) OVER() * 100 AS DECIMAL(5,2)) AS [I/O]
FROM IO_Per_DB_Per_File
ORDER BY 1,2;


-------------------------------------------------------------------------------

WITH IO_Per_DB
AS
(SELECT 
  DB_NAME(database_id) AS Db
  , CONVERT(DECIMAL(12,2), SUM(num_of_bytes_read + num_of_bytes_written) / 1024 / 1024) AS TotalMb
FROM sys.dm_io_virtual_file_stats(NULL, NULL) dmivfs
GROUP BY database_id)
SELECT 
    Db
    ,TotalMb
    ,CAST(TotalMb / SUM(TotalMb) OVER() * 100 AS DECIMAL(5,2)) AS [I/O]
FROM IO_Per_DB
ORDER BY [I/O] DESC;
