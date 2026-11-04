@echo off
setlocal enabledelayedexpansion
:: ============================================================================
::  CyberPatriot WINDOWS 11 COMPETITION SCRIPT  -  "Quick Strike"
::
::  Purpose : One-pass application of every SAFE, high-probability scoring
::            action, plus a review report for the judgment-call items.
::            This is the script you run FIRST on competition day.
::            The interactive Harden.bat / Harden.ps1 suite stays for practice
::            and for careful step-by-step rounds.
::
::  Target  : Windows 11 (also works on Win 10 / Server 2019+ standalone)
::  Usage   : Right-click -> Run as administrator
::  Config  : Reads admins.txt / users.txt / critical_services.txt from the
::            same folder (same files the practice suite uses).
::
::  NOTE    : No wmic (removed in Win11 24H2), no IE keys, no HomeGroup keys.
::            NEVER disable core services (RpcSs, SamSs, LanmanServer, ...).
:: ============================================================================

title CyberPatriot Win11 Quick Strike
color 0b

:: ------------------------------- preflight ---------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] Administrator rights required.
    echo        Right-click this file and select "Run as administrator".
    pause
    exit /b 1
)

cd /d "%~dp0"
set "REPORT=%~dp0CP_Win11_Report.txt"
set "CRITFILE=%~dp0critical_services.txt"
set "MEDIA_EXTS=*.mp3 *.mp4 *.m4a *.m4v *.mov *.avi *.wav *.flac *.ogg *.wma *.wmv *.mpg *.mpeg *.flv *.webm *.aac"

break > "%REPORT%"
echo ============================================================== >> "%REPORT%"
echo  CyberPatriot Win11 Quick Strike - started %DATE% %TIME%       >> "%REPORT%"
echo  Computer: %COMPUTERNAME%   User: %USERNAME%                   >> "%REPORT%"
echo ============================================================== >> "%REPORT%"

echo ======================================================================
echo    CYBERPATRIOT WIN11 QUICK STRIKE
echo ======================================================================
echo  [WARN] STEP 0: Answer ALL forensics questions BEFORE running this.
echo         This script deletes media files and changes system policy.
echo  [WARN] Fill admins.txt / users.txt / critical_services.txt from the
echo         README first - the account audit and report use them.
echo ======================================================================
set /p GO="Type YES to continue: "
if /I not "%GO%"=="YES" (
    echo [-] Aborted. Go answer forensics questions first.
    pause
    exit /b 1
)

:: ------------------------------- menu --------------------------------------
:MENU
cls
echo ======================================================================
echo    CYBERPATRIOT WIN11 QUICK STRIKE          Report: %REPORT%
echo ======================================================================
echo   A) RUN EVERYTHING (1-9 in order)  <-- competition day choice
echo   1) Firewall harden
echo   2) Password + lockout policy + full auditing
echo   3) Registry hardening (UAC, LSA, SMB signing, logon)
echo   4) Disable risky services + RDP decision
echo   5) Disable insecure features (SMBv1, Telnet, TFTP, PS 2.0)
echo   6) Windows Update policy + Defender on
echo   7) Built-in accounts (Guest off, Administrator decision)
echo   8) Media file sweep (report + optional delete)
echo   9) BUILD REVIEW REPORT (users, admins, persistence, shares, ports)
echo   Q) Exit
echo ----------------------------------------------------------------------
set /p OPT="Select an option: "
if /I "%OPT%"=="A" goto :ALL
if /I "%OPT%"=="1" goto :S1
if /I "%OPT%"=="2" goto :S2
if /I "%OPT%"=="3" goto :S3
if /I "%OPT%"=="4" goto :S4
if /I "%OPT%"=="5" goto :S5
if /I "%OPT%"=="6" goto :S6
if /I "%OPT%"=="7" goto :S7
if /I "%OPT%"=="8" goto :S8
if /I "%OPT%"=="9" goto :S9
if /I "%OPT%"=="Q" exit /b 0
goto :MENU

:ALL
call :S1
call :S2
call :S3
call :S4
call :S5
call :S6
call :S7
call :S8
call :S9
echo.
echo [+] Full sweep complete. Review the report:
echo     %REPORT%
pause
goto :MENU

:: ============================================================================
:S1  :: Firewall
:: ============================================================================
call :LOG "1. Firewall: enable all profiles, block inbound, log drops"
netsh advfirewall set allprofiles state on >nul
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound >nul
netsh advfirewall set allprofiles logging droppedconnections enable >nul
netsh advfirewall set allprofiles settings inboundusernotification enable >nul
for %%r in ("Remote Assistance (DCOM-In)" "Remote Assistance (PNRP-In)" "Remote Assistance (RA Server TCP-In)" "Remote Assistance (SSDP TCP-In)" "Remote Assistance (SSDP UDP-In)" "Remote Assistance (TCP-In)" "Telnet Server" "netcat") do (
    netsh advfirewall firewall set rule name=%%r new enable=no >nul 2>&1
)
call :LOG "1. Done - firewall on, inbound blocked, RA/telnet rules disabled"
pause
goto :MENU

:: ============================================================================
:S2  :: Password + lockout + auditing
:: ============================================================================
call :LOG "2. Policies: net accounts + secedit + auditpol"
net accounts /minpwlen:12 /maxpwage:60 /minpwage:1 /uniquepw:5 /lockoutthreshold:5 /lockoutduration:30 /lockoutwindow:30 >nul
call :LOG "2. net accounts set (len 12, age 60/1, history 5, lockout 5/30/30)"

set "INF=%TEMP%\CP_sec.inf"
set "SDB=%TEMP%\CP_sec.sdb"
break > "%INF%"
>> "%INF%" echo [Unicode]
>> "%INF%" echo Unicode=yes
>> "%INF%" echo [Version]
>> "%INF%" echo signature="$CHICAGO$"
>> "%INF%" echo Revision=1
>> "%INF%" echo [System Access]
>> "%INF%" echo MinimumPasswordLength = 12
>> "%INF%" echo PasswordComplexity = 1
>> "%INF%" echo MaximumPasswordAge = 60
>> "%INF%" echo MinimumPasswordAge = 1
>> "%INF%" echo PasswordHistorySize = 5
>> "%INF%" echo ClearTextPassword = 0
>> "%INF%" echo LockoutBadCount = 5
>> "%INF%" echo ResetLockoutCount = 30
>> "%INF%" echo LockoutDuration = 30
>> "%INF%" echo EnableGuestAccount = 0
>> "%INF%" echo LSAAnonymousNameLookup = 0
>> "%INF%" echo [Event Audit]
>> "%INF%" echo AuditSystemEvents = 3
>> "%INF%" echo AuditLogonEvents = 3
>> "%INF%" echo AuditObjectAccess = 3
>> "%INF%" echo AuditPrivilegeUse = 3
>> "%INF%" echo AuditPolicyChange = 3
>> "%INF%" echo AuditAccountManage = 3
>> "%INF%" echo AuditProcessTracking = 3
>> "%INF%" echo AuditDSAccess = 3
>> "%INF%" echo AuditAccountLogon = 3
secedit /export /cfg "%TEMP%\CP_secpol_backup.inf" /quiet >nul 2>&1
secedit /configure /db "%SDB%" /cfg "%INF%" /areas SECURITYPOLICY /quiet >nul 2>&1
gpupdate /force >nul 2>&1
call :LOG "2. secedit applied (complexity on, backup at %TEMP%\CP_secpol_backup.inf)"

auditpol /set /category:* /success:enable /failure:enable >nul 2>&1
call :LOG "2. auditpol: all categories success+failure"
pause
goto :MENU

:: ============================================================================
:S3  :: Registry hardening
:: ============================================================================
call :LOG "3. Registry: UAC, LSA, logon, SMB signing, null sessions"
:: --- UAC maximum ---
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableInstallerDetection /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableVirtualization /t REG_DWORD /d 1 /f >nul
:: --- Logon settings ---
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v dontdisplaylastusername /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AllocateCDRoms /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AllocateFloppies /t REG_DWORD /d 1 /f >nul
:: --- LSA / anonymous / NTLM ---
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymous /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymousSAM /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v EveryoneIncludesAnonymous /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v DisableDomainCreds /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 5 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v auditbaseobjects /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\LSASS.exe" /v AuditLevel /t REG_DWORD /d 8 /f >nul
:: --- SMB / session ---
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoDisconnect /t REG_DWORD /d 15 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v EnableSecuritySignature /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v NullSessionPipes /t REG_MULTI_SZ /d "" /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v NullSessionShares /t REG_MULTI_SZ /d "" /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v EnablePlainTextPassword /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v RequireStrongKey /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v RequireSignOrSeal /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v SignSecureChannel /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v SealSecureChannel /t REG_DWORD /d 1 /f >nul
:: --- Remote registry paths locked down ---
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg\AllowedExactPaths" /v Machine /t REG_MULTI_SZ /d "" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg\AllowedPaths" /v Machine /t REG_MULTI_SZ /d "" /f >nul 2>&1
:: --- SmartScreen / printer drivers / autorun ---
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Require" /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers" /v AddPrinterDrivers /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f >nul
:: --- Accessibility backdoor (sticky keys) ---
reg add "HKU\.DEFAULT\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "506" /f >nul
:: --- DEP always on ---
bcdedit /set {current} nx AlwaysOn >nul 2>&1
call :LOG "3. Done - 35+ registry keys applied, DEP AlwaysOn"
pause
goto :MENU

:: ============================================================================
:S4  :: Services + RDP
:: ============================================================================
call :LOG "4. Services: stopping and disabling the safe bad-list"
:: Ensure essential security services are automatic and running
for %%e in (MpsSvc EventLog wuauserv WinDefend) do (
    sc config "%%e" start= auto >nul 2>&1
    sc start "%%e" >nul 2>&1
)
:: NEVER add these to the bad list: RpcSs SamSs LanmanServer LanmanWorkstation
:: Dhcp Dnscache NtLmSsp wuauserv WinDefend (older reference scripts that
:: disable RpcSs will brick networking - that was a bug, not a feature).
for %%s in (RemoteRegistry TlntSvr ftpsvc msftpsvc SNMP SNMPTRAP SSDPSRV upnphost RemoteAccess RasAuto simptcp iprip SharedAccess Fax TapiSrv) do (
    sc stop "%%s" >nul 2>&1
    sc config "%%s" start= disabled >nul 2>&1
)
call :LOG "4. Bad services stopped + disabled (RemoteRegistry, Telnet, FTP, SNMP, UPnP, ...)"

:: --- IIS check ---
call :CRIT iis
if %errorlevel% equ 0 (
    call :LOG "4. IIS listed critical - keeping W3SVC running"
) else (
    sc stop W3SVC >nul 2>&1
    sc config W3SVC start= disabled >nul 2>&1
    call :LOG "4. W3SVC/IIS stopped (not listed critical)"
)

:: --- RDP decision ---
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f >nul
call :CRIT rdp
if %errorlevel% equ 0 (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
    netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes >nul 2>&1
    call :LOG "4. RDP is CRITICAL - enabled with NLA required"
) else (
    set /p RDPIN="4. RDP is not in critical_services.txt. Disable RDP? [Y/n]: "
    if /I "!RDPIN!"=="n" (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
        netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes >nul 2>&1
        call :LOG "4. RDP kept ENABLED with NLA required"
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f >nul
        sc stop TermService >nul 2>&1
        sc config TermService start= disabled >nul 2>&1
        sc config SessionEnv start= disabled >nul 2>&1
        sc config UmRdpService start= disabled >nul 2>&1
        netsh advfirewall firewall set rule group="Remote Desktop" new enable=no >nul 2>&1
        call :LOG "4. RDP disabled (service + firewall + registry, NLA=1 preserved)"
    )
)
pause
goto :MENU

:: ============================================================================
:S5  :: Insecure features (DISM)
:: ============================================================================
call :LOG "5. Features: disabling SMBv1, Telnet, TFTP, PowerShell 2.0 engine"
for %%f in (SMB1Protocol TelnetClient TelnetServer TFTP MicrosoftWindowsPowerShellV2 MicrosoftWindowsPowerShellV2Root SimpleTCP) do (
    dism /online /disable-feature /featurename:%%f /norestart >nul 2>&1
)
call :LOG "5. Done - features disabled (no restart required yet)"
pause
goto :MENU

:: ============================================================================
:S6  :: Updates + Defender
:: ============================================================================
call :LOG "6. Updates + Defender: enabling auto-update policy and real-time protection"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 4 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AutoInstallMinorUpdates /t REG_DWORD /d 1 /f >nul
powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue; Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue; Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue; Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue; Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue" >nul 2>&1
call :LOG "6. Defender real-time protection on, auto-update policy set"
set /p UPD="6. Run Windows Update + Defender signature scan now? (needs internet) [y/N]: "
if /I "!UPD!"=="y" (
    sc config wuauserv start= auto >nul 2>&1
    net start wuauserv >nul 2>&1
    powershell -NoProfile -Command "Update-MpSignature -ErrorAction SilentlyContinue" >nul 2>&1
    UsoClient.exe StartInteractiveScan >nul 2>&1
    call :LOG "6. Defender signatures updated and Windows Update scan triggered"
)
pause
goto :MENU

:: ============================================================================
:S7  :: Built-in & Authorized Accounts (uses admins.txt / users.txt)
:: ============================================================================
call :LOG "7. Accounts: disabling Guest & auditing against admins.txt / users.txt"
net user Guest /active:no >nul 2>&1
call :LOG "7. Guest disabled"
echo.
echo   Current local accounts:
net user
echo.
echo   Administrators group:
net localgroup Administrators
echo.
set /p ADMOFF="7. Disable built-in Administrator? Only if an authorized admin exists and works. [y/N]: "
if /I "!ADMOFF!"=="y" (
    net user Administrator /active:no >nul 2>&1
    call :LOG "7. Built-in Administrator DISABLED"
) else (
    call :LOG "7. Built-in Administrator left enabled (manual review)"
)
setlocal disabledelayedexpansion
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$admFile = '%~dp0admins.txt'; $usrFile = '%~dp0users.txt'; " ^
    "$admins = if (Test-Path $admFile) { @(Get-Content $admFile | Where-Object { $_ -notmatch '^\s*(#|$)' } | ForEach-Object { $_.Trim() }) } else { @() }; " ^
    "$users  = if (Test-Path $usrFile) { @(Get-Content $usrFile | Where-Object { $_ -notmatch '^\s*(#|$)' } | ForEach-Object { $_.Trim() }) } else { @() }; " ^
    "if ($admins.Count -eq 0 -and $users.Count -eq 0) { Write-Host '[WARN] admins.txt and users.txt are empty - skipping automated user sync.' -ForegroundColor Yellow; exit }; " ^
    "$auth = $admins + $users + $env:USERNAME; " ^
    "$protected = @('Administrator','Guest','DefaultAccount','WDAGUtilityAccount'); " ^
    "$secPass = ConvertTo-SecureString 'Cyb3rP@triot!2026Sec' -AsPlainText -Force; " ^
    "foreach ($u in Get-LocalUser) { " ^
    "  if ($protected -contains $u.Name -or $u.Name -ieq $env:USERNAME) { continue }; " ^
    "  if ($auth -notcontains $u.Name) { " ^
    "    $ans = Read-Host \"[?] Unauthorized user '$($u.Name)' found. Delete user? [y/N]\"; " ^
    "    if ($ans -match '^[Yy]') { Remove-LocalUser -Name $u.Name -ErrorAction SilentlyContinue; Write-Host \"[+] Deleted $($u.Name)\" -ForegroundColor Green } " ^
    "  } else { " ^
    "    Enable-LocalUser -Name $u.Name -ErrorAction SilentlyContinue; " ^
    "    Set-LocalUser -Name $u.Name -PasswordNeverExpires $false -UserMayChangePassword $true -ErrorAction SilentlyContinue " ^
    "  } " ^
    "}; " ^
    "foreach ($expected in ($admins + $users)) { " ^
    "  if (-not (Get-LocalUser -Name $expected -ErrorAction SilentlyContinue)) { " ^
    "    $ans = Read-Host \"[?] Missing authorized user '$expected'. Create user? [Y/n]\"; " ^
    "    if ($ans -notmatch '^[Nn]') { New-LocalUser -Name $expected -Password $secPass -PasswordNeverExpires $false -UserMayChangePassword $true | Out-Null; Write-Host \"[+] Created $expected\" -ForegroundColor Green } " ^
    "  } " ^
    "}; " ^
    "foreach ($m in (Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue)) { " ^
    "  $n = $m.Name.Split('\')[-1]; if ($n -ieq 'Administrator' -or $n -ieq $env:USERNAME) { continue }; " ^
    "  if ($admins -notcontains $n) { " ^
    "    $ans = Read-Host \"[?] '$n' is in Administrators but not admins.txt. Remove from Administrators? [Y/n]\"; " ^
    "    if ($ans -notmatch '^[Nn]') { Remove-LocalGroupMember -Group 'Administrators' -Member $n -ErrorAction SilentlyContinue; Write-Host \"[+] Removed $n from Administrators\" -ForegroundColor Green } " ^
    "  } " ^
    "}; " ^
    "foreach ($a in $admins) { " ^
    "  $cur = @(Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue | ForEach-Object { $_.Name.Split('\')[-1] }); " ^
    "  if ($cur -notcontains $a -and (Get-LocalUser -Name $a -ErrorAction SilentlyContinue)) { " ^
    "    Add-LocalGroupMember -Group 'Administrators' -Member $a -ErrorAction SilentlyContinue; Write-Host \"[+] Added $a to Administrators\" -ForegroundColor Green " ^
    "  } " ^
    "}; " ^
    "$pwAns = Read-Host '[?] Set password (Cyb3rP@triot!2026Sec) for all authorized users except you? [Y/n]'; " ^
    "if ($pwAns -notmatch '^[Nn]') { " ^
    "  foreach ($t in ($admins + $users)) { if ($t -ine $env:USERNAME -and (Get-LocalUser -Name $t -ErrorAction SilentlyContinue)) { Set-LocalUser -Name $t -Password $secPass -ErrorAction SilentlyContinue; Write-Host \"[+] Password updated: $t\" -ForegroundColor Green } } " ^
    "}"
endlocal
call :LOG "7. Account audit complete"
pause
goto :MENU

:: ============================================================================
:S8  :: Media sweep
:: ============================================================================
call :LOG "8. Media: scanning C:\Users for prohibited files"
set "MEDLIST=%TEMP%\CP_media.txt"
break > "%MEDLIST%"
(for %%e in (%MEDIA_EXTS%) do @dir /s /b /a-d "C:\Users\%%e" 2>nul) | findstr /v /i "AppData" >> "%MEDLIST%"
for /f %%c in ('find /c /v "" ^< "%MEDLIST%"') do set MEDCNT=%%c
echo.
echo   Found !MEDCNT! media file^(s^). List saved to %MEDLIST%
type "%MEDLIST%"
echo.
if !MEDCNT! GTR 0 (
    set /p MEDDEL="8. Delete ALL of these? [y/N]: "
    if /I "!MEDDEL!"=="y" (
        for %%e in (%MEDIA_EXTS%) do (
            for /f "delims=" %%f in ('dir /s /b /a-d "C:\Users\%%e" 2^>nul ^| findstr /v /i "AppData"') do (
                del /f /q "%%f" >nul 2>&1 && echo deleted: %%f >> "%REPORT%"
            )
        )
        call :LOG "8. All media files deleted"
    ) else (
        call :LOG "8. Media kept - review the list manually"
    )
) else (
    call :LOG "8. No prohibited media files found"
)
pause
goto :MENU

:: ============================================================================
:S9  :: Review report
:: ============================================================================
call :LOG "9. Building review report (users, persistence, shares, ports, programs)"
echo. >> "%REPORT%"
echo ===== REVIEW REPORT: LOCAL USERS (compare to users.txt/admins.txt) ===== >> "%REPORT%"
echo --- all local users --- >> "%REPORT%"
for /f "skip=2 tokens=*" %%a in ('net user ^| findstr /v /c:"command completed"') do (
    set "line=%%a"
    if not "!line:~0,1!"=="-" echo   !line! >> "%REPORT%"
)
echo. >> "%REPORT%"
echo --- Administrators group --- >> "%REPORT%"
net localgroup Administrators | findstr /v /b /i /c:"Alias" /c:"Comment" /c:"Members" /c:"The command" /c:"-" >> "%REPORT%"
echo. >> "%REPORT%"
echo ===== STARTUP PERSISTENCE (Run keys + Startup folders) ===== >> "%REPORT%"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" >> "%REPORT%" 2>nul
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" >> "%REPORT%" 2>nul
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" >> "%REPORT%" 2>nul
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" >> "%REPORT%" 2>nul
dir /s /b "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" >> "%REPORT%" 2>nul
dir /s /b "C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" >> "%REPORT%" 2>nul
echo. >> "%REPORT%"
echo ===== SCHEDULED TASKS (look for tasks you do not recognize) ===== >> "%REPORT%"
schtasks /query /fo LIST >> "%REPORT%" 2>nul
echo. >> "%REPORT%"
echo ===== NETWORK SHARES (look for non-default shares) ===== >> "%REPORT%"
net share >> "%REPORT%" 2>nul
echo. >> "%REPORT%"
echo ===== LISTENING PORTS (investigate anything unexpected) ===== >> "%REPORT%"
netstat -ano | findstr LISTENING >> "%REPORT%" 2>nul
echo. >> "%REPORT%"
echo ===== HOSTS FILE ENTRIES (non-comment, non-localhost) ===== >> "%REPORT%"
type "C:\Windows\System32\drivers\etc\hosts" | findstr /v /b "#" | findstr /v /i "localhost" >> "%REPORT%"
echo. >> "%REPORT%"
echo ===== INSTALLED PROGRAMS (uninstall prohibited software by hand) ===== >> "%REPORT%"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName >> "%REPORT%" 2>nul
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName >> "%REPORT%" 2>nul
echo. >> "%REPORT%"
echo ===== AUTORUNS FROM OTHER LOCATIONS ===== >> "%REPORT%"
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" >> "%REPORT%" 2>nul
echo. >> "%REPORT%"
echo ===== MANUAL CHECKLIST (do these by hand) ===== >> "%REPORT%"
echo   [ ] Remove unauthorized users:        net user NAME /delete >> "%REPORT%"
echo   [ ] Remove unauthorized admins:       net localgroup Administrators NAME /delete >> "%REPORT%"
echo   [ ] Change all authorized passwords to a strong unique one >> "%REPORT%"
echo   [ ] Uninstall prohibited programs (games, torrents, hackers tools) >> "%REPORT%"
echo   [ ] Check Desktop/Documents for README violations >> "%REPORT%"
echo   [ ] Verify required services are STILL RUNNING (services.msc) >> "%REPORT%"
echo   [ ] Set screensaver: 10 min, resume with password >> "%REPORT%"
ipconfig /flushdns >nul 2>&1
call :LOG "9. Report complete: %REPORT%"
start notepad "%REPORT%"
pause
goto :MENU

:: ------------------------------- helpers -----------------------------------
:LOG
echo [*] %~1
echo [%TIME%] %~1 >> "%REPORT%"
goto :eof

:CRIT
:: exit code 0 if %1 found (uncommented) in critical_services.txt
type "%CRITFILE%" 2>nul | findstr /r /v /c:"^ *#" | findstr /i /c:"%~1" >nul 2>&1
if %errorlevel% equ 0 (exit /b 0) else (exit /b 1)
