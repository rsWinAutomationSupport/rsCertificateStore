rsSSL
=====
Originated at: https://github.com/PowerShellOrg/DSC/tree/master/Resources/StackExchangeResources/DSCResources/StackExchange_CertificateStore

Used for SSL installation. PFX password support added by RS.
Updated for Secure Password (PSCredential)
Tests added for Thumbprint-based management checks
```PoSh
rsCertificateStore cert_1
{
  Ensure = "Present"
  Name = "rackspacedevops.com"
  Path = "C:\DevOps\DDI_rsConfigs\certificates\rackspacedevops.com.2015.pfx"
  Location = "LocalMachine"
  Store = "WebHosting"
  Password = "rack"
}

rsCertificateStore cert_2
{
  Ensure = "Present"
  Name = "devops_selfsigned.net"
  Path = "C:\DevOps\DDI_rsConfigs\certificates\rackspacedevops.net.2015.pfx"
  Location = "LocalMachine"
  Store = @("My", "Root")
  SecurePassword = $Credentials."devops_selfsigned.net"
}
```
