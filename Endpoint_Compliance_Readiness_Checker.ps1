#requires -Version 5.1
<#
.SYNOPSIS
    Endpoint Compliance Readiness Checker.
.DESCRIPTION
    Read-only endpoint readiness context reporter for Windows support.
#>
[CmdletBinding()]
param([string]$OutputPath)

$RunStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Compliance_Readiness_Reports' }
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
function New-Check { param($Category,$Name,$Status,$Value,$Recommendation) [PSCustomObject]@{Category=$Category;Name=$Name;Status=$Status;Value=$Value;Recommendation=$Recommendation} }
$checks=@()
$os=Get-CimInstance Win32_OperatingSystem
$checks += New-Check 'System' 'OS build' 'Info' "$($os.Caption) Build $($os.BuildNumber)" 'Record OS build for compliance review.'
$drive=Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'"
$free=[math]::Round($drive.FreeSpace/1GB,2)
$checks += New-Check 'Disk' 'System drive free space' ($(if($free -lt 10){'Warning'}else{'OK'})) "$free GB" 'Low free space can affect readiness.'
try{Get-NetFirewallProfile | ForEach-Object { $checks += New-Check 'Firewall' $_.Name ($(if($_.Enabled){'OK'}else{'Warning'})) "Enabled=$($_.Enabled)" 'Firewall should normally be enabled.' }}catch{}
try{$mp=Get-MpComputerStatus; $checks += New-Check 'Defender' 'Real-time protection' ($(if($mp.RealTimeProtectionEnabled){'OK'}else{'Warning'})) $mp.RealTimeProtectionEnabled 'Review endpoint protection state.'}catch{$checks += New-Check 'Defender' 'Defender query' 'Info' $_.Exception.Message 'May use another security product.'}
try{Get-BitLockerVolume | ForEach-Object { $checks += New-Check 'BitLocker' $_.MountPoint ($(if($_.ProtectionStatus -eq 'On'){'OK'}else{'Info'})) "Protection=$($_.ProtectionStatus)" 'Review encryption requirement.' }}catch{}
$pending = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')
$checks += New-Check 'Reboot' 'Pending reboot indicator' ($(if($pending){'Warning'}else{'OK'})) $pending 'Restart may be needed before readiness sign-off.'
$checks | Export-Csv (Join-Path $OutputPath "compliance_readiness_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$checks | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputPath "compliance_readiness_$RunStamp.json") -Encoding UTF8
$checks | ConvertTo-Html -Title 'Endpoint Compliance Readiness' -PreContent "<h1>Endpoint Compliance Readiness - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p>" | Set-Content (Join-Path $OutputPath "compliance_readiness_$RunStamp.html") -Encoding UTF8
$checks | Format-Table -AutoSize -Wrap
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "`"$OutputPath`"" -ErrorAction SilentlyContinue
