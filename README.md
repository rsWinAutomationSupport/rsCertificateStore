rsSSL
=====
Originated at: https://github.com/PowerShellOrg/DSC/tree/master/Resources/StackExchangeResources/DSCResources/StackExchange_CertificateStore

Used for SSL installation. PFX password support added by RS.
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
```
