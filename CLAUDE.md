# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build executable JAR (output: build/libs/configservice.jar)
./gradlew bootJar

# Run all tests
./gradlew test

# Run a single test class
./gradlew test --tests "com.acenexus.tata.configservice.SecurityTests"
./gradlew test --tests "com.acenexus.tata.configservice.ActuatorHealthTests"

# Full build (compile + test + jar)
./gradlew build
```

Tests run without RabbitMQ — the test `application.yml` disables `RabbitAutoConfiguration` and Spring Cloud Bus.

To run locally, set these environment variables before starting via IntelliJ or `./gradlew bootRun`:

```
SECURITY_USERNAME=admin
SECURITY_PASSWORD=password
ENCRYPT_KEY=my-secret-key
RABBITMQ_USER=admin
RABBITMQ_PASS=password
```

Service starts on port `8888` (default; `SERVER_PORT` to override). Verify: `http://localhost:8888/actuator/health`

## Architecture

This is a **Spring Cloud Config Server** — the centralized configuration hub for the AceNexus microservice ecosystem. The application layer itself is intentionally minimal: only two source files exist (`ConfigserviceApplication.java` with `@EnableConfigServer`, and `SecurityConfig.java`). All behavior comes from Spring Cloud Config Server auto-configuration.

**Configuration storage**: Config files live in the `configs/` directory of this Git repository, named `{application}-{profile}.yml` (e.g., `gatewayservice-prod.yml`). Currently only `prod` profiles exist — `local` profiles are not needed because client services disable the config server when running locally. On startup the server serves these files via REST to client microservices.

**Dynamic refresh flow**: When configs change, `POST /actuator/busrefresh` publishes a refresh event to RabbitMQ. All subscribed microservices receive the event, re-fetch their config from this server, and rebind `@RefreshScope` beans — no restarts required.

**Security**: `SecurityConfig.java` permits `/actuator/health` without auth; all other endpoints (including `/{application}/{profile}`, `/encrypt`, `/decrypt`, `/actuator/busrefresh`) require HTTP Basic Auth.

**JCE encryption**: Values prefixed with `{cipher}` in config files are automatically decrypted before being served to clients. The symmetric key is `ENCRYPT_KEY`.

**Distributed tracing**: Includes Micrometer OTel bridge + OTLP exporter. In prod, traces are sent to Tempo at the endpoint configured by `MANAGEMENT_OTLP_TRACING_ENDPOINT` (default: `http://tempo:4318/v1/traces`).

**Versioning**: `build.gradle.kts` derives the version from the latest git tag (`git describe --tags --abbrev=0`). Falls back to `0.0.1-SNAPSHOT` when no tag exists.

## Deployment

Deployed to **Kubernetes** (namespace: `acenexus`) via CI/CD:

- **CI**: GitHub Actions (`.github/workflows/ci.yml`) triggers on push / PR to `main`
  - test job: `./gradlew build` (compile + test)
  - release job: `./gradlew bootJar` → `docker build` → Trivy scan → push `ghcr.io/acenexus/configservice:<sha>` to GHCR → update `AceNexus/deploy` k8s/configservice/deployment.yaml image tag
- **CD**: ArgoCD detects deploy repo change → `kubectl apply` → rolling update

K8s manifests and operation guide: `AceNexus/deploy` repo → `k8s/configservice/` and `README.md`.

## Commit Message Format

```
[type] Chinese description
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `config`
