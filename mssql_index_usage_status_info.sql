Index Usage Stats


SELECT  DB_NAME() AS DatabaseName
                 ,SCHEMA_NAME(s.schema_id) +'.'+OBJECT_NAME(i.OBJECT_ID) AS TableName
                 ,i.name AS IndexName
                 ,ius.user_seeks AS Seeks
                 ,ius.user_scans AS Scans
                 ,ius.user_lookups AS Lookups
                 ,ius.user_updates AS Updates
                 ,CASE WHEN ps.usedpages > ps.pages THEN (ps.usedpages - ps.pages) ELSE 0 
                               END * 8 / 1024 AS IndexSizeMB
                 ,ius.last_user_seek AS LastSeek
                 ,ius.last_user_scan AS LastScan
                 ,ius.last_user_lookup AS LastLookup
                 ,ius.last_user_update AS LastUpdate
FROM sys.indexes i
INNER JOIN sys.dm_db_index_usage_stats ius ON ius.index_id = i.index_id AND ius.OBJECT_ID = i.OBJECT_ID
INNER JOIN (SELECT sch.name, sch.schema_id, o.OBJECT_ID, o.create_date FROM sys.schemas sch 
                                            INNER JOIN sys.objects o ON o.schema_id = sch.schema_id) s ON s.OBJECT_ID = i.OBJECT_ID
LEFT JOIN (SELECT OBJECT_ID, index_id, SUM(used_page_count) AS usedpages,
                                                              SUM(CASE WHEN (index_id < 2) 
                                                                                        THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count) 
                                                                                        ELSE lob_used_page_count + row_overflow_used_page_count 
                                                                           END) AS pages
                                                          FROM sys.dm_db_partition_stats
                                                          GROUP BY object_id, index_id) AS ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE OBJECTPROPERTY(i.OBJECT_ID,'IsUserTable') = 1
AND ius.database_id = DB_ID()
and i.name='IX_DAS_TTH_TradeTagHistoryIntIdDataDate1'
order by SCHEMA_NAME(s.schema_id) +'.'+OBJECT_NAME(i.OBJECT_ID)



Index DML status 


SELECT DB_NAME() Database_Name, OBJECT_NAME(IXOS.OBJECT_ID)  Table_Name 
       ,IX.name  Index_Name
          ,IXOS.partition_number
          ,IX.type_desc Index_Type
          ,SUM(PS.[used_page_count]) * 8 IndexSizeKB
       ,IXOS.LEAF_INSERT_COUNT NumOfInserts
       ,IXOS.LEAF_UPDATE_COUNT NumOfupdates
       ,IXOS.LEAF_DELETE_COUNT NumOfDeletes        
FROM   SYS.DM_DB_INDEX_OPERATIONAL_STATS (NULL,NULL,NULL,NULL ) IXOS 
INNER JOIN SYS.INDEXES AS IX ON IX.OBJECT_ID = IXOS.OBJECT_ID AND IX.INDEX_ID =    IXOS.INDEX_ID 
       INNER JOIN sys.dm_db_partition_stats PS on PS.object_id=IX.object_id
WHERE  OBJECTPROPERTY(IX.[OBJECT_ID],'IsUserTable') = 1
and ix.name='IX_DAS_TTH_TradeTagHistoryIntIdDataDate1'
GROUP BY OBJECT_NAME(IXOS.OBJECT_ID), IX.name, IX.type_desc,IXOS.LEAF_INSERT_COUNT, IXOS.LEAF_UPDATE_COUNT,IXOS.LEAF_DELETE_COUNT,IXOS.partition_number
order by 4;
