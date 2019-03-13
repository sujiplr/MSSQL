  Remove-Item D:\BackupReport\Output\SuccessBackup_$((Get-Date).AddDays(-30).ToString('dd_MM_yyyy')).txt
  Remove-Item D:\BackupReport\Output\FailedBackup_$((Get-Date).AddDays(-30).ToString('dd_MM_yyyy')).txt
  Remove-Item D:\BackupReport\Output\BackupCount_$((Get-Date).AddDays(-30).ToString('dd_MM_yyyy')).txt
    
  $servers = Get-Content -Path D:\BackupReport\BackupServers.txt

Foreach ($dataSource in $servers) 
{
    $sqlCommand = $("EXEC BackupStatusReportSuccess") 
    $connectionString = "Data Source=$dataSource; " + "Integrated Security=SSPI; " + "Initial Catalog='sysadmin'"
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $command.CommandTimeout=60
    $connection.Open()
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    write-output $adapter.Fill($dataSet) | Format-Table
    $connection.Close() 
    $out=$dataSet.Tables | Format-Table -AutoSize | Out-File -Filepath D:\BackupReport\Output\SuccessBackup_$(get-date -f dd_MM_yyyy).txt -Append  
} 

Foreach ($dataSource in $servers) 
{
    $sqlCommand = $("EXEC BackupStatusReport")    
    $connectionString = "Data Source=$dataSource; " + "Integrated Security=SSPI; " + "Initial Catalog='sysadmin'"
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $command.CommandTimeout=60
    $connection.Open()
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    write-output $adapter.Fill($dataSet) | Format-Table
    $connection.Close() 
    $out=$dataSet.Tables | Format-Table -AutoSize | Out-File -Filepath D:\BackupReport\Output\FailedBackup_$(get-date -f dd_MM_yyyy).txt -Append  
}

Foreach ($dataSource in $servers) 
{
    $sqlCommand = $("EXEC BackupCount")    
    $connectionString = "Data Source=$dataSource; " + "Integrated Security=SSPI; " + "Initial Catalog='sysadmin'"
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $command.CommandTimeout=60
    $connection.Open()
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    write-output $adapter.Fill($dataSet) | Format-Table
    $connection.Close() 
    $out=$dataSet.Tables | Format-Table -AutoSize | Out-File -Filepath D:\BackupReport\Output\BackupCount_$(get-date -f dd_MM_yyyy).txt -Append  
}

$From = 'mail id'
$To = "mail id","mail id"
$Cc ="mail id"
$Attachment = 'D:\BackupReport\Output\SuccessBackup_' +$(get-date -f dd_MM_yyyy) +'.txt'
$Attchment1 = 'D:\BackupReport\Output\FailedBackup_' +$(get-date -f dd_MM_yyyy) +'.txt'
$Attachment2= 'D:\BackupReport\Output\BackupCount_' +$(get-date -f dd_MM_yyyy) +'.txt'
$Subject = 'MSSQL Databases Backup Report - AB DataCenter'
$Body = 'Hi,

This is a backup report which has all the backups for MSSQL databases. Attachment has 

    1) All Full & Differential Successful backups with in 24 hours

    2) All Full & Differential Failed backups with in 24 hours

'
$SMTPServer = ''
$SMTPPort = '25'
Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Attachments $Attachment,$Attchment1,$Attachment2 -Priority High
