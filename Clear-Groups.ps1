<# 
.SYNOPSIS
This function takes an Active Directory group name, lists all current members, and removed the members from the supplied group name.
.DESCRIPTION
 A group or array of group names is operated on. Each group named will have all of its members removed from the group.
.EXAMPLE
 Clear-Groups -DomainController MyDC.mydomain -Groups Temp-Group1,Temp-Group2
.INPUTS
.OUTPUTS
.NOTES
#>
function Clear-Groups {
 [cmdletbinding()]
 param ( 
  [Parameter(Position = 0, Mandatory = $True)]
  [Alias('DC')]
  [string]$DomainController,
  [Parameter(Position = 1, Mandatory = $True)]
  [Alias('ADCred')]
  [System.Management.Automation.PSCredential]$Credential,
  [Parameter(Position = 2, Mandatory = $True)]
  [string[]]$Groups,
  [Parameter(Position = 3, Mandatory = $false)]
  [SWITCH]$WhatIf
 )
 
 Begin {
  . .\lib\Add-Log.ps1

  if ( Test-Connection -ComputerName $DomainController) { 
   $adCmdLets = 'Get-ADGroupMember', 'Remove-ADGroupMember'
   $adSession = New-PSSession -ComputerName $DomainController -Credential $Credential
   Import-PSSession -Session $adSession -Module ActiveDirectory -CommandName $adCmdLets -AllowClobber
  }
  else {

  }
 }
 Process {
  foreach ($group in $Groups) {
   # BEGIN PROCESS GROUPS
   Write-Verbose $group
   $members = (Get-ADGroupMember -Identity $group).SamAccountName

   if (!$members) { "No members in $group."; continue }

   foreach ($sam in $members) {
    Add-Log remove "$group,$sam,member"
   }
   Remove-ADGroupMember -Identity $group -Members $members -Confirm:$false -WhatIf:$WhatIf
  } # END PROCESS GROUPS
 }

 End {
  'Tearing down sessions...'
  Get-PSSession | Remove-PSSession -WhatIf:$false
 }

} # END
