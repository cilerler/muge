# Development Infrastructure Orchestration

Muge provides a Windows-first Docker Compose environment for local infrastructure, observability, and a Dapr sidecar used with LINQPad or another application running on the host.

> [!WARNING]
> This stack is for local development. It exposes databases and administrative UIs on the host, uses development credentials, and enables anonymous Grafana administration. Do not deploy it as-is to a shared or production environment.

## Prerequisites

- Windows with PowerShell.
- Docker Desktop with Docker Compose v2.
- The host ports listed in [Published ports](#published-ports) must be available.
- An application listening on `http://localhost:5000` when using `linqpad-dapr`; the sidecar reaches it through `host.docker.internal:5000`.

## Configure the local environment

Create the local Compose environment file once:

```powershell
Set-Location .\docker
Copy-Item .env.example .env
```

Edit `.env` with local-only passwords and bind-mount paths before starting the stack. The file is intentionally untracked; never commit real credentials. If credentials previously committed to this repository were ever real or shared, rotate them—removing the current file does not erase values from Git history.

The active local-file secret-store component reads `%APPDATA%\Microsoft\UserSecrets\LinqPad\secrets.json`. Create that local file before starting the Dapr sidecar, using the same Redis and RabbitMQ credentials configured in `.env`:

```json
{
  "redis": {
    "password": "<same value as REDIS_PASSWORD>"
  },
  "rabbitmq": {
    "username": "<same value as RABBITMQ_USERNAME>",
    "password": "<same value as RABBITMQ_PASSWORD>"
  }
}
```

This local file supplies the active Redis state, lock, and configuration components and the RabbitMQ pub/sub component through Dapr `secretKeyRef` entries. It must contain development secrets only and must not be committed.

### Optional HTTPS development certificate

The active infrastructure and Dapr sidecar do not require a certificate. Generate one only when a host application uses HTTPS, and keep HTTPS redirection disabled when the Dapr sidecar calls the application over HTTP on port `5000`.

```powershell
$certificateDirectory = Join-Path $env:USERPROFILE ".aspnet\https"
New-Item -ItemType Directory -Force -Path $certificateDirectory | Out-Null
dotnet dev-certs https --export-path (Join-Path $certificateDirectory "dev-cert.pfx") -p "<same local password configured in .env>"
dotnet dev-certs https --trust
```

## Start the stack

Run these commands from `docker/`. Start the base Compose file first because it creates the external `muge_network` used by the Dapr Compose project. `DevEnvCLI.ps1` validates the local Dapr secret file, waits for Redis and RabbitMQ readiness, and confirms that Dapr initialized its outbound components.

### Full environment

```powershell
docker compose up -d --wait --wait-timeout 120
.\DevEnvCLI.ps1 -Action up
```

### Focused Dapr environment

This subset starts the Dapr component dependencies and the Alloy metrics, logs, and traces path: Redis, RabbitMQ, Alloy, Loki, Tempo, and Prometheus. RabbitMQ's initialization service is included automatically. Pyroscope remains optional; start it when collecting profiles.

```powershell
.\DevEnvCLI.ps1 -Action up
```

Grafana, Redis Insight, Seq, Aspire Dashboard, Pyroscope, SQL Server, Durable Functions Monitor, and PlantUML are optional and remain outside this focused subset.

Check the two Compose projects independently:

```powershell
docker compose ps
docker compose -f .\docker-compose.dapr.yml -p "muge-dapr" ps
```

Stop Dapr first so it releases the external network, then stop the base stack:

```powershell
docker compose -f .\docker-compose.dapr.yml -p "muge-dapr" down
docker compose down
```

## Profile ingestion

The full environment starts both Alloy and Pyroscope. Applications instrumented with a Pyroscope SDK send profiles to Alloy at:

- `http://localhost:9999` when the application runs on the host.
- `http://alloy:9999` when the application runs in another container on `muge_network`.

Alloy forwards received profiles to Pyroscope. View them through Grafana at `http://localhost:3000` or the Pyroscope UI/API at `http://localhost:4040`.

Port `9999` uses the Pyroscope SDK ingestion protocol. OTLP ports `4317` and `4318` continue to accept metrics, logs, and traces; they do not accept profiles. Muge provides the ingestion path but does not automatically profile applications—each application must enable a supported Pyroscope SDK or profiler.

Grafana's Tempo data source maps the OpenTelemetry `service.name` resource attribute to Pyroscope's `service_name` label and uses the standard CPU profile type. Trace-to-profile links additionally require the application's language-specific OpenTelemetry profiling bridge to add `pyroscope.profile.id` to spans; profiles remain independently explorable without that bridge.

## Dapr configuration

The sidecar mounts [`docker/config/components/development/`](./docker/config/components/development/) as `/components` and loads [`docker/config/dapr-config.yaml`](./docker/config/dapr-config.yaml) through `--config`. The Dapr Compose project also runs Placement and Scheduler; Scheduler keeps its local job, actor-reminder, and workflow state in a Compose-managed volume.

Dapr exports a 10% trace sample to Alloy by default. Trace stdout, Dapr API request logging, and debug logging remain disabled for normal use; temporarily raise the values in `dapr-config.yaml` and `docker-compose.dapr.yml` when diagnosing a problem.

Alloy mounts the Docker socket to discover containers and collect their logs and metrics. Treat it as a trusted local-development service because access to that socket is effectively access to the local Docker daemon; do not reuse this setup on a shared or production host.

| Path | Purpose | Loaded by the local sidecar |
|---|---|---|
| [`components/development/`](./docker/config/components/development/) | Active Redis configuration, lock, and state stores; RabbitMQ pub/sub; local-file secret store; cron and local-storage bindings | Yes |
| [`components/examples/development/`](./docker/config/components/examples/development/) | HTTP, MinIO, and SMTP binding examples that require endpoints not supplied by this stack | No |
| [`components/integration/`](./docker/config/components/integration/) | Integration templates containing environment-specific placeholders | No |

Configure an example or integration template for its target environment before copying it into the mounted development directory or mounting a separate resources directory. Files outside `components/development/` are intentionally inert.

## Published ports

These are the host ports published by the uncommented services. Internal-only ports, including Dapr Placement and Scheduler, are not listed. Port `5000` must also remain available for the host application expected by `linqpad-dapr`.

| Service | Host port(s) | Purpose |
|---|---:|---|
| PlantUML | `8080` | Diagram server |
| Seq | `5341`, `15341` | Ingestion/API and UI |
| Alloy | `4317`, `4318`, `9999`, `12345` | OTLP gRPC, OTLP HTTP, Pyroscope SDK profiles, and Alloy UI |
| Pyroscope | `4040` | Profiling UI/API |
| Grafana | `3000` | Observability UI |
| Aspire Dashboard | `18888`, `18889`, `18890` | UI, OTLP gRPC, and OTLP HTTP |
| Redis | `6379` | Redis endpoint |
| Redis Insight | `16379` | Redis UI |
| RabbitMQ | `5672`, `15672` | AMQP and management UI |
| SQL Server | `1433` | Database endpoint |
| Durable Functions Monitor | `7072` | Monitor UI |
| LINQPad Dapr sidecar | `3500`, `50001` | Dapr HTTP and gRPC APIs |
