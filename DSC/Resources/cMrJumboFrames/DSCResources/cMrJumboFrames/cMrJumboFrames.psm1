function Get-TargetResource {

	[CmdletBinding()]
	[OutputType([Hashtable])]
	param (
		[Parameter(Mandatory)]
		[String]$InterfaceAlias
	)
  $CurrentSettings = Get-NetAdapterAdvancedProperty -InterfaceAlias $InterfaceAlias |
                     Where-Object RegistryKeyword -eq '*JumboPacket'

  Write-Verbose -Message 'Determining if the NIC manufacturer uses 1500 or 1514 for the default packet size setting.'
  [int]$NormalPacket = [int]$CurrentSettings.DefaultRegistryValue
  [int]$JumboPacket = [int]$CurrentSettings.DefaultRegistryValue + 7500

  $returnValue = @{
    InterfaceAlias = $InterfaceAlias
    Ensure = switch ($CurrentSettings.RegistryValue) {
      $JumboPacket {'Present'}
      $NormalPacket {'Absent'}
    }
	}
	$returnValue
}

function Set-TargetResource {

	[CmdletBinding()]
	param (
	  [Parameter(Mandatory)]
	  [String]$InterfaceAlias,

    [Parameter(Mandatory)]
	  [ValidateSet('Absent','Present')]
	  [String]$Ensure
	)

  $CurrentSettings = Get-NetAdapterAdvancedProperty -InterfaceAlias $InterfaceAlias |
                     Where-Object RegistryKeyword -eq '*JumboPacket'

  Write-Verbose -Message 'Determining if the NIC manufacturer uses 1500 or 1514 for the default packet size setting.'
  [int]$NormalPacket = [int]$CurrentSettings.DefaultRegistryValue
  [int]$JumboPacket = [int]$CurrentSettings.DefaultRegistryValue + 7500

  switch ($Ensure) {
    'Absent' {[int]$DesiredSetting = $NormalPacket}
    'Present' {[int]$DesiredSetting = $JumboPacket}
  }

  if ($CurrentSettings.RegistryValue -ne $DesiredSetting -and $CurrentSettings.RegistryValue -ne $null) {
    Set-NetAdapterAdvancedProperty -InterfaceAlias $InterfaceAlias -RegistryKeyword '*JumboPacket' -RegistryValue $DesiredSetting -PassThru
  }
}

function Test-TargetResource {

	[CmdletBinding()]
	[OutputType([Boolean])]
	param (
		[Parameter(Mandatory)]
		[String]$InterfaceAlias,

    [Parameter(Mandatory)]
		[ValidateSet('Absent','Present')]
		[String]$Ensure
	)

  $CurrentSettings = Get-NetAdapterAdvancedProperty -InterfaceAlias $InterfaceAlias |
                     Where-Object RegistryKeyword -eq '*JumboPacket'

  Write-Verbose -Message 'Determining if the NIC manufacturer uses 1500 or 1514 for the default packet size setting.'
  [int]$NormalPacket = [int]$CurrentSettings.DefaultRegistryValue
  [int]$JumboPacket = [int]$CurrentSettings.DefaultRegistryValue + 7500

  switch ($Ensure) {
    'Absent' {[int]$DesiredSetting = $NormalPacket}
    'Present' {[int]$DesiredSetting = $JumboPacket}
  }

  if ($CurrentSettings.RegistryValue -ne $DesiredSetting -and $CurrentSettings.RegistryValue -ne $null) {
    Write-Verbose -Message "Jumbo Frames setting is Non-Compliant! Value should be $DesiredSetting - Detected value is: $($CurrentSettings.RegistryValue)."
    [Boolean]$result = $false
  }
  elseif ($CurrentSettings.RegistryValue -eq $DesiredSetting) {
    Write-Verbose -Message 'Jumbo Frames setting matches the desired state.'
    [Boolean]$result = $true
  }
  $result
}

Export-ModuleMember -Function *-TargetResource