# Development Infrastructure Orchestration

> [!WARNING]  
>	Instructions are for Windows OS. For Mac OS or Linux, you're on your own.

## Usage

```powershell
docker compose up -d; # runs infrastructure
docker compose -f .\docker-compose.helpers.yml -p "muge-helpers" up -d;
```

```powershell
docker compose up placement redis rabbitmq -d; # runs only dapr placement, redis and rabbitmq
docker compose -f .\docker-compose.helpers.yml -p "muge-helpers" up "redis-insight" -d;
docker compose -f .\docker-compose.helpers.yml -p "muge-helpers" up "linqpad-dapr" -d;
```

> [!NOTE]  
>	Ensure that port 5000..5001 are not in use.


## Create dev-certs

> [!IMPORTANT]  
> Replace `$DEV_CERTS_PASSWORD` below with your actual password, and also update it in the `.env` file.

Run on your host machine:

```powershell
Set-Location ~;
dotnet dev-certs https --clean;
dotnet dev-certs https --export-path ".\.aspnet\https\aspnetapp.pfx" -p $DEV_CERTS_PASSWORD;
dotnet dev-certs https --trust;
```

> [!WARNING]  
> DEV_CERTS works with `https://localhost:<port>` but not with `https://host.docker.internal:<port>`.
