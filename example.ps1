$newcertpath = "D:\source\repos\deploy-cert_ps1_msai\SSL\foo.bar-crt.pem"
$oldcertpath = "D:\source\repos\deploy-cert_ps1_msai\SSL\cert.pem"
$newcacertpath = "D:\source\repos\deploy-cert_ps1_msai\SSL\foo.bar-chain-only.pem"
$oldcacertpath = "D:\source\repos\deploy-cert_ps1_msai\SSL\cacert.pem"
$newprivkeypath = "D:\source\repos\deploy-cert_ps1_msai\SSL\foo.bar-key.pem"
$oldprivkeypath = "D:\source\repos\deploy-cert_ps1_msai\SSL\privkey.pem"
$cn = "foo.bar"

& .\Deploy-Cert4MAILDSrv.ps1 -newcertpath $newcertpath -oldcertpath $oldcertpath -newcacertpath $newcacertpath -oldcacertpath $oldcacertpath -newprivkeypath $newprivkeypath -oldprivkeypath $oldprivkeypath -cn $cn