#!powershell

# WANT_JSON
# POWERSHELL_COMMON

$ErrorActionPreference = 'Stop'

$params = Parse-Args -arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false
$diff_mode = Get-AnsibleParam -obj $params -name "_ansible_diff" -type "bool" -default $false


$result = @{
    changed = $false
}


$domainName = Get-AnsibleParam -obj $params -name "domain_name" -type "str" -failifempty $true
$safeModePassword = Get-AnsibleParam -obj $params -name "safe_mode_password" -type "str" -failifempty $true
$netBiosName = Get-AnsibleParam -obj $params -name "netbios_name" -type "str" -failifempty $true

try {
    Import-Module ADDSDeployment
}
catch {
    Fail-Json $result "Failed at Import-Module ADDSDeployment " + $_.Exception.Message
}

try {
    Get-ADDomainController | Out-Null
    Exit-Json $result
}
catch {
}

$secureSafeModePassword = ConvertTo-SecureString "$safeModePassword" -AsPlainText -Force

try {
$outResult = Install-ADDSForest `
    -InstallDns:$true `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "Win2012R2" `
    -DomainName "$domainName" `
    -DomainNetbiosName "$netbiosName" `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $secureSafeModePassword `
    -Force:$true

$result.output = $outResult
$result.changed = $true
  
} catch {
    Fail-Json $result "Failed at Install-ADDSForest: " + $Error
}
Exit-Json $result
