# <--- Functions --->
function Update-Fallout4INI {
    param (
        [string]$iniFilePath
    )

    # Check if the INI file exists
    if (-not (Test-Path -Path $iniFilePath)) {
        Write-Host "Error: Fallout4.ini file not found at $iniFilePath"
        return
    }

    # Create a backup if it doesn't exist
    $backupFilePath = [System.IO.Path]::ChangeExtension($iniFilePath, "bak")
    if (-not (Test-Path -Path $backupFilePath)) {
        Copy-Item -Path $iniFilePath -Destination $backupFilePath
        Write-Host "Backup created: $backupFilePath"
    }

    # Configuration line to add
    $configLine = "bInvalidateOlderFiles=1"

    # Read the existing contents of the INI file
    $iniContents = Get-Content -Path $iniFilePath

    # Update the line with "sResourceDataDirsFinal="
    $updatedContents = foreach ($line in $iniContents) {
        if ($line -match "^\s*sResourceDataDirsFinal=") {
            $line -replace "=.*", "=$configLine"
        } else {
            $line
        }
    }

    # Write the updated contents back to the INI file
    $updatedContents | Set-Content -Path $iniFilePath

    Write-Host "Fallout4.ini updated with configuration line."
}

function Copy-DLCList {
    $userProfile = [Environment]::GetFolderPath('UserProfile')
    $fallout4DLCListPath = Join-Path -Path $userProfile -ChildPath 'AppData\Local\Fallout4\DLCList.txt'
    $fallout4VRDLCListPath = Join-Path -Path $userProfile -ChildPath 'AppData\Local\Fallout4vr\DLCList.txt'

    # Check if the Fallout 4 DLCList.txt exists
    if (-not (Test-Path -Path $fallout4DLCListPath)) {
        Write-Host "Error: Fallout 4 DLCList.txt not found at $fallout4DLCListPath"
        return
    }

    # Create the Fallout 4 VR folder if it doesn't exist
    if (-not (Test-Path -Path $fallout4VRDLCListPath)) {
        New-Item -Path (Split-Path $fallout4VRDLCListPath) -ItemType Directory -Force
    }

    # Copy the DLCList.txt from Fallout 4 to Fallout 4 VR
    Copy-Item -Path $fallout4DLCListPath -Destination $fallout4VRDLCListPath -Force

    Write-Host "DLCList.txt copied from Fallout 4 to Fallout 4 VR."
}

# <--- Script Start --->

# Read settings from the CSV file
$mypath = $MyInvocation.MyCommand.Path
$Settings_File = $mypath + "\settings.csv"
$settings = Import-Csv -Path $Settings_File -Header Setting,Value

# Get specific settings
$fallout4Folder = $settings | Where-Object { $_.Setting -eq "Fallout4Folder" } | Select-Object -ExpandProperty Value
$fallout4VRFolder = $settings | Where-Object { $_.Setting -eq "Fallout4VRFolder" } | Select-Object -ExpandProperty Value
$backupFilename = $settings | Where-Object { $_.Setting -eq "BackupFilename" } | Select-Object -ExpandProperty Value

# Update Data folder location based on install location.
$fallout4DataFolder = $fallout4Folder + "\data"
$fallout4VRDataFolder = $fallout4VRFolder + "\data"

# Check if Fallout 4 data folder exists
if (-not (Test-Path -Path $fallout4DataFolder)) {
    Write-Host "Error: Fallout 4 data folder not found at $fallout4DataFolder"
    exit
}

# Check if Fallout 4 VR data folder exists
if (-not (Test-Path -Path $fallout4VRDataFolder)) {
    Write-Host "Error: Fallout 4 VR data folder not found at $fallout4VRDataFolder"
    exit
}

# Destination path for the backup zip file
$backupFilePath = Join-Path -Path $fallout4VRFolder -ChildPath $backupFilename

# INI file location
$INI_Path = $fallout4VRFolder + "\Fallout4.ini"

# Check if the backup zip file already exists
if (Test-Path $backupFilePath) {
    Write-Host "Backup file already exists: $backupFilePath"
} else {
    # Create a backup zip file
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($fallout4VRDataFolder, $backupFilePath)
    Write-Host "Backup created: $backupFilePath"
}

# Call the function to copy DLCList.txt
Copy-DLCList

if (Test-Path $backupFilePath) {
    # Copy Fallout 4 data to Fallout 4 VR data
    $filesToCopy = Get-ChildItem -Path $fallout4DataFolder -File -Recurse
    $filesToCopy | ForEach-Object {
        $destinationPath = Join-Path -Path $fallout4VRDataFolder -ChildPath $_.FullName.Substring($fallout4DataFolder.Length)
        if (-not (Test-Path -Path $destinationPath)) {
            Copy-Item -Path $_.FullName -Destination $destinationPath -Force
            Write-Host "Copied: $($_.FullName)"
        } else {
            Write-Host "Skipped (already exists): $($_.FullName)"
        }
    }
    # Call the function with the path to your Fallout4.ini file
    Update-Fallout4INI -iniFilePath $INI_Path

    Write-Host "Fallout 4 Data copied to Fallout 4 VR Data."
}
else {Write-Host "Backup failed. Aborting copy."}