# Endpoint Compliance Readiness Checker

A PowerShell toolkit for Windows endpoint readiness checks and selected guarded compliance repairs.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Endpoint_Compliance_Readiness_Checker.ps1
```

## Repair script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Endpoint_Compliance_Repair_Toolkit.ps1 -EnableFirewall -DryRun
```

Examples:

```powershell
.\Endpoint_Compliance_Repair_Toolkit.ps1 -EnableFirewall
.\Endpoint_Compliance_Repair_Toolkit.ps1 -EnableDefender -RunQuickScan
.\Endpoint_Compliance_Repair_Toolkit.ps1 -ResumeBitLocker C
.\Endpoint_Compliance_Repair_Toolkit.ps1 -StartComplianceServices
```

## What the repair does

- Enables Domain, Private and Public Windows Firewall profiles.
- Enables Microsoft Defender real-time monitoring.
- Starts a Defender quick scan.
- Resumes protection on one already encrypted BitLocker volume.
- Starts selected Defender, firewall and Windows Update services.
- Captures firewall, Defender, BitLocker and service state before and after repair.
- Supports `-DryRun`, confirmation prompts, logs and clear exit codes.

## Safety

The tool does not start BitLocker encryption, change recovery keys, alter firewall rules or disable security controls. Resume BitLocker only after confirming the recovery key is available.

## Author

Dewald Pretorius — L2 IT Support Engineer
