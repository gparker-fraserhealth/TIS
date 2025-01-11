# Ensure execution policy allows script execution
# Set-ExecutionPolicy RemoteSigned -Scope Process

# Import server list and output file from command-line arguments
param(
    [string]$ServerListFile,
    [string]$OutputCsvFile
)

# Log file name
$LogFile = "log.log"

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$Timestamp [$Type] $Message" | Out-File -Append -FilePath $LogFile
}

# Function to collect server statistics
function Get-ServerStats {
    param(
        [string]$ServerName,
        [string]$Username,
        [string]$Password
    )
    try {
        $Creds = New-Object System.Management.Automation.PSCredential($Username, (ConvertTo-SecureString $Password -AsPlainText -Force))

        Invoke-Command -ComputerName $ServerName -Credential $Creds -ScriptBlock {
            $RAM = Get-WmiObject -Class Win32_OperatingSystem | Select-Object @{Name='Used';Expression={[math]::Round($_.TotalVisibleMemorySize - $_.FreePhysicalMemory,2)}}, @{Name='Total';Expression={[math]::Round($_.TotalVisibleMemorySize,2)}}
            $Disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, @{Name='Used';Expression={[math]::Round($_.Size - $_.FreeSpace,2)}}, @{Name='Total';Expression={[math]::Round($_.Size,2)}}
            $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            [PSCustomObject]@{
                ServerName = $env:COMPUTERNAME
                Date = $Date
                RAMUsed = $RAM.Used
                RAMTotal = $RAM.Total
                DiskStats = $Disks
            }
        }
    } catch {
        Write-Log -Message "Error collecting stats from $ServerName: $_" -Type "ERROR"
        $null
    }
}

# Ensure necessary parameters are provided
if (-not (Test-Path $ServerListFile)) {
    Write-Log -Message "Server list file not found: $ServerListFile" -Type "ERROR"
    exit
}

if (-not $OutputCsvFile) {
    Write-Log -Message "Output CSV file not specified." -Type "ERROR"
    exit
}

# Read server list
$Servers = Get-Content -Path $ServerListFile
$Username = "your-username"
$Password = "your-password"

# Initialize CSV
if (-not (Test-Path $OutputCsvFile)) {
    "ServerName,Date,RAMUsed,RAMTotal,DiskDrive,DiskUsed,DiskTotal" | Out-File -FilePath $OutputCsvFile
}

# Start monitoring
while ($true) {
    $CurrentTime = Get-Date

    if ($CurrentTime.Hour -ge 10 -and $CurrentTime.Hour -lt 18) {
        Write-Log -Message "Collecting stats at $CurrentTime."

        foreach ($Server in $Servers) {
            $Stats = Get-ServerStats -ServerName $Server -Username $Username -Password $Password

            if ($Stats -ne $null) {
                foreach ($Disk in $Stats.DiskStats) {
                    "$($Stats.ServerName),$($Stats.Date),$($Stats.RAMUsed),$($Stats.RAMTotal),$($Disk.DeviceID),$($Disk.Used),$($Disk.Total)" |
                        Out-File -Append -FilePath $OutputCsvFile
                }
            }
        }
    }

    Write-Log -Message "Sleeping for 15 minutes."
    Start-Sleep -Seconds (15 * 60)
}
