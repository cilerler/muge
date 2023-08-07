<#
.SYNOPSIS
Starts or stops Docker services based on the provided action.

.DESCRIPTION
This script controls Docker services, either starting them up or shutting them down, based on the given action.

.PARAMETER action
The action to be performed. Can be either "up" or "down".

.EXAMPLE
.\runme.ps1 -action "up"

This example starts the Docker services.
#>

param (
    [ValidateSet("up", "down")]
    [string]$action
)

# Constants
$DOCKER_HELPERS_FILE = ".\docker-compose.helpers.yml"
$PROJECT_NAME = "muge_helpers"

function StartOrStopDockerServices {
    param (
        [string]$action
    )

    switch ($action) {
        "up" {
            docker compose up rabbitmq redis -d
            docker compose -f $DOCKER_HELPERS_FILE -p $PROJECT_NAME up "redis-insight" -d
        }
        "down" {
            docker compose down
            docker compose -f $DOCKER_HELPERS_FILE -p $PROJECT_NAME down
        }
    }
}

StartOrStopDockerServices -action $action
