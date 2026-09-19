#Requires -Version 5.1
<#
.SYNOPSIS
  Headless relay: Grok Bot (or any assistant with Shell) -> local Grok Build CLI.

.DESCRIPTION
  Thin wrapper around `agent` for prompt, continue, resume, and which.
  Prints only the agent reply on stdout; exits nonzero on failure.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('prompt', 'continue', 'resume', 'which')]
    [string]$Command,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs,

    [string]$Cwd
)

$ErrorActionPreference = 'Stop'

function Resolve-AgentPath {
    $defaultAgent = Join-Path $env:USERPROFILE '.grok\bin\agent.exe'
    if (Test-Path -LiteralPath $defaultAgent) {
        return (Resolve-Path -LiteralPath $defaultAgent).Path
    }

    foreach ($name in @('agent', 'grok')) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }

    Write-Error "Grok Build CLI not found. Install it or add agent/grok to PATH. Expected: $defaultAgent"
}

function Resolve-WorkingDirectory {
    param([string]$Override)

    if ($Override) {
        if (-not (Test-Path -LiteralPath $Override)) {
            Write-Error "Working directory does not exist: $Override"
        }
        return (Resolve-Path -LiteralPath $Override).Path
    }

    if ($env:GROK_BRIDGE_CWD) {
        if (-not (Test-Path -LiteralPath $env:GROK_BRIDGE_CWD)) {
            Write-Error "GROK_BRIDGE_CWD does not exist: $env:GROK_BRIDGE_CWD"
        }
        return (Resolve-Path -LiteralPath $env:GROK_BRIDGE_CWD).Path
    }

    $repoRoot = Split-Path -Parent $PSScriptRoot
    $defaultWorkspace = Join-Path $repoRoot 'workspace'

    if (-not (Test-Path -LiteralPath $defaultWorkspace)) {
        New-Item -ItemType Directory -Path $defaultWorkspace -Force | Out-Null
    }

    return (Resolve-Path -LiteralPath $defaultWorkspace).Path
}

function Invoke-Agent {
    param(
        [string]$AgentPath,
        [string[]]$AgentArgs,
        [string]$WorkDir
    )

    Push-Location $WorkDir
    try {
        & $AgentPath @AgentArgs
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    finally {
        Pop-Location
    }
}

$agentPath = Resolve-AgentPath
$workDir = Resolve-WorkingDirectory -Override $Cwd

switch ($Command) {
    'which' {
        Write-Output $agentPath
        & $agentPath --version 2>&1 | ForEach-Object { Write-Output $_ }
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        exit 0
    }

    'prompt' {
        if (-not $RemainingArgs -or $RemainingArgs.Count -eq 0) {
            Write-Error "Usage: bridge.ps1 prompt <message>"
        }
        $message = ($RemainingArgs -join ' ')
        Invoke-Agent -AgentPath $agentPath -WorkDir $workDir -AgentArgs @(
            '-p', $message,
            '--output-format', 'plain'
        )
        exit 0
    }

    'continue' {
        if (-not $RemainingArgs -or $RemainingArgs.Count -eq 0) {
            Write-Error "Usage: bridge.ps1 continue <message>"
        }
        $message = ($RemainingArgs -join ' ')
        Invoke-Agent -AgentPath $agentPath -WorkDir $workDir -AgentArgs @(
            '-c', '-p', $message,
            '--output-format', 'plain'
        )
        exit 0
    }

    'resume' {
        if (-not $RemainingArgs -or $RemainingArgs.Count -lt 2) {
            Write-Error "Usage: bridge.ps1 resume <session-id> <message>"
        }
        $sessionId = $RemainingArgs[0]
        $message = ($RemainingArgs[1..($RemainingArgs.Count - 1)] -join ' ')
        Invoke-Agent -AgentPath $agentPath -WorkDir $workDir -AgentArgs @(
            '--resume', $sessionId,
            '-p', $message,
            '--output-format', 'plain'
        )
        exit 0
    }
}
