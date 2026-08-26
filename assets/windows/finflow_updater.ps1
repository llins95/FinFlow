param(
  [Parameter(Mandatory = $true)][int]$HostProcessId,
  [Parameter(Mandatory = $true)][string]$ArchivePath,
  [Parameter(Mandatory = $true)][string]$InstallDirectory,
  [Parameter(Mandatory = $true)][string]$ExecutablePath,
  [Parameter(Mandatory = $true)][string]$ReadyPath,
  [Parameter(Mandatory = $true)][string]$ResultPath,
  [Parameter(Mandatory = $true)][string]$CancelPath,
  [Parameter(Mandatory = $true)][string]$BackupPath,
  [Parameter(Mandatory = $true)][string]$LogPath,
  [Parameter(Mandatory = $true)][string]$ScriptPath,
  [switch]$SkipRestart,
  [switch]$ForceFailureAfterInstall
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$staging = Join-Path ([System.IO.Path]::GetTempPath()) "FinFlow-Update-$HostProcessId"
$backupCreated = $false
$readySignaled = $false
$updateSucceeded = $false

function Write-UpdateLog {
  param([Parameter(Mandatory = $true)][string]$Message)

  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  Add-Content -LiteralPath $LogPath -Value "[$timestamp] $Message" -Encoding UTF8
}

function Test-HostProcessRunning {
  $hostProcess = Get-Process `
    -Id $HostProcessId `
    -ErrorAction SilentlyContinue
  return $null -ne $hostProcess
}

function Invoke-RobustCopy {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [Parameter(Mandatory = $true)][string]$Description
  )

  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  $robocopy = Join-Path $env:SystemRoot 'System32\robocopy.exe'
  if (-not (Test-Path -LiteralPath $robocopy -PathType Leaf)) {
    throw 'O Windows nao encontrou o Robocopy.'
  }

  Write-UpdateLog "$Description iniciada."
  & $robocopy $Source $Destination /E /COPY:DAT /DCOPY:DAT /R:10 /W:1 /XJ /NFL /NDL /NJH /NJS /NP | Out-Null
  $robocopyExitCode = $LASTEXITCODE
  if ($robocopyExitCode -ge 8) {
    throw "$Description falhou. Codigo do Robocopy: $robocopyExitCode."
  }
  Write-UpdateLog "$Description concluida. Codigo do Robocopy: $robocopyExitCode."
}

function Start-FinFlow {
  if ($SkipRestart) {
    return $null
  }

  $startedProcess = Start-Process `
    -FilePath $ExecutablePath `
    -WorkingDirectory $InstallDirectory `
    -PassThru
  return $startedProcess
}

function Show-UpdateError {
  param([Parameter(Mandatory = $true)][string]$Message)

  if ($SkipRestart) {
    return
  }

  try {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
      $Message,
      'FinFlow',
      [System.Windows.MessageBoxButton]::OK,
      [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
  } catch {
    # O arquivo de log continua disponivel mesmo se a caixa nao puder ser aberta.
  }
}

try {
  Set-Content -LiteralPath $LogPath -Value 'FinFlow Windows Updater' -Encoding UTF8
  Write-UpdateLog 'Atualizador iniciado.'

  foreach ($marker in @($ReadyPath, $ResultPath, $CancelPath)) {
    Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
  }
  foreach ($directory in @($staging, $BackupPath)) {
    if (Test-Path -LiteralPath $directory) {
      Remove-Item -LiteralPath $directory -Recurse -Force
    }
  }

  New-Item -ItemType Directory -Path $staging -Force | Out-Null
  Write-UpdateLog 'Extraindo o pacote validado para a pasta temporaria.'
  Expand-Archive -LiteralPath $ArchivePath -DestinationPath $staging -Force

  $newExecutable = Join-Path $staging 'FinFlow.exe'
  if (-not (Test-Path -LiteralPath $newExecutable -PathType Leaf)) {
    throw 'O pacote baixado nao contem FinFlow.exe.'
  }
  if (Test-Path -LiteralPath $CancelPath -PathType Leaf) {
    throw 'A preparacao da atualizacao foi cancelada pelo FinFlow.'
  }

  Set-Content -LiteralPath $ReadyPath -Value 'ready' -Encoding ASCII
  $readySignaled = $true
  Write-UpdateLog 'Pacote preparado. Aguardando o FinFlow fechar.'

  while (Test-HostProcessRunning) {
    if (Test-Path -LiteralPath $CancelPath -PathType Leaf) {
      throw 'A atualizacao foi cancelada antes do fechamento do FinFlow.'
    }
    Start-Sleep -Milliseconds 200
  }
  Start-Sleep -Milliseconds 1000
  Write-UpdateLog 'FinFlow fechado. Iniciando a substituicao dos arquivos.'

  Invoke-RobustCopy `
    -Source $InstallDirectory `
    -Destination $BackupPath `
    -Description 'Copia de seguranca'
  $backupCreated = $true

  Invoke-RobustCopy `
    -Source $staging `
    -Destination $InstallDirectory `
    -Description 'Instalacao da nova versao'

  if ($ForceFailureAfterInstall) {
    throw 'Falha forcada para testar a restauracao da versao anterior.'
  }

  if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
    throw 'FinFlow.exe nao foi encontrado depois da atualizacao.'
  }

  $newProcess = Start-FinFlow
  if (-not $SkipRestart) {
    Start-Sleep -Seconds 2
    $newProcess.Refresh()
    if ($newProcess.HasExited) {
      throw 'A nova versao fechou imediatamente depois de ser iniciada.'
    }
  }

  Set-Content -LiteralPath $ResultPath -Value 'success' -Encoding ASCII
  $updateSucceeded = $true
  Write-UpdateLog 'Atualizacao concluida e nova versao iniciada.'

  Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $BackupPath -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $ArchivePath -Force -ErrorAction SilentlyContinue
  exit 0
} catch {
  $failure = $_ | Out-String
  try {
    Write-UpdateLog "ERRO: $failure"
  } catch {
    # A falha original sera gravada diretamente no arquivo de resultado.
  }

  if ($backupCreated -and (Test-Path -LiteralPath $BackupPath)) {
    try {
      Invoke-RobustCopy `
        -Source $BackupPath `
        -Destination $InstallDirectory `
        -Description 'Restauracao da versao anterior'
    } catch {
      $rollbackFailure = $_ | Out-String
      $failure = "$failure`r`nFalha ao restaurar: $rollbackFailure"
      try {
        Write-UpdateLog "ERRO NA RESTAURACAO: $rollbackFailure"
      } catch {
        # O arquivo de resultado ainda recebera os dois erros.
      }
    }
  }

  Set-Content `
    -LiteralPath $ResultPath `
    -Value "failure`r`n$failure" `
    -Encoding UTF8

  $hostStillRunning = Test-HostProcessRunning
  if ($readySignaled -and -not $hostStillRunning) {
    try {
      Start-FinFlow | Out-Null
    } catch {
      try {
        Write-UpdateLog "ERRO AO REABRIR: $($_ | Out-String)"
      } catch {
        # O erro principal permanece no arquivo de resultado.
      }
    }
    Show-UpdateError -Message (
      "A atualizacao nao foi concluida. A versao anterior foi restaurada. " +
      "Consulte o registro em:`r`n$LogPath"
    )
  }
  exit 1
} finally {
  if ($updateSucceeded) {
    Remove-Item -LiteralPath $ScriptPath -Force -ErrorAction SilentlyContinue
  }
}
