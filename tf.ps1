#!/usr/bin/env pwsh
#Requires -PSEdition Core

<#
.SYNOPSIS 
    A wrapper around Terraform to ease integration with Azure state backends.
    It is very convention-driven, so please see https://github.com/olohmann/terraform-azure-runner/README.md
    for details. 
.DESCRIPTION 
    See https://github.com/olohmann/terraform-azure-runner/README.md for details.
.NOTES 
    File Name  : tf.ps1 
    Author     : Oliver Lohmann (oliver@lohmann.io) 
.LINK 
    https://github.com/olohmann/terraform-azure-runner
.EXAMPLE 
    See https://github.com/olohmann/terraform-azure-runner/README.md for details.
#>

param (
    # Target Path to the Terraform .tf files directory.
    [Parameter(
            Mandatory = $true)]
    [string]
    $TargetPath,

    # Name of the environment (e.g. dev, qa, prod). Is translated to a Terraform workspace.
    [Parameter(
            Mandatory = $false,
            HelpMessage = "EnvironmentName is a lowercase, alphanumeric name, starting with a letter.")]
    [Alias('e')]
    [ValidatePattern('(?-i:^[a-z][a-z0-9]+$)')]
    [ValidateLength(1,8)]
    [string]
    $EnvironmentName = "dev",

    # A shared prefix which is used to prefix the resource group for the storage account.
    # It will also be set to a TF_prefix environment variable when envoking the Terraform
    # deployment process.
    [Parameter(
            Mandatory = $false,
            HelpMessage = "Prefix is a lowercase, alphanumeric name, starting with a letter.")]
    [ValidatePattern('(?-i:^[a-z][a-z0-9]+$)')]
    [ValidateLength(1,8)]
    [string]
    $Prefix = "fabrikam",

    # The location for the resource group and storage account that will be created for the 
    # Terraform state store.
    [Parameter(
            Mandatory = $false,
            HelpMessage = "Location is a valid Azure location.")]
    [string]$Location = "westeurope",
    
    # The path to a Terraform variable file that shall be passed to the deployment.
    [Parameter(Mandatory = $false)][string]$VarFile = "",

    # When set, uses the explicit name for the util resource group instead of a generated
    # one. Not recommended to use, instead follow the conventional defaults.
    [Parameter(Mandatory = $false)][string]$UtilResourceGroupName = "",

    # Do not print colored console ouptut when set.
    [switch]$NoColor = $false,

    # Run Terraform init.
    [switch]$Init = $false,

    # Run Terraform plan.
    [switch]$Plan = $false,

    # Run Terraform destroy.
    [switch]$Destroy = $false,

    # Run Terraform apply.
    [switch]$Apply = $false,

    # Run Terraform validate.
    [switch][Alias('v')]$Validate = $false,

    # Run Terraform output.
    [switch]$Output = $false,

    # Use an existing Terraform plan (when applying).
    [switch]$UseExistingTerraformPlan = $false,
    
    # Keep the Azure Storage Account's firewall open instead of putting it to default deny 
    # when finishing the deployment process.
    [switch]$LeaveFirewallOpen = $false,
    
    # Do no change the current firewall setup.
    [switch]$SkipFirewallUpdate = $false,

    # Print the script's version and exit.
    [switch]$Version = $false,

    # Download the Terraform binary in the minimal required version. 
    [switch][Alias('d')]$DownloadTerraform = $false,
   
    # Print the environment variables during execution.
    [switch][Alias('p')]$PrintEnv = $false,
    
    # Force, that is do not ask for interactive input.
    [switch][Alias('f')]$Force = $false
)

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$ScriptVersion = [version]"2.1.0"
$TerrafomMinimumVersion = [version]"0.12.21"
$TerraformNoColor = if ($NoColor) { "-no-color" } else { "" }
$TerraformPlanPath = "terraform.tfplan"
$TerraformOutputPath = "output.json"

# Prepare Options
if ($UtilResourceGroupName -eq "") {
    $UtilResourceGroupName = "$($Prefix)_$($EnvironmentName)_util_rg".ToLower()
}

$Location = $Location.ToLower()
$Location = $Location -Replace " "
$TargetPath = Resolve-Path $TargetPath

$global:TfStateStorageAccountName = ""
$global:TfStateContainerName = "tf-state"

if ($VarFile) {
    if ([System.IO.File]::Exists($VarFile)) {
        $VarFile = Resolve-Path $VarFile
    } else {
        Write-Warning "Provided VarFile to not-existing path. Ignoring..."
    }
}

Write-Verbose "Provided Options"
Write-Verbose "================"
Write-Verbose "TargetPath:                     $TargetPath"
Write-Verbose "EnvironmentName:                $EnvironmentName"
Write-Verbose "Prefix:                         $Prefix"
Write-Verbose "Location:                       $Location"
Write-Verbose "VarFile:                        $VarFile"
Write-Verbose "UtilResourceGroupName:          $UtilResourceGroupName"
Write-Verbose ""
Write-Verbose "Setting Environment"
Write-Verbose "==================="
Write-Verbose "TF_VAR_prefix                   $Prefix"
Write-Verbose "TF_VAR_location                 $Location"
Write-Verbose "TF_VAR_util_resource_group_name $UtilResourceGroupName"
Write-Verbose ""

$env:TF_VAR_prefix = $Prefix
$env:TF_VAR_location = $Location
$env:TF_VAR_util_resource_group_name = $UtilResourceGroupName

function GetLocalTerraformInstallation() {
    $tf = $null

    try {
        $tf = Get-Command terraform
    }
    catch {
        if (!$DownloadTerraform) {
            throw "No local terraform client found and option 'DownloadTerraform' not specified."
        }
    }

    return $tf.Source
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function GetTerraformOsName {
    if ($IsLinux) {
        return "linux"
    }
    elseif ($IsMacOS) {
        return "darwin"
    }
    elseif ($IsWindows) {
        return "windows"
    }
    else {
        Write-Error "This script is executed in an unsupported OS."
    }
}

function VerifyTerraformSignature {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $TerraformDownloadBaseFolder,
        [Parameter(Mandatory = $true)]
        [string]
        $TerraformZipFilePath
    )

    $tfShaSums = Join-Path -Path $TerraformDownloadBaseFolder -ChildPath "terraform_SHA265SUMS"
    $tfShaSumsSig = Join-Path -Path $TerraformDownloadBaseFolder -ChildPath "terraform_SHA265SUMS.sig"

    # See https://www.hashicorp.com/security.html
    $HashiCorpGpgSig = @"
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQENBFMORM0BCADBRyKO1MhCirazOSVwcfTr1xUxjPvfxD3hjUwHtjsOy/bT6p9f
W2mRPfwnq2JB5As+paL3UGDsSRDnK9KAxQb0NNF4+eVhr/EJ18s3wwXXDMjpIifq
fIm2WyH3G+aRLTLPIpscUNKDyxFOUbsmgXAmJ46Re1fn8uKxKRHbfa39aeuEYWFA
3drdL1WoUngvED7f+RnKBK2G6ZEpO+LDovQk19xGjiMTtPJrjMjZJ3QXqPvx5wca
KSZLr4lMTuoTI/ZXyZy5bD4tShiZz6KcyX27cD70q2iRcEZ0poLKHyEIDAi3TM5k
SwbbWBFd5RNPOR0qzrb/0p9ksKK48IIfH2FvABEBAAG0K0hhc2hpQ29ycCBTZWN1
cml0eSA8c2VjdXJpdHlAaGFzaGljb3JwLmNvbT6JATgEEwECACIFAlMORM0CGwMG
CwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEFGFLYc0j/xMyWIIAIPhcVqiQ59n
Jc07gjUX0SWBJAxEG1lKxfzS4Xp+57h2xxTpdotGQ1fZwsihaIqow337YHQI3q0i
SqV534Ms+j/tU7X8sq11xFJIeEVG8PASRCwmryUwghFKPlHETQ8jJ+Y8+1asRydi
psP3B/5Mjhqv/uOK+Vy3zAyIpyDOMtIpOVfjSpCplVRdtSTFWBu9Em7j5I2HMn1w
sJZnJgXKpybpibGiiTtmnFLOwibmprSu04rsnP4ncdC2XRD4wIjoyA+4PKgX3sCO
klEzKryWYBmLkJOMDdo52LttP3279s7XrkLEE7ia0fXa2c12EQ0f0DQ1tGUvyVEW
WmJVccm5bq25AQ0EUw5EzQEIANaPUY04/g7AmYkOMjaCZ6iTp9hB5Rsj/4ee/ln9
wArzRO9+3eejLWh53FoN1rO+su7tiXJA5YAzVy6tuolrqjM8DBztPxdLBbEi4V+j
2tK0dATdBQBHEh3OJApO2UBtcjaZBT31zrG9K55D+CrcgIVEHAKY8Cb4kLBkb5wM
skn+DrASKU0BNIV1qRsxfiUdQHZfSqtp004nrql1lbFMLFEuiY8FZrkkQ9qduixo
mTT6f34/oiY+Jam3zCK7RDN/OjuWheIPGj/Qbx9JuNiwgX6yRj7OE1tjUx6d8g9y
0H1fmLJbb3WZZbuuGFnK6qrE3bGeY8+AWaJAZ37wpWh1p0cAEQEAAYkBHwQYAQIA
CQUCUw5EzQIbDAAKCRBRhS2HNI/8TJntCAClU7TOO/X053eKF1jqNW4A1qpxctVc
z8eTcY8Om5O4f6a/rfxfNFKn9Qyja/OG1xWNobETy7MiMXYjaa8uUx5iFy6kMVaP
0BXJ59NLZjMARGw6lVTYDTIvzqqqwLxgliSDfSnqUhubGwvykANPO+93BBx89MRG
unNoYGXtPlhNFrAsB1VR8+EyKLv2HQtGCPSFBhrjuzH3gxGibNDDdFQLxxuJWepJ
EK1UbTS4ms0NgZ2Uknqn1WRU1Ki7rE4sTy68iZtWpKQXZEJa0IGnuI2sSINGcXCJ
oEIgXTMyCILo34Fa/C6VCm2WBgz9zZO8/rHIiQm1J5zqz0DrDwKBUM9C
=LYpS
-----END PGP PUBLIC KEY BLOCK-----
"@
    # TODO: Test for gpg in path instead.
    if ($IsWindows -or $IsMacOS) {
        Write-Warning "Skipping SHA256SUM signature validation on Windows and MacOS. Requires GPG."
    }
    else {
        $hashiCorpGpgTmpFile = Join-Path $TerraformDownloadBaseFolder -ChildPath "hashicorp.gpg"
        Set-Content -Path $hashiCorpGpgTmpFile -Value $HashiCorpGpgSig
        gpg --quiet --no-verbose --batch --no-tty --import $hashiCorpGpgTmpFile
        gpg --quiet --no-verbose --batch --no-tty --verify  $tfShaSumsSig $tfShaSums
        if ($LastExitCode -gt 0) { throw "GPG signature validation of Terraform's SHA256 sums failed." }
    }

    $hash = Get-FileHash -Path $TerraformZipFilePath -Algorithm 'SHA256'
    $zipFileName = Split-Path $TerraformZipFilePath -Leaf

    $success = $false
    $shaSums = Get-Content $tfShaSums
    foreach ($line in $shaSums) {
        if ($line -like "*$zipFileName*") {
            $result = $line -Split '  '
            if ($result.Count -gt 0) {
                $success = $result[0] -eq $hash.Hash
            }
        }
    }

    if (!$success) {
        throw "Validating the signature of the downloaded terraform release failed. See Path: $($TerraformDownloadBaseFolder)"
    }
}

function DownloadCurrentTerraformVersionToTemporaryLocation {
    $osName = GetTerraformOsName
    $uriBinary = "https://releases.hashicorp.com/terraform/$TerrafomMinimumVersion/terraform_$($TerrafomMinimumVersion)_$($osName)_amd64.zip"
    $uriShaSums = "https://releases.hashicorp.com/terraform/$TerrafomMinimumVersion/terraform_$($TerrafomMinimumVersion)_SHA256SUMS"
    $uriShaSumsSig = "https://releases.hashicorp.com/terraform/$TerrafomMinimumVersion/terraform_$($TerrafomMinimumVersion)_SHA256SUMS.sig"

    $tmpDirectory = New-TemporaryDirectory
    $outputBinary = Join-Path -Path $tmpDirectory -ChildPath "terraform_$($TerrafomMinimumVersion)_$($osName)_amd64.zip"
    $outputShaSums = Join-Path -Path $tmpDirectory -ChildPath "terraform_SHA265SUMS"
    $outputShaSumsSig = Join-Path -Path $tmpDirectory -ChildPath "terraform_SHA265SUMS.sig"

    Invoke-WebRequest -Uri $uriBinary -OutFile $outputBinary
    Invoke-WebRequest -Uri $uriShaSums -OutFile $outputShaSums
    Invoke-WebRequest -Uri $uriShaSumsSig -OutFile $outputShaSumsSig

    VerifyTerraformSignature -TerraformDownloadBaseFolder $tmpDirectory -TerraformZipFilePath $outputBinary
    Expand-Archive -Path $outputBinary -DestinationPath $tmpDirectory

    if ($IsWindows) {
        $tfExe = Join-Path $tmpDirectory -ChildPath "terraform.exe"
        return $tfExe 
    }
    else {
        $tfExe = Join-Path $tmpDirectory -ChildPath "terraform"
        chmod +x $tfExe
        return $tfExe 
    }
}

function ValidateTerraformMinimumVersion {
    $versionInfo = [Version]"0.0.0"
    $versionStr = &"$TerraformPath" --% -version
    if ($LastExitCode -gt 0) { throw "Cannot validate terraform version." }

    [Regex]$regex = "v(?<versionNumber>\d+.\d+.\d+)"
    $regexMatch = $regex.Match($versionStr)
    if ($regexMatch.Success) {
        $versionInfo = [Version]$($regexMatch.Groups["versionNumber"].Value)
    }
    else {
        throw "Cannot get version number from terraform."
    }

    if (!$($versionInfo -ge $TerrafomMinimumVersion)) {
        throw "Require at least terraform v$TerrafomMinimumVersion but found terraform v$versionInfo."
    }
}

function GetSha256 {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $InputString,
        [Parameter(Mandatory = $false)]
        [int]
        $TrimTo = -1
    )

    $hashValue = New-Object System.Security.Cryptography.SHA256Managed `
    | ForEach-Object { $_.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputString)) } `
    | ForEach-Object { $_.ToString("x2") } `
    | Join-String 
    
    $hashValue = $hashValue.ToLower()
    if ($trimTo -gt -1) {
        $hashValue = $hashValue.Substring(0, $trimTo)
    }

    return $hashValue
}

function TryUploadTestBlob {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $StorageAccountName,
        [Parameter(Mandatory = $true)]
        [string]
        $StorageAccountContainerName
    )


}

function CreateOrUpdateTerraformBackend {
    az group create --name "$UtilResourceGroupName" --location "$Location" --output none
    if ($LastExitCode -gt 0) { throw "az CLI error." }

    $azRes = az group show --name "$UtilResourceGroupName" --output json | ConvertFrom-Json
    if ($LastExitCode -gt 0) { throw "az CLI error." }

    $tf_backend_resource_group_id = $azRes.Id
    $tf_hash_suffix = GetSha256 -InputString $tf_backend_resource_group_id -TrimTo 6

    $global:TfStateStorageAccountName = "tf$($Prefix)$($EnvironmentName)$($tf_hash_suffix)"

    az storage account create --name $global:TfStateStorageAccountName --resource-group $UtilResourceGroupName --location $Location --sku "Standard_LRS" --kind "BlobStorage" --access-tier "Hot" --encryption-service "blob" --encryption-service "file" --https-only "true" --default-action "Allow" --bypass "None" --output none --tags "environment=$EnvironmentName" "purpose=TerraformStateStorage" "prefix=$Prefix"
    if ($LastExitCode -gt 0) { throw "az CLI error." }

    if ($SkipFirewallUpdate) {
        Write-Verbose "[Terraform State] Skip updating Azure Storage firewall configuration..."
    }
    else
    {
        Write-Verbose "[Terraform State] Updating firewall configuration..."
        $saUpdateRetryCount = 0
        $saUpdateSuccessful = $false
        for ($saUpdateRetryCount = 0; $saUpdateRetryCount -lt 10 -and !$saUpdateSuccessful; $saUpdateRetryCount++) {
            Write-Verbose "[Terraform State] Waiting for update..."
            Start-Sleep -Seconds 2
            $saShowResponse = az storage account show --name $global:TfStateStorageAccountName | ConvertFrom-Json
            if ($saShowResponse.networkRuleSet.defaultAction.ToLower() -eq "allow") {
                Write-Verbose "[Terraform State] Successfully configured firewall... Waiting 10secs for synchronization..."
                $saUpdateSuccessful = $true
                Start-Sleep -Seconds 10
            }
        }

        if (!$saUpdateSuccessful) {
            throw "[Terraform State] Failed to temporarily de-activate the terraform state storage account's firewall."
        }
    }

    $accountKeyResponse = az storage account keys list --account-name $global:TfStateStorageAccountName | ConvertFrom-Json
    if ($LastExitCode -gt 0) { throw "az CLI error." }

    az storage container create --account-name $global:TfStateStorageAccountName --account-key $accountKeyResponse[0].value --name $global:TfStateContainerName --public-access "off" --auth-mode key --output none
    if ($LastExitCode -gt 0) { throw "az CLI error." }
}

function LockdownTerraformBackend {
    $existingNetworkRulesResponse = az storage account network-rule list --account-name $global:TfStateStorageAccountName | ConvertFrom-Json
    if ($LastExitCode -gt 0) { throw "az CLI error." }
    Write-Verbose "[Terraform State] Rewriting network rules..."
    foreach ($ipRule in $existingNetworkRulesResponse.ipRules) {
        Write-Verbose "[Terraform State] Dropping $($ipRule.ipAddressOrRange)"
        az storage account network-rule remove --resource-group $UtilResourceGroupName --account-name $Location --ip-address $ipRule.ipAddressOrRange --output none
        if ($LastExitCode -gt 0) { throw "az CLI error." }
    }

    Write-Verbose "[Terraform State] Set storage account firewall to `"default-action: Deny`"..."
    az storage account update --name $global:TfStateStorageAccountName --default-action "Deny" --output none
    if ($LastExitCode -gt 0) { throw "az CLI error." }
}

function EnsureAzureCliContext () {
    if ($Force) {
        return
    }

    $defaultSubscriptionDetails = az account list --all --query "[?isDefault] | [0]" | ConvertFrom-Json 
    if ($LastExitCode -gt 0) { throw "az CLI error." }

    $defaultSubscriptionId = $defaultSubscriptionDetails.id;
    $defaultSubscriptionName = $defaultSubscriptionDetails.name;

    Write-Host ""
    Write-Host "Detected the following Azure configuration:"
    Write-Host "Subscription ID = $defaultSubscriptionId"
    Write-Host "Subscription Name = $defaultSubscriptionName"
    Write-Host ""

    $confirmation = Read-Host "Continue using this subscription? (y/n)"
    if ($confirmation.ToLower() -ne 'y') {
        Write-Host "Stopped by user."
        Write-Host ""
        exit
    }
}

function SwitchToTerraformWorskpace {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,
        [Parameter(Mandatory = $true)]
        [string]
        $Workspace
    )

    Write-Verbose "[Terraform] Switch Workspace: $Path"

    Push-Location
    try {
        Set-Location -Path $Path
        $tfWorkspace = &"$TerraformPath" workspace show
        if ($LastExitCode -gt 0) { throw "terraform error." }

        Write-Verbose "[Terraform] Current workspace: $tfWorkspace"
        if ($tfWorkspace.ToLower() -eq $Workspace.ToLower()) {
            Write-Verbose "[Terraform] No workspace switch required."
        }
        else {
            $tfWorkspaceListString = &"$TerraformPath" workspace list
            if ($LastExitCode -gt 0) { throw "terraform error." }
            $tfWorkspaceList = $tfWorkspaceListString.Split([Environment]::NewLine)
            $found = $false
            foreach ($tfWorkspaceItem in $tfWorkspaceList) {
                Write-Verbose "[Terraform] Found workspace $tfWorkspaceItem"
                if ($tfWorkspaceItem.ToLower().Contains($Workspace.ToLower())) {
                    $found = $true
                    Break
                }
            }

            if ($found) {
                &"$TerraformPath" workspace select $Workspace.ToLower()
                if ($LastExitCode -gt 0) { throw "terraform error." }
            }
            else {
                &"$TerraformPath" workspace new $Workspace.ToLower()
                if ($LastExitCode -gt 0) { throw "terraform error." }
            }
        }
    }
    finally {
        Pop-Location
    }
}

function TerraformPlan {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    Write-Verbose "[Terraform] Plan: $Path"

    Push-Location
    try {
        Set-Location -Path $Path

        if ($VarFile) {
            &"$TerraformPath" plan $TerraformNoColor -input=false -var-file="$VarFile" -out="`"$TerraformPlanPath`""
        } else {
            &"$TerraformPath" plan $TerraformNoColor -input=false -out="`"$TerraformPlanPath`""
        }
        if ($LastExitCode -gt 0) { throw "terraform error." }
    }
    finally {
        Pop-Location
    }
}

function TerraformApply {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    Write-Verbose "[Terraform] Apply: $Path"

    Push-Location
    try {
        Set-Location -Path $Path

        if (!$force) {
            $confirmation = Read-Host "[Terraform] Continue deployment? (y/n)"
            if ($confirmation.ToLower() -ne 'y') {
                Write-Host "[Terraform] Stopped by user."
                Write-Host ""
                exit
            }
        }

        &"$TerraformPath" apply $TerraformNoColor -input=false "`"$TerraformPlanPath`""
        if ($LastExitCode -gt 0) { throw "terraform error." }
    }
    finally {
        Pop-Location
    }
}

function TerraformDestroy {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    Write-Verbose "[Terraform] Destroy: $Path"

    Push-Location
    try {
        Set-Location -Path $Path

        if (!$force) {
            $confirmation = Read-Host "[Terraform] Continue with terraform destroy? (y/n)"
            if ($confirmation.ToLower() -ne 'y') {
                Write-Host "[Terraform] Stopped by user."
                Write-Host ""
                exit
            }
        }

        if ($VarFile) {
            &"$TerraformPath" destroy $TerraformNoColor -auto-approve -input=false -var-file="$VarFile"
        } else {
            &"$TerraformPath" destroy $TerraformNoColor -auto-approve -input=false
        }
        if ($LastExitCode -gt 0) { throw "terraform error." }
    }
    finally {
        Pop-Location
    }
}

function TerraformOutput {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    Write-Verbose "[Terraform] Output: $Path"

    Push-Location
    try {
        Set-Location -Path $Path

        $terrafomOutput = &"$TerraformPath" output $TerraformNoColor -json
        if ($LastExitCode -gt 0) { throw "terraform error." }

        Set-Content -Path $TerraformOutputPath  -Value $terrafomOutput
    }
    finally {
        Pop-Location
    }
}


function CleanTerraformDirectory {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    $tfStateFile = Join-Path -Path $Path -ChildPath ".terraform" -AdditionalChildPath "terraform.tfstate"
    $tfStateEnvironmentFile = Join-Path -Path $Path -ChildPath ".terraform" -AdditionalChildPath "environment"
    Remove-Item -ErrorAction SilentlyContinue -Path $tfStateFile
    Remove-Item -ErrorAction SilentlyContinue -Path $tfStateEnvironmentFile
    if (!$UseExistingTerraformPlan)
    {
        $tfPlanFile = Join-Path -Path $Path -ChildPath "terraform.tfplan"
        Remove-Item -ErrorAction SilentlyContinue -Path $tfPlanFile
    }
}

function InitTerraformWithRemoteBackend {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    Write-Verbose "[Terraform] Init: $Path"

    $accountKeyResponse = az storage account keys list --account-name $global:TfStateStorageAccountName | ConvertFrom-Json
    $key = $accountKeyResponse[0].value

    Push-Location
    try {
        Set-Location -Path $Path
        &"$TerraformPath" init $TerraformNoColor -backend-config "resource_group_name=$UtilResourceGroupName" -backend-config "storage_account_name=$($global:TfStateStorageAccountName)" -backend-config "container_name=$($global:TfStateContainerName)" -backend-config "access_key=`"$key`""
        if ($LastExitCode -gt 0) { throw "terraform error." }
    }
    finally {
        Pop-Location
    }
}

function InitTerraformWithLocalBackend {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    Push-Location
    try {
        Set-Location -Path $Path
        $ignoreOutput = &"$TerraformPath" init -backend=false $TerraformNoColor
        if ($LastExitCode -gt 0) { 
            Write-Error $ignoreOutput
            throw "terraform error."
        }
    }
    finally {
        Pop-Location
    }
}

function RunTerraformValidate {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    Push-Location
    Set-Location -Path $Path
    $ignore = &"$TerraformPath" validate
    $validationError = $LastExitCode -gt 0
    Pop-Location
    return $validationError
}

function PatchTerraformEnvironmentVariables {
    $isVerbose = [bool](Write-Verbose ([String]::Empty) 4>&1)

    Write-Verbose "== Patching Environment Variables to be compatible with Terraform Variables =="

    $environmentVariables = (Get-ChildItem env:*).GetEnumerator() | Sort-Object Name 

    if ($isVerbose -and $PrintEnv) {
        Write-Verbose ""
        Write-Verbose "[ Original Environment Variables ]"
        foreach ($environmentVariable in $environmentVariables) {
            Write-Verbose "$($environmentVariable.Name)=$($environmentVariable.Value)"
        }
    }

    foreach ($environmentVariable in $environmentVariables) {
        if ($environmentVariable.Name.StartsWith("TF_VAR_")) {
            $caseFixedName = "TF_VAR_" + $environmentVariable.Name.Remove(0, "TF_VAR_".Length).ToLower()
            Set-Item -LiteralPath Env:$caseFixedName -Value $environmentVariable.Value
            if (!$PrintEnv)
            {
                # Only be verbose if there is an actual case fix.
                if ($environmentVariable.Name -ne $caseFixedName)
                {
                    Write-Verbose "$( $environmentVariable.Name )='$( $environmentVariable.Value )' ==> $( $caseFixedName )='$( $environmentVariable.Value )'"
                }
            }
        }
    }

    if ($isVerbose -and $PrintEnv) {
        $environmentVariables = (Get-ChildItem env:*).GetEnumerator() | Sort-Object Name 

        Write-Verbose ""
        Write-Verbose "[ Patched Environment Variables ]"
        foreach ($environmentVariable in $environmentVariables) {
            Write-Verbose "$($environmentVariable.Name)=$($environmentVariable.Value)"
        }
    }

    Write-Verbose "============================================================================="
}


# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if ($Version) {
    Write-Host $ScriptVersion
    return
}

# Prepare Terraform Environment ------------------------------------------------
if ($Validate) {
    Write-Verbose "Validate only, skipping Azure Backend configuration check."
}
elseif ($env:ARM_CLIENT_ID -and $env:ARM_CLIENT_SECRET -and $env:ARM_SUBSCRIPTION_ID -and $env:ARM_TENANT_ID) {
    Write-Verbose "Detected Terraform-specific Azure Authorization via environment variables (ARM_CLIENT_ID, ...)"
}
elseif ($env:servicePrincipalId) {
    Write-Verbose "Detected Azure DevOps az configuration. Automatically setting Terraform env vars."
    $env:ARM_CLIENT_ID = $env:servicePrincipalId
    $env:ARM_CLIENT_SECRET = $env:servicePrincipalKey

    $defaultSubscriptionDetails = az account list --all --query "[?isDefault] | [0]" | ConvertFrom-Json 
    if ($LastExitCode -gt 0) { throw "az CLI error." }

    $env:ARM_SUBSCRIPTION_ID = $defaultSubscriptionDetails.id
    $env:ARM_TENANT_ID = $defaultSubscriptionDetails.tenantId
}
elseif ($env:AZURE_CREDENTIALS) {
    Write-Verbose "Detected GitHub az configuration. Automatically setting Terraform env vars. "
    $GitHubJsonSettings = ConvertFrom-Json -InputObject $env:AZURE_CREDENTIALS
    $env:ARM_CLIENT_ID = $GitHubJsonSettings.clientId
    $env:ARM_CLIENT_SECRET = $GitHubJsonSettings.clientSecret
    $env:ARM_SUBSCRIPTION_ID = $GitHubJsonSettings.subscriptionId
    $env:ARM_TENANT_ID = $GitHubJsonSettings.tenantId
}
else {
    Write-Verbose "Using az authentication context for Terraform (default for interactive login)"
    $currentAccount = az account show | ConvertFrom-Json
    if ($LastExitCode -gt 0) { throw "az CLI error." }
    $userName = $currentAccount.user.name

    $user = az ad user show --id "$userName" | ConvertFrom-Json
    if ($LastExitCode -gt 0) { throw "az CLI error." }

    Write-Verbose "Setting TF_VAR_az_cli_user_object_id=$($user.objectId)"
    $env:TF_VAR_az_cli_user_object_id=$user.objectId

    Write-Verbose ""
}

# Fix Environment --------------------------------------------------------------
PatchTerraformEnvironmentVariables

# Setup Terraform --------------------------------------------------------------
if ($DownloadTerraform) {
    $TerraformPath = DownloadCurrentTerraformVersionToTemporaryLocation
}
else {
    $TerraformPath = GetLocalTerraformInstallation
}

ValidateTerraformMinimumVersion
CleanTerraformDirectory -Path $TargetPath
InitTerraformWithLocalBackend -Path $TargetPath
$tfValidateError = RunTerraformValidate -Path $TargetPath

# Run deployment on all Subdeployments -----------------------------------------
if ($tfValidateError) {
    throw "[Terraform] Validation errors detected. Stopping deployment process."
}
else {
    Write-Verbose "[Terraform] Validation completed successfully."
}

if ($Validate) {
    return
}

EnsureAzureCliContext


if ($Init -or $Destroy -or $Plan -or $Apply -or $Output) {
    CreateOrUpdateTerraformBackend
    CleanTerraformDirectory -Path $TargetPath
    InitTerraformWithRemoteBackend -Path $TargetPath
    SwitchToTerraformWorskpace -Path $TargetPath -Workspace $EnvironmentName

    if ($Init) {
        # Nothing further to do.
    } elseif ($Destroy) {
        TerraformDestroy -Path $TargetPath
    } elseif ($Plan) {
        TerraformPlan -Path $TargetPath
    } elseif ($Apply) {
        if (!$UseExistingTerraformPlan)
        {
            TerraformPlan -Path $TargetPath
        }
        TerraformApply -Path $TargetPath
    } elseif ($Output) {
        TerraformOutput -Path $TargetPath
    }

    if (!$LeaveFirewallOpen) {
        LockdownTerraformBackend
    }
} else {
    Write-Warning "Nothing modified or initialized. Please specify, -Init, -Destroy, -Plan or -Apply"
}

