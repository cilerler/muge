# Development Infrastructure Orchestration

```powershell
docker compose up -d; # runs infrastructure
docker compose -f .\docker-compose.helpers.yml -p "muge-helpers" up -d;
```

```powershell
docker compose up placement redis rabbitmq -d; # runs only dapr placement, redis and rabbitmq
docker compose -f .\docker-compose.helpers.yml -p "muge-helpers" up "linqpad-dapr" -d;
```
