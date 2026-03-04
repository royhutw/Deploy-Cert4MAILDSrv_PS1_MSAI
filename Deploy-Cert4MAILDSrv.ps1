param(
    [Parameter(Mandatory=$true)]
    [string]$NewCertPath,

    [Parameter(Mandatory=$true)]
    [string]$OldCertPath,

    [Parameter(Mandatory=$true)]
    [string]$NewCACertPath,

    [Parameter(Mandatory=$true)]
    [string]$OldCACertPath,

    [Parameter(Mandatory=$true)]
    [string]$NewPrivKeyPath,

    [Parameter(Mandatory=$true)]
    [string]$OldPrivKeyPath,
    
    [Parameter(Mandatory=$true)]
    [string]$CN,

    [string]$LogPath = ".\deploy_cert.log"
)

# Error codes from Compare script
$ERR_OK        = 0
$ERR_NO_UPDATE = 10

# Compare script path
$compareScript = ".\Compare-CerCertificates.ps1"

# --- Log function ---
function Write-Log {
    param([string]$Message)

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogPath -Value "$timestamp`t$Message"
}

Write-Log "=== Deployment process started ==="

# --- 防呆：確認 Compare-CerCertificates.ps1 存在 ---
if (-not (Test-Path $compareScript)) {
    Write-Log "ERROR: Compare-CerCertificates.ps1 not found."
    exit 1
}

# --- 呼叫 Compare-CerCertificates.ps1 ---
try {
    $compareResult = & $compareScript -NewCertPath $NewCertPath -OldCertPath $OldCertPath -CN $CN
    $exitCode = $LASTEXITCODE
}
catch {
    Write-Log "ERROR: Failed to execute Compare-CerCertificates.ps1"
    exit 1
}

# --- 若非 0 → 不部署 ---
if ($exitCode -ne $ERR_OK) {

    if ($exitCode -eq $ERR_NO_UPDATE) {
        Write-Log "INFO: No update required. Certificate unchanged."
        exit 0
    }

    Write-Log "ERROR: New certificate invalid. Compare returned error code: $exitCode"
    exit $exitCode
}

Write-Log "INFO: New certificate is valid and newer. Starting deployment..."

# --- Resolve paths ---
try {
    $NewFull = (Resolve-Path $NewCertPath).ProviderPath
    $OldFull = (Resolve-Path $OldCertPath).ProviderPath
    $NewCACertFull = (Resolve-Path $NewCACertPath).ProviderPath
    $OldCACertFull = (Resolve-Path $OldCACertPath).ProviderPath
    $NewPrivKeyFull = (Resolve-Path $NewPrivKeyPath).ProviderPath
    $OldPrivKeyFull = (Resolve-Path $OldPrivKeyPath).ProviderPath
}
catch {
    Write-Log "ERROR: Path resolution failed."
    exit 1
}

# --- 備份舊憑證, 舊CACert & 舊私鑰 ---
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$backupPath = "$OldFull.$timestamp.bak"

try {
    Copy-Item -Path $OldFull -Destination $backupPath -Force
    Write-Log "INFO: Old certificate backed up to: $backupPath"
}
catch {
    Write-Log "ERROR: Failed to backup old certificate."
    exit 1
}

$backupPathCACert = "$OldCACertFull.$timestamp.bak"
try {
    Copy-Item -Path $OldCACertFull -Destination $backupPathCACert -Force
    Write-Log "INFO: Old CACert backed up to: $backupPathCACert"
}
catch {
    Write-Log "ERROR: Failed to backup old CACert."
    exit 1
}

$backupPathPrivKey = "$OldPrivKeyFull.$timestamp.bak"
try {
    Copy-Item -Path $OldPrivKeyFull -Destination $backupPathPrivKey -Force
    Write-Log "INFO: Old PrivKey backed up to: $backupPathPrivKey"
}
catch {
    Write-Log "ERROR: Failed to backup old PrivKey."
    exit 1
}

# --- 覆蓋舊憑證（部署新憑證, 新CACert & 新私鑰） ---
try {
    Copy-Item -Path $NewFull -Destination $OldFull -Force
    Write-Log "INFO: New certificate deployed to: $OldFull"
}
catch {
    Write-Log "ERROR: Failed to deploy new certificate."
    exit 1
}

try {
    Copy-Item -Path $NewCACertFull -Destination $OldCACertFull -Force
    Write-Log "INFO: New CACert deployed to: $OldCACertFull"
}
catch {
    Write-Log "ERROR: Failed to deploy new CACert."
    exit 1
}

try {
    Copy-Item -Path $NewPrivKeyFull -Destination $OldPrivKeyFull -Force
    Write-Log "INFO: New PrivKey deployed to: $OldPrivKeyFull"
}
catch {
    Write-Log "ERROR: Failed to deploy new PrivKey."
    exit 1
}

Write-Log "=== Deployment completed successfully ==="
exit 0