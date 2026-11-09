<#
.SYNOPSIS
    Builds the extension and the test app in a Business Central container, tests the upgrade from the
    previous release, and runs the AL tests. CI and local Windows machines run this same script.

.PARAMETER RepoRoot
    Repository root (contains app/ and test/).

.PARAMETER PreviousApp
    Path to the previous release's .app (or .zip containing it). When given, it is installed first and the
    new build is published as an upgrade, so a broken upgrade path fails the run.

.PARAMETER KeepContainer
    Keep the container afterwards (for e2e runs against its API). Default: remove it.

.OUTPUTS
    <RepoRoot>/out/*.app and <RepoRoot>/out/TestResults.xml
#>
param(
    [Parameter(Mandatory = $true)][string] $RepoRoot,
    [string] $PreviousApp = '',
    [string] $ContainerName = 'bcbuild',
    [string] $Password = 'P@ssw0rd',
    [switch] $KeepContainer
)

$ErrorActionPreference = 'Stop'
Import-Module BcContainerHelper

$work = 'C:\src'
$out = Join-Path $RepoRoot 'out'
New-Item -ItemType Directory -Path "$work\app", "$work\tests", $out -Force | Out-Null
Copy-Item -Path (Join-Path $RepoRoot 'app\*') -Destination "$work\app" -Recurse -Force
Copy-Item -Path (Join-Path $RepoRoot 'test\*') -Destination "$work\tests" -Recurse -Force
Get-ChildItem "$work\app", "$work\tests" -Filter *.app -File | Remove-Item -Force

$appJson = Get-Content -Path "$work\app\app.json" -Raw | ConvertFrom-Json
$bcVersion = $appJson.platform -replace '\.0\.0$', ''
$credential = New-Object PSCredential 'admin', (ConvertTo-SecureString -String $Password -AsPlainText -Force)

$artifactUrl = Get-BcArtifactUrl -type OnPrem -version $bcVersion -country w1 -select Latest
Write-Host "Creating container $ContainerName from $artifactUrl"
New-BcContainer `
    -accept_eula `
    -containerName $ContainerName `
    -artifactUrl $artifactUrl `
    -auth NavUserPassword `
    -credential $credential `
    -updateHosts `
    -accept_outdated `
    -includeTestToolkit `
    -includeTestLibrariesOnly `
    -additionalParameters @('--volume', "${work}:${work}")

try {
    if ($PreviousApp) {
        $previous = $PreviousApp
        if ($PreviousApp.EndsWith('.zip')) {
            Expand-Archive -Path $PreviousApp -DestinationPath "$work\previous" -Force
            $previous = (Get-ChildItem "$work\previous\*.app" | Select-Object -First 1).FullName
        }
        Write-Host "Installing previous release $previous"
        Publish-BcContainerApp -containerName $ContainerName -appFile $previous -skipVerification -sync -install
    }

    $appFile = Compile-AppInBcContainer -containerName $ContainerName -credential $credential `
        -appProjectFolder "$work\app" -appOutputFolder "$work\app" -EnableCodeCop -EnableUICop -EnablePerTenantExtensionCop

    if ($PreviousApp) {
        Write-Host "Upgrading to $appFile"
        Publish-BcContainerApp -containerName $ContainerName -appFile $appFile -skipVerification -sync -upgrade
    }
    else {
        Publish-BcContainerApp -containerName $ContainerName -appFile $appFile -skipVerification -sync -install
    }

    $installed = Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties |
        Where-Object { $_.Publisher -eq 'alpamayo' -and $_.Name -eq $appJson.name }
    $installed | Format-Table Name, Version, IsInstalled, SyncState, NeedsUpgrade
    $current = $installed | Where-Object { $_.Version -eq $appJson.version }
    if (-not $current -or -not $current.IsInstalled) {
        throw "Version $($appJson.version) is not installed after publish/upgrade."
    }

    $testAppFile = Compile-AppInBcContainer -containerName $ContainerName -credential $credential `
        -appProjectFolder "$work\tests" -appOutputFolder "$work\tests" -appSymbolsFolder "$work\app"
    Publish-BcContainerApp -containerName $ContainerName -appFile $testAppFile -skipVerification -sync -install

    $testAppJson = Get-Content -Path "$work\tests\app.json" -Raw | ConvertFrom-Json
    $resultFile = "$work\TestResults.xml"
    $allPassed = Run-TestsInBcContainer -containerName $ContainerName -credential $credential `
        -extensionId $testAppJson.id -XUnitResultFileName $resultFile -detailed -returnTrueIfAllPassed

    Copy-Item -Path $appFile, $resultFile -Destination $out -Force
    if (-not $allPassed) {
        throw "AL tests failed, see $out\TestResults.xml"
    }
    Write-Host "Done: $out"
}
finally {
    if (-not $KeepContainer) {
        Remove-BcContainer -containerName $ContainerName -ErrorAction SilentlyContinue
    }
}
