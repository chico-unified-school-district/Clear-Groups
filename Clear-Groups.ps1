[cmdletbinding()]
param (
 [Parameter(Position = 0, Mandatory = $True)]
 [Alias('DCs')]
 [string[]]$DomainControllers,
 [Parameter(Position = 1, Mandatory = $True)]
 [Alias('ADCred')]
 [System.Management.Automation.PSCredential]$Credential,
 [Parameter(Position = 2, Mandatory = $True)]
 [string[]]$Groups,
 [Parameter(Position = 3, Mandatory = $false)]
 [Alias('wi')]
 [SWITCH]$WhatIf
)

function New-ADSession ($dcs) {
 Write-Host ('{0},{1}' -f $MyInvocation.MyCommand.Name, ($dcs -join ','))
 $dc = Select-DomainController $dcs
 $adCmdLets = 'Get-ADGroup', 'Get-ADGroupMember', 'Remove-ADGroupMember'
 $adSession = New-PSSession -ComputerName $dc -Credential $Credential
 Import-PSSession -Session $adSession -Module ActiveDirectory -CommandName $adCmdLets -AllowClobber | Out-Null
}

function Get-GroupObj {
 process {
  Write-Host ('{0},{1},Finding Group...' -f $MyInvocation.MyCommand.Name, $_)
  $group = Get-ADGroup -Identity $_
  if ($group) {
   Write-Host ('{0},{1},Group Found' -f $MyInvocation.MyCommand.Name, $_)
   $group
  }
  else {
   Write-Host ('{0},{1},Group not found.' -f $MyInvocation.MyCommand.Name, $_)
  }
 }
}

function Get-GroupObjMember {
 process {
  $members = Get-ADGroupMember -Identity $_.ObjectGUID
  if (-not$members) { return }
  foreach ($user in $members) {
   New-MemberObj -group $_ -member $user.samAccountName
  }
 }
}

function New-MemberObj($group, $member) {
 [PSCustomObject]@{
  group  = $group
  member = $member
 }
}

function Remove-GroupMember {
 process {
  $msgVars = $MyInvocation.MyCommand.Name, $_.group.name.ToUpper(), $_.member
  Write-Host ('{0},[{1}],[{2}]' -f $msgVars)
  Remove-ADGroupMember -Identity $_.group.ObjectGUID -member $_.member -Confirm:$false -WhatIf:$WhatIf
 }
}

. .\lib\Clear-SessionData.ps1
. .\lib\Select-DomainController.ps1
. .\lib\Show-TestRun.ps1

Show-TestRun
Clear-SessionData
New-ADSession $DomainControllers
$Groups | Get-GroupObj | Get-GroupObjMember | Remove-GroupMember