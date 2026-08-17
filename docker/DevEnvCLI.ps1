<#
.SYNOPSIS
Starts or stops Docker services based on the provided action.

.DESCRIPTION
This script controls Docker services, either starting them up or shutting them down, based on the given action.

.PARAMETER Action
The action to be performed. Can be either "up" or "down".

.EXAMPLE
.\DevEnvCLI.ps1 -Action "up"

This example starts the Docker services.
#>

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("up", "down")]
    [string]$Action
)

$dockerDaprFile = ".\docker-compose.dapr.yml"
$projectName = "muge-dapr"
$environmentFile = Join-Path $PSScriptRoot ".env"

function Assert-DaprPrerequisites {
    if ([string]::IsNullOrWhiteSpace($env:APPDATA)) {
        throw "APPDATA is not available; the LINQPad Dapr secret-store path cannot be resolved."
    }

    $secretsFile = Join-Path $env:APPDATA "Microsoft\UserSecrets\LinqPad\secrets.json"
    if (-not (Test-Path -LiteralPath $secretsFile -PathType Leaf)) {
        throw "Missing '$secretsFile'. Create the local Dapr secrets file described in README.md before starting the environment."
    }

    try {
        Get-Content -LiteralPath $secretsFile -Raw | ConvertFrom-Json | Out-Null
    }
    catch {
        throw "The local Dapr secrets file '$secretsFile' is not valid JSON."
    }
}

function Wait-DaprOutboundReady {
    param (
        [int]$TimeoutSeconds = 90
    )

    $healthEndpoint = "http://127.0.0.1:3500/v1.0/healthz/outbound"
    $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)

    do {
        try {
            $response = Invoke-WebRequest -Uri $healthEndpoint -Method Get -TimeoutSec 2 -UseBasicParsing
            if ($response.StatusCode -eq 204) {
                Write-Host "Dapr sidecar and outbound components are ready."
                return
            }
        }
        catch {
            # The sidecar may still be starting or initializing its components.
        }

        Start-Sleep -Seconds 2
    }
    while ([DateTimeOffset]::UtcNow -lt $deadline)

    throw "Dapr did not become outbound-ready within $TimeoutSeconds seconds. Inspect 'docker compose -f $dockerDaprFile -p $projectName logs linqpad-dapr'."
}

function Invoke-DockerEnvironment {
    param (
        [ValidateSet("up", "down")]
        [string]$RequestedAction
    )

    switch ($RequestedAction) {
        "up" {
            Assert-DaprPrerequisites

            docker compose up -d --wait --wait-timeout 120 "alloy" "loki" "tempo" "prometheus" "redis" "rabbitmq"
            if ($LASTEXITCODE -ne 0) { throw "Starting the base Muge services failed with exit code $LASTEXITCODE." }

            docker compose -f $dockerDaprFile -p $projectName up -d "placement" "scheduler" "linqpad-dapr"
            if ($LASTEXITCODE -ne 0) { throw "Starting the Muge Dapr services failed with exit code $LASTEXITCODE." }

            Wait-DaprOutboundReady
        }
        "down" {
            docker compose -f $dockerDaprFile -p $projectName down
            if ($LASTEXITCODE -ne 0) { throw "Stopping the Muge Dapr services failed with exit code $LASTEXITCODE." }

            docker compose down
            if ($LASTEXITCODE -ne 0) { throw "Stopping the base Muge services failed with exit code $LASTEXITCODE." }
        }
    }
}

if (-not (Test-Path -LiteralPath $environmentFile -PathType Leaf)) {
    throw "Missing '$environmentFile'. Copy '.env.example' to '.env' and configure local values first."
}

Push-Location $PSScriptRoot
try {
    Invoke-DockerEnvironment -RequestedAction $Action
}
finally {
    Pop-Location
}
