param(
    [string]$LogPath = ".\restart_maildsrv.log"
)

# --- Log function ---
function Write-Log {
    param([string]$Message)

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogPath -Value "$timestamp`t$Message"
}

# --- 重啟 MAILDSrv 服務 ---
try {
    Restart-Service -Name "MAILDSrv" -Force
    Write-Log "INFO: Service 'MAILDSrv' restarted successfully."
}
catch {
    Write-Log "ERROR: Failed to restart service 'MAILDSrv'."
    exit 1
}