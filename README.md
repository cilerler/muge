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
dotnet dev-certs https --export-path ".\.aspnet\https\aspnetapp.pfx" -p $DEV_CERTS_PASSWORD;
dotnet dev-certs https --trust;
```

> [!IMPORTANT]  
> **DEV_CERTS** will only work as `https://localhost:<port>` and will not `https://host.docker.internal:<port>` therefore make sure that HTTPS redirections are off for development.


## Usage

```powershell
docker compose up -d; # runs infrastructure
docker compose -f .\docker-compose.helpers.yml -p "muge-helpers" up -d;
```

```powershell
docker compose up  "otel-collector" -d; # runs open-telemetry collector (which depends on grafana, loki, tempo, prometheus, minio)
docker compose up  "otel-collector" placement redis "redis-insight" rabbitmq -d;
docker compose -f .\docker-compose.helpers.yml -p "muge-helpers" up "linqpad-dapr" -d;
```
