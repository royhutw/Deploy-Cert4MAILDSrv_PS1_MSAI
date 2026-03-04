param(
    [Parameter(Mandatory=$true)]
    [string]$NewCertPath,

    [Parameter(Mandatory=$true)]
    [string]$OldCertPath,

    [Parameter(Mandatory=$true)]
    [string]$CN
)

# Error codes
$ERR_OK              = 0
$ERR_NO_UPDATE       = 10
$ERR_NO_UPDATE_SAMETHUMBPRINT = 11
$ERR_NO_UPDATE_NotAfterDate  = 12
$ERR_CN_MISMATCH     = 20

# --- 防呆：確認 Validate-CerCertificate.ps1 存在 ---
$validator = ".\Validate-CerCertificate.ps1"

if (-not (Test-Path $validator)) {
    exit $ERR_NO_UPDATE
}

# --- Resolve full paths ---
try {
    $NewFull = (Resolve-Path $NewCertPath).ProviderPath
}
catch {
    exit $ERR_NO_UPDATE
}

try {
    $OldFull = (Resolve-Path $OldCertPath).ProviderPath
}
catch {
    $OldFull = $null
}

# --- Load new certificate ---
try {
    $newCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($NewFull)
}
catch {
    exit $ERR_NO_UPDATE
}

# --- Load old certificate ---
try {
    $oldCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($OldFull)
}
catch {
    exit $ERR_NO_UPDATE
}

# --- Check CN of old certificate ---
$oldSubject = $oldCert.Subject
$oldCN = ($oldSubject -split ",") |
         Where-Object { $_ -like "CN=*" } |
         ForEach-Object { $_.Substring(3) }

if ($oldCN -ne $CN) {
    exit $ERR_CN_MISMATCH
}

# --- 呼叫 validator 檢查新憑證有效性 ---
try {
    $validateResult = & $validator -Path $NewFull -CN $CN
    $exitCode = $LASTEXITCODE
}
catch {
    exit $ERR_NO_UPDATE
}

if ($exitCode -ne 0) {
    exit $exitCode
}

# --- Load old certificate (if exists) ---
if ($OldFull -ne $null) {
    try {
        $oldCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($OldFull)
    }
    catch {
        exit $ERR_OK
    }

    # --- Compare thumbprints ---
    if ($newCert.Thumbprint -eq $oldCert.Thumbprint) {
        exit $ERR_NO_UPDATE_SAMETHUMBPRINT
    }

    # --- Compare NotAfter (截止日期) ---
    if ($newCert.NotAfter -le $oldCert.NotAfter) {
        exit $ERR_NO_UPDATE_NotAfterDate
    }
}

# --- New certificate is valid and newer ---
exit $ERR_OK
