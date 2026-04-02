# local-dev-services-template

Open source tooling for spinning up local development databases with Docker Compose through a small Bash CLI.

This project is designed for teams that want a lightweight, repeatable way to start only the databases they need during development, while keeping persistence, onboarding, and CI validation straightforward.

Repository URL: `https://github.com/TeamZamp/local-dev-services-template`

## Highlights

- Interactive Bash CLI for starting selected services
- Interactive Bash CLI for stopping selected services
- Docker Compose-based local infrastructure
- Persistent named volumes for all databases
- Support for multiple selections in one command
- Input validation with helpful error messages
- Open source-friendly repository structure
- CI pipeline for `main` and `staging`

## Supported Services

| Service | Port(s) | Default Connection |
| --- | --- | --- |
| MongoDB | `27017` | `mongodb://localhost:27017` |
| PostgreSQL | `5432` | `postgresql://postgres:postgres@localhost:5432/app` |
| Redis | `6379` | `redis://localhost:6379` |
| Neo4j | `7474`, `7687` | `neo4j://localhost:7687` |

## Repository Structure

```text
.
|-- .github/
|   `-- workflows/
|       `-- ci.yml
|-- docker-compose.yml
|-- start.sh
|-- stop.sh
|-- tests/
|   `-- test_start.sh
`-- CONTRIBUTING.md
```

## Requirements

- Docker
- Docker Compose
- Bash 4+

## Quick Start

Clone the repository:

```bash
git clone https://github.com/TeamZamp/local-dev-services-template.git
cd local-dev-services-template
```

Make the CLI executable:

```bash
chmod +x start.sh
chmod +x stop.sh
```

Run the tool:

```bash
./start.sh
```

Stop selected services:

```bash
./stop.sh
```

Choose one or more services using comma-separated menu numbers:

```text
1,2,4
```

The script will:

1. Verify Docker access
2. Show available services
3. Ignore invalid selections
4. Start only the selected services
5. Print the matching connection strings

## Docker Access

If Docker is installed but not accessible to the current user, the script exits with:

```bash
Run: sudo usermod -aG docker $USER && newgrp docker
```

## Usage Example

```text
Select services to start:
1. mongo
2. postgres
3. redis
4. neo4j
Enter service numbers (comma-separated): 1,3
```

Expected result:

- Starts `mongo` and `redis`
- Prints their connection strings

## Development Workflow

### Start selected services

```bash
./start.sh
```

### Stop selected services

```bash
./stop.sh
```

### Validate the Compose file locally

```bash
docker compose -f docker-compose.yml config
```

### Run shell syntax checks

```bash
bash -n start.sh tests/test_start.sh
bash -n stop.sh
```

### Run functional tests

```bash
bash tests/test_start.sh
```

### Run ShellCheck locally

If you have ShellCheck installed:

```bash
shellcheck start.sh tests/test_start.sh
shellcheck stop.sh
```

## How To Add a New Service

Adding a service requires changes in three places:

1. `docker-compose.yml`
2. `start.sh`
3. `stop.sh`
4. `README.md`

### 1. Define the service in `docker-compose.yml`

Every service should include:

- a stable service name
- the container image
- default port mappings where possible
- a named volume for persistence
- required environment variables

Example:

```yaml
  mysql:
    image: mysql:8
    container_name: local-mysql
    environment:
      MYSQL_DATABASE: app
      MYSQL_USER: mysql
      MYSQL_PASSWORD: mysql
      MYSQL_ROOT_PASSWORD: root
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
```

Add the volume under `volumes:`:

```yaml
  mysql_data:
```

### 2. Register the service in `start.sh`

Add a menu mapping:

```bash
declare -A SERVICE_MAP=(
  [1]="mongo"
  [2]="postgres"
  [3]="redis"
  [4]="neo4j"
  [5]="mysql"
)
```

Add the connection URL:

```bash
declare -A CONNECTION_URLS=(
  [mongo]="mongodb://localhost:27017"
  [postgres]="postgresql://postgres:postgres@localhost:5432/app"
  [redis]="redis://localhost:6379"
  [neo4j]="neo4j://localhost:7687"
  [mysql]="mysql://mysql:mysql@localhost:3306/app"
)
```

Update the interactive menu:

```bash
echo "5. mysql"
```

### 3. Document the service

When adding a new service, update:

- the supported services table
- example connection strings
- any setup notes specific to that service

### 4. Extend tests when behavior changes

If your service changes selection logic, startup commands, or connection output, update `tests/test_start.sh` so CI continues to verify the expected behavior.

## CI/CD

GitHub Actions is configured in [.github/workflows/ci.yml](C:\Users\ravi8\Desktop\cambodiaagricue\Devservice\.github\workflows\ci.yml).

The pipeline runs on:

- pushes to `main`
- pushes to `staging`
- pull requests targeting `main`
- pull requests targeting `staging`

Checks included:

1. Docker Compose validation
2. ShellCheck linting
3. Bash syntax validation
4. Functional test execution

### Merge Protection Recommendation

To make sure changes are only merged when the project is linted, valid, and functional, enable GitHub branch protection for:

- `main`
- `staging`

Then mark the CI workflow status check as required before merge.

That repository setting is what enforces merge blocking; the workflow in this repo provides the required check itself.

## Open Source Contribution

This project is intended to stay simple, dependable, and easy to extend.

Contributors should aim for:

- readable Bash
- minimal surprises in local developer experience
- clear documentation updates with code changes
- passing CI before review

See [CONTRIBUTING.md](C:\Users\ravi8\Desktop\cambodiaagricue\Devservice\CONTRIBUTING.md) for contribution guidelines.

## Repository

- Name: `local-dev-services-template`
- Git URL: `https://github.com/TeamZamp/local-dev-services-template`

## Troubleshooting

### Docker is not accessible

Run:

```bash
sudo usermod -aG docker $USER && newgrp docker
```

Then retry the script.

### A selection number does not work

Make sure the service is registered in:

- `docker-compose.yml`
- `SERVICE_MAP` in `start.sh`
- `CONNECTION_URLS` in `start.sh`
- `SERVICE_MAP` in `stop.sh`

### CI fails on a shell change

Run locally:

```bash
shellcheck start.sh stop.sh tests/test_start.sh
bash -n start.sh stop.sh tests/test_start.sh
bash tests/test_start.sh
```

## Roadmap Ideas

- add `status.sh` for service health checks
- support environment-specific overrides
- support optional `.env` configuration
