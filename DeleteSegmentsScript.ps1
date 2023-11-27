Read-Host -Prompt "Please enter the FQDN of the NSX Server (use the VIP where possible)..." -OutVariable nsxtServer
 
Write-Host "Please provide valid credentials for connecting to the NSX-T Server..."
$cred=Get-Credential
 
Read-Host -Prompt "Please enter the full path to the CSV file with External VLAN segments (e.g. C:\Users\administrator\Documents\segments.csv):" -OutVariable csvFileVlan
 
Write-Host "Connecting to NSX Server now..`n`n"
Connect-NsxServer -Server $nsxtServer -Credential $cred
 
Import-Csv $csvFileVlan | ForEach-Object {
    # Setting variables
    $vlanSegmentName = $_.Segment_Name
	Invoke-DeleteInfraSegment -Segment $vlanSegmentName
	Write-Host "Deleted segment $vlanSegmentName."
	}
 
Disconnect-NsxServer -Server $nsxtServer
