SELECT @@SERVERNAME as ServerName,
    [sJOB].[name] AS [JobName],
       CASE [sJOB].[enabled]
        WHEN 0 THEN 'Disabled'
        WHEN 1 THEN 'Enabled'
      END AS [EnabledStatus]
    , CASE 
        WHEN [sJOBH].[run_date] IS NULL OR [sJOBH].[run_time] IS NULL THEN NULL
        ELSE CAST(
                CAST([sJOBH].[run_date] AS CHAR(8))
                + ' ' 
                + STUFF(
                    STUFF(RIGHT('000000' + CAST([sJOBH].[run_time] AS VARCHAR(6)),  6)
                        , 3, 0, ':')
                    , 6, 0, ':')
                AS DATETIME)
      END AS [LastRunDateTime]
    , CASE [sJOBH].[run_status]
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'Running' -- In Progress
      END AS [LastRunStatus]
         , (([sJOBH].run_duration)/60) as Run_Duration_In_Min
        
FROM 
    [msdb].[dbo].[sysjobs] AS [sJOB]
    LEFT JOIN (
                SELECT
                    [job_id]
                    , MIN([next_run_date]) AS [NextRunDate]
                    , MIN([next_run_time]) AS [NextRunTime]
                FROM [msdb].[dbo].[sysjobschedules]
                GROUP BY [job_id]
            ) AS [sJOBSCH]
        ON [sJOB].[job_id] = [sJOBSCH].[job_id]
    LEFT JOIN (
                SELECT 
                    [job_id]
                    , [run_date]
                    , [run_time]
                    , [run_status]
                    , [run_duration]
                    , [message]
                    , ROW_NUMBER() OVER (
                                            PARTITION BY [job_id] 
                                            ORDER BY [run_date] DESC, [run_time] DESC
                      ) AS RowNumber
                FROM [msdb].[dbo].[sysjobhistory]
                WHERE [step_id] = 0
                           AND [run_status]=1 
            ) AS [sJOBH]
        ON [sJOB].[job_id] = [sJOBH].[job_id]
              AND [sJOB].[enabled]=1
        AND [sJOBH].[RowNumber] = 1
              where [sJOB].enabled=1 and ([sJOB].name like '%DD %' or [sJOB].name like '%stat%' or [sJOB].name like '%inte%' or [sJOB].name like '%rebuild%' or [sJOB].name like '%reorg%')
              and [sJOB].name !='DD Cleanup' 
ORDER BY [JobName]
