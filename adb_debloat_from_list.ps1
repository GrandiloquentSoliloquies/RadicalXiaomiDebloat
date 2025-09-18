# ============================================================================
#            PowerShell ADB Utility Script (GitHub Version 1.0)
# ============================================================================
# This script can either uninstall or install apps on an Android device via ADB.
# It is designed to be portable and user-friendly.
# ============================================================================

# --- CONFIGURATION (File paths are now relative to the script's location) ---
$UninstallListFile = Join-Path -Path $PSScriptRoot -ChildPath "uninstall_list.txt"
$InstallListFile = Join-Path -Path $PSScriptRoot -ChildPath "install_list.txt" # Renamed
$ResultsFile = Join-Path -Path $PSScriptRoot -ChildPath "results.txt"

# --- Delay Configuration ---
$DelayOnSuccess = 3
$DelayOnFailure = 1
$DelayOnInstall = 5

# ============================================================================
#                              HELPER FUNCTIONS
# ============================================================================

# --- Function to prompt the user for a valid adb.exe path ---
function Get-AdbPath {
    while ($true) {
        $inputPath = Read-Host "Please enter the full path to your adb.exe file (e.g., C:\platform-tools\adb.exe)"
        # Remove quotes if user pastes a quoted path
        $cleanPath = $inputPath.Trim('"')

        if ((Test-Path $cleanPath) -and ((Split-Path $cleanPath -Leaf) -eq "adb.exe")) {
            Write-Host "ADB path set successfully: $cleanPath" -ForegroundColor Green
            return $cleanPath
        } else {
            Write-Host "Error: Path is invalid or does not point to adb.exe. Please try again." -ForegroundColor Red
        }
    }
}

# --- This entire section of functions remains unchanged ---
function Start-RemovalProcess {
    Write-Host "Starting ADB Uninstallation Process..." -ForegroundColor Green
    $PackageRegex = "([a-zA-Z0-9._-]+)$"
    if (-not (Test-Path $UninstallListFile)) {
        Write-Host "ERROR: 'uninstall_list.txt' not found in the script directory." -ForegroundColor Red
        return
    }
    Get-Content $UninstallListFile | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        Write-Host "`n=========================================================================="
        Write-Host "Processing line: '$line'"
        Add-Content -Path $ResultsFile -Value "`r`n[INFO] Removing: '$line'"
        $packageName = $null
        if ($line -match $PackageRegex) { $packageName = $Matches[1] }
        if ($packageName) {
            $uninstallCommand = "& `"$AdbPath`" shell pm uninstall --user 0 $packageName"
            Write-Host "Executing command for '$packageName'..."
            Add-Content -Path $ResultsFile -Value "[EXEC] $uninstallCommand"
            $result = ""
            try {
                $result = Invoke-Expression -Command $uninstallCommand 2>&1 | Out-String
                Write-Host "Result: $($result.Trim())" -ForegroundColor Cyan
            } catch {
                $result = "[CRITICAL ERROR] $($_.Exception.Message)"
                Write-Host $result -ForegroundColor Red
            }
            Add-Content -Path $ResultsFile -Value $result.Trim()
            if ($result -like "*Failure [-1000]*") {
                Write-Host "Uninstall failed. Attempting to disable the package as a fallback..." -ForegroundColor Yellow
                Add-Content -Path $ResultsFile -Value "[INFO] Uninstall failed with error -1000. Attempting fallback: disable-user."
                $disableCommand = "& `"$AdbPath`" shell pm disable-user --user 0 $packageName"
                Add-Content -Path $ResultsFile -Value "[EXEC] $disableCommand"
                $fallbackResult = ""
                try {
                    $fallbackResult = Invoke-Expression -Command $disableCommand 2>&1 | Out-String
                    Write-Host "Fallback Result: $($fallbackResult.Trim())" -ForegroundColor DarkYellow
                } catch {
                    $fallbackResult = "[CRITICAL ERROR] Fallback failed: $($_.Exception.Message)"
                    Write-Host $fallbackResult -ForegroundColor Red
                }
                Add-Content -Path $ResultsFile -Value $fallbackResult.Trim()
            }
            $currentDelay = 0
            if ($result -like "*Success*" -or $fallbackResult -like "*new state: disabled-user*") {
                $currentDelay = $DelayOnSuccess
            } elseif ($result -like "*Failure*not installed*") {
                $currentDelay = $DelayOnFailure
            } else {
                $currentDelay = $DelayOnSuccess
            }
            Write-Host "Pausing for $currentDelay second(s)..."
            Start-Sleep -Seconds $currentDelay
        } else {
            Write-Host "[ERROR] Could not find a package name in '$line'. Skipping." -ForegroundColor Yellow
            Add-Content -Path $ResultsFile -Value "[ERROR] Could not find a package name in '$line'. Skipping."
        }
    }
}
function Invoke-AdbInstall {
    param([string]$ApkFileFullPath)
    Write-Host "`n--- Attempting to install: $(Split-Path $ApkFileFullPath -Leaf) ---"
    $CommandToRun = "& `"$AdbPath`" install -r `"$ApkFileFullPath`""
    Add-Content -Path $ResultsFile -Value "[EXEC] adb install -r `"$ApkFileFullPath`""
    $result = ""
    try {
        $result = Invoke-Expression -Command $CommandToRun 2>&1 | Out-String
        Write-Host "Result: $($result.Trim())" -ForegroundColor Cyan
    } catch {
        $result = "[CRITICAL ERROR] $($_.Exception.Message)"
        Write-Host $result -ForegroundColor Red
    }
    Add-Content -Path $ResultsFile -Value $result.Trim()
    Write-Host "Pausing for $DelayOnInstall seconds..."
    Start-Sleep -Seconds $DelayOnInstall
}
function Start-InstallationProcess {
    Write-Host "Starting ADB Installation Process..." -ForegroundColor Green
    if (-not (Test-Path $InstallListFile)) {
        Write-Host "ERROR: 'install_list.txt' not found in the script directory." -ForegroundColor Red
        return
    }
    Get-Content $InstallListFile | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        Write-Host "`n=========================================================================="
        Write-Host "Processing line: '$line'"
        Add-Content -Path $ResultsFile -Value "`r`n[INFO] Processing install list item: '$line'"
        $itemPath = $line.Trim('"')
        if (-not ([System.IO.Path]::IsPathRooted($itemPath))) {
            $itemPath = Join-Path -Path $PSScriptRoot -ChildPath $itemPath
        }
        if (-not (Test-Path $itemPath)) {
            Write-Host "[ERROR] Path not found: '$itemPath'. Skipping." -ForegroundColor Red
            Add-Content -Path $ResultsFile -Value "[ERROR] Path not found: '$itemPath'. Skipping."
            return
        }
        $item = Get-Item $itemPath
        if ($item.PSIsContainer) {
            Write-Host "Directory detected. Scanning for APKs in '$($item.FullName)'..." -ForegroundColor Yellow
            Add-Content -Path $ResultsFile -Value "[INFO] Directory detected. Scanning for APKs."
            $apkFiles = Get-ChildItem -Path $item.FullName -Filter "*.apk" -Recurse
            if ($apkFiles) {
                Write-Host "Found $($apkFiles.Count) APK(s). Starting installation of all found files."
                foreach ($apk in $apkFiles) { Invoke-AdbInstall -ApkFileFullPath $apk.FullName }
            } else {
                Write-Host "No APK files found in '$($item.FullName)'."
                Add-Content -Path $ResultsFile -Value "[INFO] No APK files found in directory."
            }
        } else {
            if ($item.Name -like "*.apk") {
                Invoke-AdbInstall -ApkFileFullPath $item.FullName
            } else {
                Write-Host "[WARNING] File is not an APK: '$($item.Name)'. Skipping." -ForegroundColor Yellow
                Add-Content -Path $ResultsFile -Value "[WARNING] File is not an APK: '$($item.Name)'. Skipping."
            }
        }
    }
}

# ============================================================================
#                              MAIN SCRIPT LOGIC
# ============================================================================
Clear-Host
Add-Content -Path $ResultsFile -Value "`r`n--------------------------------------------------------------------------`r`n[INFO] --- Script Session Started on $(Get-Date) ---"

# --- Get ADB Path from User ---
$AdbPath = Get-AdbPath

# --- Check for ADB Device ---
Write-Host "Checking for connected ADB devices..."
$devices = & $AdbPath devices
if ($devices -notlike "*device*`n*device") {
    Write-Host "Error: No ADB device found. Please connect your device, enable USB debugging, and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit."
    exit
}
Write-Host "Device found. Proceeding..." -ForegroundColor Green


# --- Mode Selection Logic ---
if (Test-Path $InstallListFile) {
    Write-Host "Installation file ('install_list.txt') found. Please choose an operation mode:" -ForegroundColor Yellow
    Write-Host "1: Removal Mode (uses uninstall_list.txt)"
    Write-Host "2: Installation Mode (uses install_list.txt)"
    
    $choice = ""
    while ($choice -ne "1" -and $choice -ne "2") {
        $choice = Read-Host "Enter your choice (1 or 2)"
    }
    
    switch ($choice) {
        "1" { Start-RemovalProcess }
        "2" { Start-InstallationProcess }
    }
} else {
    Write-Host "'install_list.txt' not found. Running in default Removal Mode (uses 'uninstall_list.txt')." -ForegroundColor Cyan
    Start-RemovalProcess
}

Write-Host "`n=========================================================================="
Write-Host "`nAll tasks are complete." -ForegroundColor Green
Read-Host "Press Enter to close this window."