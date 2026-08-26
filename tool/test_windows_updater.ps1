$ErrorActionPreference = 'Stop'
$testRoot = Join-Path $env:TEMP "finflow-updater-test-$PID"
$updaterSource = Join-Path $PSScriptRoot '..\assets\windows\finflow_updater.ps1'
$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

function New-UpdaterTestCase {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$OldVersion,
    [Parameter(Mandatory = $true)][string]$NewVersion
  )

  $root = Join-Path $testRoot $Name
  $packageDirectory = Join-Path $root 'package'
  $installDirectory = Join-Path $root 'install'
  New-Item -ItemType Directory -Force -Path $packageDirectory | Out-Null
  New-Item -ItemType Directory -Force -Path $installDirectory | Out-Null

  Copy-Item "$env:WINDIR\System32\cmd.exe" "$packageDirectory\FinFlow.exe"
  Copy-Item "$env:WINDIR\System32\cmd.exe" "$installDirectory\FinFlow.exe"
  Set-Content "$packageDirectory\version.txt" $NewVersion
  Set-Content "$installDirectory\version.txt" $OldVersion

  $paths = @{
    Root = $root
    PackageDirectory = $packageDirectory
    InstallDirectory = $installDirectory
    Archive = Join-Path $root 'FinFlow-Windows-test.zip'
    Ready = Join-Path $root 'updater.ready'
    Result = Join-Path $root 'updater.result'
    Cancel = Join-Path $root 'updater.cancel'
    Backup = Join-Path $root 'backup'
    Log = Join-Path $root 'updater.log'
    Script = Join-Path $root 'FinFlow-Updater-test.ps1'
  }

  Copy-Item $updaterSource $paths.Script
  Compress-Archive -Path "$packageDirectory\*" -DestinationPath $paths.Archive
  return $paths
}

function Invoke-UpdaterTestCase {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Paths,
    [switch]$ForceFailureAfterInstall
  )

  $arguments = @(
    '-NoLogo',
    '-NoProfile',
    '-NonInteractive',
    '-ExecutionPolicy', 'Bypass',
    '-File', $Paths.Script,
    '-HostProcessId', '2147483647',
    '-ArchivePath', $Paths.Archive,
    '-InstallDirectory', $Paths.InstallDirectory,
    '-ExecutablePath', (Join-Path $Paths.InstallDirectory 'FinFlow.exe'),
    '-ReadyPath', $Paths.Ready,
    '-ResultPath', $Paths.Result,
    '-CancelPath', $Paths.Cancel,
    '-BackupPath', $Paths.Backup,
    '-LogPath', $Paths.Log,
    '-ScriptPath', $Paths.Script,
    '-SkipRestart'
  )
  if ($ForceFailureAfterInstall) {
    $arguments += '-ForceFailureAfterInstall'
  }

  & $windowsPowerShell @arguments
  return $LASTEXITCODE
}

function Assert-Condition {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

try {
  $success = New-UpdaterTestCase `
    -Name 'success' `
    -OldVersion 'old' `
    -NewVersion 'new'
  $successExitCode = Invoke-UpdaterTestCase -Paths $success
  if ($successExitCode -ne 0) {
    if (Test-Path $success.Log) {
      Get-Content $success.Log
    }
    throw "O teste de sucesso retornou $successExitCode."
  }
  Assert-Condition (Test-Path $success.Ready) `
    'O atualizador nao confirmou que estava pronto.'
  Assert-Condition (
    (Get-Content $success.Result -Raw).Trim() -eq 'success'
  ) 'O atualizador nao registrou sucesso.'
  Assert-Condition (
    (Get-Content (Join-Path $success.InstallDirectory 'version.txt') -Raw).Trim() -eq 'new'
  ) 'Os arquivos da nova versao nao foram instalados.'

  $rollback = New-UpdaterTestCase `
    -Name 'rollback' `
    -OldVersion 'old' `
    -NewVersion 'new'
  $rollbackExitCode = Invoke-UpdaterTestCase `
    -Paths $rollback `
    -ForceFailureAfterInstall
  Assert-Condition ($rollbackExitCode -ne 0) `
    'O teste de restauracao deveria retornar falha.'
  Assert-Condition (
    (Get-Content $rollback.Result -Raw).TrimStart().StartsWith('failure')
  ) 'A falha controlada nao foi registrada.'
  Assert-Condition (
    (Get-Content (Join-Path $rollback.InstallDirectory 'version.txt') -Raw).Trim() -eq 'old'
  ) 'A versao anterior nao foi restaurada.'

  Write-Host 'Atualizador do Windows: instalacao e restauracao validadas.'
} finally {
  Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
