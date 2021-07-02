$NSXFQDN = Read-Host -Prompt 'Input your NSX-T FQDN'
$credentials = Get-Credential
$TransportID = Read-Host -Prompt 'Input your Transport Zone ID'

Connect-NsxtServer -Server $NSXFQDN -Credential $credentials

# Below will list out all trasportzones
#$tZoneSvc = Get-NsxtService -Name com.vmware.nsx.transport_zones
#$tZoneSvc | Get-Member
#$tZones = $tZoneSvc.list()
#$tZones.results


#Transport Zone
$transportZone = "/infra/sites/default/enforcement-points/default/transport-zones/$TransportID"
$transportZone
Import-Csv ".\nsxt-segments.txt" | ForEach-Object {
 
    # Set variables from csv data
    $segmentId = $_.pgName
    $vlanArray = @($_.VlanID)
 
    # Pull the current segment information
    $segmentList = Get-NsxtPolicyService -Name com.vmware.nsx_policy.infra.segments
 
    # Creating a new segment object
    $newSegmentSpec = $segmentList.Help.patch.segment.Create()
    $newSegmentSpec[0].id = $segmentId
    $newSegmentSpec[0].vlan_ids = $vlanArray
    $newSegmentSpec[0].transport_zone_path = $transportZone
 
    # Create the segment
    $segmentList[0].patch($segmentId, $newSegmentSpec[0])
    Write-Host("Created segment "+$segmentId+ " with vlan ID "+$vlanArray)
  }