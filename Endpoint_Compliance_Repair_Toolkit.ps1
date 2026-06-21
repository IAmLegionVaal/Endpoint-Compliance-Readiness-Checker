[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [switch]$EnableFirewall,
 [switch]$EnableDefender,
 [switch]$RunQuickScan,
 [ValidatePattern('^[A-Z]$')][string]$ResumeBitLocker,
 [switch]$StartComplianceServices,
 [switch]$DryRun,[switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'EndpointComplianceRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State{[pscustomobject]@{Collected=Get-Date;Firewall=Get-NetFirewallProfile|Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction;Defender=Get-MpComputerStatus -ErrorAction SilentlyContinue|Select-Object AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated,QuickScanAge;BitLocker=Get-BitLockerVolume -ErrorAction SilentlyContinue|Select-Object MountPoint,VolumeStatus,ProtectionStatus,EncryptionPercentage;Services=Get-Service WinDefend,mpssvc,wuauserv,bits,cryptsvc -ErrorAction SilentlyContinue|Select-Object Name,Status,StartType}}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
State|ConvertTo-Json -Depth 6|Set-Content $before -Encoding UTF8
if(-not($EnableFirewall -or $EnableDefender -or $RunQuickScan -or $ResumeBitLocker -or $StartComplianceServices)){Write-Error 'Choose at least one repair action.';exit 2}
if(-not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell.';exit 4}
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected compliance repairs? Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
if($EnableFirewall){Act 'Enabling all Windows Firewall profiles' {Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True}}
if($EnableDefender){Act 'Enabling Microsoft Defender real-time monitoring' {Set-MpPreference -DisableRealtimeMonitoring $false}}
if($RunQuickScan){Act 'Starting Microsoft Defender quick scan' {Start-MpScan -ScanType QuickScan}}
if($ResumeBitLocker){$mount="${ResumeBitLocker}:";$v=Get-BitLockerVolume -MountPoint $mount -ErrorAction Stop;if($v.VolumeStatus -notmatch 'Encrypted|EncryptionInProgress'){Write-Error "$mount is not an encrypted BitLocker volume.";exit 2};Act "Resuming BitLocker protection on $mount" {Resume-BitLocker -MountPoint $mount}}
if($StartComplianceServices){foreach($s in 'WinDefend','mpssvc','wuauserv','bits','cryptsvc'){Act "Starting service $s" {Set-Service $s -StartupType Automatic -ErrorAction SilentlyContinue;Start-Service $s -ErrorAction Stop}}}
Start-Sleep 2;State|ConvertTo-Json -Depth 6|Set-Content $after -Encoding UTF8
if($script:Failures){Log "Completed with $script:Failures failure(s).";exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
