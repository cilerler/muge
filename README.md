# Development Infrastructure Orchestration

> [!CAUTION]
> Avoid syncing live `.git` directories with Google Drive. The Drive client can’t keep up with Git’s rapid file churn and the repo ends up corrupted. Instead, put a bare (upstream) repository in Google Drive and push to it only when needed. This cuts the update frequency to a trickle, so Drive can handle it without breaking anything.

> [!IMPORTANT]  
> All instructions below are intended for Windows OS.
> If you're using macOS or Linux, you'll need to adapt the steps on your own.

> [!WARNING] 
> Make sure ports 5000–5009 are free to prevent conflicts with the local development environment.

## Create dev-certs

> [!IMPORTANT]  
> Replace `$DEV_CERTS_PASSWORD` below with your actual password, and also update it in the `.env` file.

Run on your host machine:

```powershell
Set-Location $env:userprofile;
dotnet dev-certs https --clean;
dotnet dev-certs https --export-path ".\.aspnet\https\dev-cert.pfx" -p $DEV_CERTS_PASSWORD;
dotnet dev-certs https --trust;
```

> [!IMPORTANT]  
> **DEV_CERTS** will only work as `https://localhost:<port>` and will not `https://host.docker.internal:<port>` therefore make sure that HTTPS redirections are off for development.


## Usage

Run from the `docker/` directory.

Bring up the full stack:

```powershell
docker compose up -d;                                                   # runs infrastructure
docker compose -f .\docker-compose.dapr.yml -p "muge-dapr" up -d;       # runs Dapr (placement + linqpad sidecar)
```

Minimum subset for Dapr work (Alloy for OTLP + Redis + RabbitMQ + Dapr sidecar):

```powershell
docker compose up alloy redis "redis-insight" rabbitmq -d;
docker compose -f .\docker-compose.dapr.yml -p "muge-dapr" up "placement" "linqpad-dapr" -d;
```
