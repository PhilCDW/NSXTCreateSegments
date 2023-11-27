Write-Host "This script is designed to create VLAN-backed segments based on the contents of a CSV file defining the Segment Name and VLAN ID.`n`n"
 
Read-Host -Prompt "Please enter the FQDN of the NSX Server (use the VIP where possible)..." -OutVariable nsxtServer
 
Write-Host "Please provide valid credentials for connecting to the NSX-T Server..."
$cred=Get-Credential
 
Read-Host -Prompt "Please enter the full path to the CSV file with External VLAN segments (e.g. C:\Users\administrator\Documents\segments.csv):" -OutVariable csvFileVlan
 
Write-Host "Connecting to NSX Server now..`n`n"
Connect-NsxServer -Server $nsxtServer -Credential $cred
 
## Creating a list of transport zones from which the user can select the correct one
$tzs=Invoke-ListTransportZonesForEnforcementPoint -EnforcementPointId "default" -SiteId "default"
$selectedVlanTz=$tzs.results.DisplayName | Out-GridView -Title "Select in which VLAN transport zone to create the segments" -OutputMode Single
if ($selectedVlanTz)
    {
        Write-Host "You selected the VLAN transport zone named $selectedVlanTz.`n`n"
        Start-Sleep 10
    } else {
        Write-Host "You did not select a VLAN transport zone. Exiting..."
        Break
    }
 
$vlanTz=$tzs.results | Where-Object {$_.DisplayName -eq $selectedVlanTz}
$vlanTzPath=$vlanTz.Path
 
Write-Host "Now reading CSV file and creating the required segments...`n`n"
Start-Sleep 5
 
Import-Csv $csvFileVlan | ForEach-Object {
    # Setting variables
    $vlanSegmentName = $_.Segment_Name
	$uplinkPolicy = $_.Uplink_Policy
    $array = @()
	$array += $_.VLAN_ID
	$vlanArray = $array -split(" ")
 
if ($uplinkPolicy)
	{
		Write-Host "This segment has a requirement for the named uplink policy named $uplinkPolicy."
		# Initializing Segment advanced configuration to add named teaming policy
		$segmentAdvConfig = Initialize-SegmentAdvancedConfig -UplinkTeamingPolicyName $uplinkPolicy
		# Initializing segment objects
		$vlanSegment = Initialize-Segment -DisplayName $vlanSegmentName -TransportZonePath "$vlanTzPath" -VlanIds $vlanArray -AdvancedConfig $segmentAdvConfig
 
		# Creating the segment in NSX-T
		Invoke-PatchInfraSegment -Segment $vlanSegment -SegmentId $vlanSegmentName
		Write-Host "Created segment $vlanSegmentName with VLAN ID $vlanArray and uplink profile $uplinkPolicy."
	} else {
		# Initializing segment objects
		$vlanSegment = Initialize-Segment -DisplayName $vlanSegmentName -TransportZonePath "$vlanTzPath" -VlanIds $vlanArray
 
		# Creating the segment in NSX-T
		Invoke-PatchInfraSegment -Segment $vlanSegment -SegmentId $vlanSegmentName
		Write-Host "Created segment $vlanSegmentName with VLAN ID $vlanArray."
	}
}
 
Disconnect-NsxServer -Server $nsxtServer
