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
    [string[]]$Store = 'My',
    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',
    [string]$Password,
    [pscredential]$SecurePassword
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
    [string[]]$Store = 'My',
    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',
    [string]$Password,
    [pscredential]$SecurePassword
    )

    if($PSBoundparameters.Password)
    {
        $SecurePassword = New-Object System.Management.Automation.PSCredential("blank",(ConvertTo-SecureString -string $Password -AsPlainText -Force))
    }
    if(-not $SecurePassword)
    {
        $noenc = $true
        $SecurePassword = $null
    }
    if(Test-Path $Path)
    {
        if($noenc -eq $true){
            $thumbprint = Get-Thumbprint -Path $Path
        }else{
            $thumbprint = Get-Thumbprint -Path $Path -SecurePassword $SecurePassword
        }
    }
    foreach ($Store in $($PSBoundparameters.Store))
    {
        $CertificateBaseLocation = "cert:\$Location\$Store"
        if ($Ensure -like 'Present')
        {
            Write-Verbose "Importing $path to $CertificateBaseLocation."
            if($noenc -and (-not ($Path -match ".pfx"))){Import-Certificate -CertStoreLocation $CertificateBaseLocation -FilePath $Path
            }else{
            Import-PfxCertificate -CertStoreLocation $CertificateBaseLocation -FilePath $Path -Password $SecurePassword.Password
            }
        }
        else
        {
            if ([bool](Get-childitem -Path $CertificateBaseLocation | Where-object thumbprint -eq $thumbprint))
            {
                $CertificatePath = (Get-childitem -Path $CertificateBaseLocation | Where-object thumbprint -eq $thumbprint).PSPath
            }elseif ([bool](Get-childitem -Path $CertificateBaseLocation | Where-object thumbprint -eq $Name))
            {
                $CertificatePath = (Get-childitem -Path $CertificateBaseLocation | Where-object thumbprint -eq $Name).PSPath
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
    [string[]]$Store = 'My',
    [ValidateSet('Present','Absent')]
    [string]$Ensure = 'Present',
    [string]$Password,
    [pscredential]$SecurePassword
    )

    $IsValid = $false
    $falsecount = 0
    if($PSBoundparameters.Password)
    {
        $SecurePassword = New-Object System.Management.Automation.PSCredential("blank",(ConvertTo-SecureString -string $Password -AsPlainText -Force))
    }
    if(Test-Path $Path)
    {
        Write-Verbose "Filepath test is good. Grabbing PFX thumbprint."
        
        if(-not $SecurePassword){
            $thumbprint = Get-Thumbprint -Path $Path
        }else{
            $thumbprint = Get-Thumbprint -Path $Path -SecurePassword $SecurePassword
        }
        $pathGood = $true
    }else{
        $pathGood = $false
    }
    foreach ($Store in $($PSBoundparameters.Store))
    {
        $CertificateBaseLocation = "cert:\$Location\$Store"
        
        
        if (($Ensure -eq 'Present') -and ($pathGood))
        {
            Write-Verbose "Checking for thumbprint $thumbprint in the $location store under $store."
            if ([bool](Get-childitem -Path $CertificateBaseLocation | Where-object thumbprint -eq $thumbprint))
            {
                Write-Verbose "Found a matching certificate in Certificate Store $store"
                $IsValid = $true
            }else{
                Write-Verbose "Unable to find a matching certificate in Certificate Store $store"
                $falsecount ++
            }
        }
        elseif ($Ensure -eq "Present")
        {
            Write-Verbose "Ensure is Present, but the filepath test is bad. Unable to grab Certificate thumbprint./nUsing $Name."
            if ([bool](Get-childitem -Path $CertificateBaseLocation | Where-object thumbprint -eq $Name){$IsValid = $true}
            else{$falsecount ++}
        }
        elseif (($Ensure -eq 'Absent') -and ($pathGood))
        {
            Write-Verbose "Checking for $thumbprint to be absent in the $location store under $store."
            if ([bool](Get-childitem -Path $CertificateBaseLocation | Where-object thumbprint -eq $thumbprint))
            {
                Write-Verbose "Found the matching certificate in Certificate Store $store"
                $falsecount ++
            }else{
                Write-Verbose "Unable to find a matching certificate in Certificate Store $store"
                $IsValid = $true
            }
        }
        else
        {
            Write-Verbose "Certificate Thumbprint not available./nChecking for Thumbprint match against $name in Certificate Store $store."
            if ([bool](Get-ChildItem $CertificateBaseLocation | Where-object thumbprint -eq $Name))
            {
                Write-Verbose "Found a matching certificate in Certificate Store $store"
                $falsecount ++
            }else{
                Write-Verbose "Unable to find a matching certificate in Certificate Store $store"
                $IsValid = $true
            }
        }
    }
    #Needs to return a boolean  
    if(($falsecount -eq 0) -and $IsValid = $true){ Return $true }
    else{ return $false }
}

function Get-Thumbprint
{
    param (
    [parameter(Mandatory = $true)]
    [string]$Path,
    [pscredential]$SecurePassword
    )
    if(-not $PSboundparameters.SecurePassword){$pass = $null}
	else{$pass = $SecurePassword.Password}

    $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $certificate.Import($Path, $pass, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet)
    Return $certificate.thumbprint
}

Export-ModuleMember -Function *-TargetResource