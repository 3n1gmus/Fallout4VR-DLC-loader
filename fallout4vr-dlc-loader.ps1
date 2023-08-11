# Read settings from the CSV file
$mypath = $MyInvocation.MyCommand.Path
$Settings_File = $mypath + "\settings.csv"
$settings = Import-Csv -Path $Settings_File -Header Setting,Value

# Get specific settings
$fallout4DataFolder = $settings | Where-Object { $_.Setting -eq "Fallout4DataFolder" } | Select-Object -ExpandProperty Value
$fallout4VRDataFolder = $settings | Where-Object { $_.Setting -eq "Fallout4VRDataFolder" } | Select-Object -ExpandProperty Value
$backupDestination = $settings | Where-Object { $_.Setting -eq "BackupDestination" } | Select-Object -ExpandProperty Value
$backupFilename = $settings | Where-Object { $_.Setting -eq "BackupFilename" } | Select-Object -ExpandProperty Value

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
$backupFilePath = Join-Path -Path $backupDestination -ChildPath $backupFilename

# Check if the backup zip file already exists
if (Test-Path $backupFilePath) {
    Write-Host "Backup file already exists: $backupFilePath"
} else {
    # Create a backup zip file
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($fallout4VRDataFolder, $backupFilePath)
    Write-Host "Backup created: $backupFilePath"
}

if (Test-Path $backupFilePath) {
    # Write-Host "Backup complete: $backupFilePath"

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

    Write-Host "Fallout 4 Data copied to Fallout 4 VR Data."
}
else {Write-Host "Backup failed. Aborting copy."}