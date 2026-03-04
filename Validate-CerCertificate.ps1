param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [Parameter(Mandatory=$true)]
    [string]$CN
)

# Error codes
$ERR_OK              = 0
$ERR_LOAD_FAILED     = 10
$ERR_EXPIRED         = 20
$ERR_NOT_YET_VALID   = 21
$ERR_CHAIN_INVALID   = 30
$ERR_REVOKED         = 40

# Resolve full path (PS 4.0 必須這樣做)
try {
    $FullPath = (Resolve-Path $Path).ProviderPath
}
catch {
    exit $ERR_LOAD_FAILED
}

# Load certificate
try {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($FullPath)
}
catch {
    exit $ERR_LOAD_FAILED
}

# Extract CN (PS 4.0 相容寫法)
$subject = $cert.Subject
$certCN = ($subject -split ",") |
          Where-Object { $_ -like "CN=*" } |
          ForEach-Object { $_.Substring(3) }

if ($certCN -ne $CN) {
    exit $ERR_LOAD_FAILED
}

# Check validity period
$now = Get-Date

if ($now -lt $cert.NotBefore) {
    exit $ERR_NOT_YET_VALID
}

if ($now -gt $cert.NotAfter) {
    exit $ERR_EXPIRED
}

# Build chain with revocation check
$chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$chain.ChainPolicy.RevocationMode = "Online"
$chain.ChainPolicy.RevocationFlag = "EntireChain"
$chain.ChainPolicy.UrlRetrievalTimeout = New-TimeSpan -Seconds 10

$chainBuilt = $chain.Build($cert)

if (-not $chainBuilt) {

    foreach ($status in $chain.ChainStatus) {

        if ($status.Status -eq "Revoked") {
            exit $ERR_REVOKED
        }
    }

    exit $ERR_CHAIN_INVALID
}

exit $ERR_OK