function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    [ValidateSet('LocalMachine','CurrentUser')]
    [string]$Location = 'LocalMachine',
    [string]$Store = 'My',
    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',
    [string]$Password
    )
    
    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Ensure = 'Present'

    if (Test-TargetResource @PSBoundParameters)
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    $Configuration = @{
        Name = $Name
        Path = $Path
        Location = $Location
        Store = $Store
        Ensure = $Ensure
    }

    return $Configuration
}

function Set-TargetResource
{
    param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    [ValidateSet('LocalMachine','CurrentUser')]
    [string]$Location = 'LocalMachine',
    [string]$Store = 'My',
    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',
    [string]$Password
    )

    $CertificateBaseLocation = "cert:\$Location\$Store"
    
    if ($Ensure -like 'Present')
    {        
        $SecurePassword = ConvertTo-SecureString -string $Password -AsPlainText -Force
        Write-Verbose "Adding $path to $CertificateBaseLocation."
        Import-PfxCertificate -CertStoreLocation $CertificateBaseLocation -FilePath $Path -Password $SecurePassword
    }
    else
    {
        if ([bool](Get-childitem -Path $CertificateBaseLocation | ? thumbprint -eq $thumbprint))
        {
            $CertificatePath = (Get-childitem -Path $CertificateBaseLocation | ? thumbprint -eq $thumbprint).PSPath
        }else{
            $CertificatePath = Join-path $CertificateBaseLocation $Name
        }
        Write-Verbose "Removing Certificate $Name."
        dir $CertificatePath | Remove-Item -Force -Confirm:$false
    }
}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    [ValidateSet('LocalMachine','CurrentUser')]
    [string]$Location = 'LocalMachine',
    [string]$Store = 'My',
    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',
    [string]$Password
    )

    $IsValid = $false
    $CertificateBaseLocation = "cert:\$Location\$Store"
    if(Test-Path $Path)
    {
        Write-Verbose "Filepath test is good. Grabbing PFX thumbprint."
        $securepass = ConvertTo-SecureString -String $Password -Force –AsPlainText
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $certificate.Import($Path, $securepass, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet)
        $thumbprint = $certificate.thumbprint
        $pathGood = $true
    }else{
        
    }
    
    if (($Ensure -eq 'Present') -and ($pathGood))
    {
        Write-Verbose "Checking for $thumbprint thumbprint in the $location store under $store."
        if ([bool](Get-childitem -Path $CertificateBaseLocation | ? thumbprint -eq $thumbprint))
        {
            Write-Verbose "Found a matching certificate in Certificate Store $store"
            $IsValid = $true
        }else{
            Write-Verbose "Unable to find a matching certficate in Certificate Store $store"
        }
    }
    elseif ($Ensure -eq "Present")
    {
        Write-Verbose "Ensure is Present, but the filepath test is bad. Unable to grab PFX thumbprint."
        Return $false
    }
    elseif (($Ensure -eq 'Absent') -and ($pathGood))
    {
        Write-Verbose "Checking for $thumbprint to be absent in the $location store under $store."
        if ([bool](Get-childitem -Path $CertificateBaseLocation | ? thumbprint -eq $thumbprint))
        {
            Write-Verbose "Found the matching certificate in Certificate Store $store"
        }else{
            Write-Verbose "Unable to find a matching certificate in Certificate Store $store"
            $IsValid = $true
        }
    }
    else
    {
        Write-Verbose "Certificate Thumbprint not available./nChecking $Name for Name or Thumbprint match to be present in the $location store under $store."
        if ([bool](Get-ChildItem $CertificateBaseLocation | ? {@($_.name,$_.thumbprint) -like $Name}))
        {
            Write-Verbose "Found a matching certificate at $CertificateLocation"
        }else{
            Write-Verbose "Unable to find a matching certificate at $CertificateLocation"
            $IsValid = $true
        }
    }

    #Needs to return a boolean  
    return $IsValid
}


