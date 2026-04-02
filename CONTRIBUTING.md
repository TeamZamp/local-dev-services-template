# Contributing

Thank you for contributing to this project.

The goal of this repository is to stay small, practical, and reliable for local development workflows. Good contributions improve usability, keep behavior predictable, and preserve a clean onboarding experience for new users.

## Ways To Contribute

- report bugs
- improve documentation
- add support for new local services
- tighten tests and CI
- refine the Bash CLI without making it harder to understand

## Development Standards

Please keep contributions aligned with these expectations:

- prefer simple, readable Bash over clever Bash
- keep service names consistent across compose, script, and docs
- update tests when behavior changes
- update documentation whenever user-facing behavior changes
- avoid breaking existing service selections unless necessary

## Local Setup

Clone the repository and move into the project directory:

```bash
git clone https://github.com/TeamZamp/local-dev-services-template.git
cd local-dev-services-template
```

Make the CLI executable if needed:

```bash
chmod +x start.sh
chmod +x stop.sh
chmod +x tests/test_start.sh
```

## Before Opening a Pull Request

Run the same checks used in CI:

### 1. Validate Docker Compose

```bash
docker compose -f docker-compose.yml config
```

### 2. Run ShellCheck

```bash
shellcheck start.sh stop.sh tests/test_start.sh
```

### 3. Run Bash syntax checks

```bash
bash -n start.sh stop.sh tests/test_start.sh
```

### 4. Run functional tests

```bash
bash tests/test_start.sh
```

## Branching

The CI workflow runs for:

- `main`
- `staging`

Recommended flow:

1. Create a feature branch from `staging`
2. Make your changes
3. Run local checks
4. Open a pull request into `staging`
5. Promote tested changes from `staging` to `main`

## Pull Request Expectations

Every pull request should:

- explain what changed
- explain why it changed
- mention any new services, ports, or environment variables
- include documentation updates when needed
- pass CI

## Adding a New Service

When adding a service, update all of the following:

1. `docker-compose.yml`
2. `start.sh`
3. `stop.sh`
4. `README.md`
5. `tests/test_start.sh` if behavior or output changes

Checklist:

- service uses default or documented ports
- service uses a named volume for persistence
- menu numbering stays clear
- connection string is documented
- compose configuration remains valid

## Code Review Guidelines

Reviewers will usually look for:

- correctness
- readability
- backward compatibility
- documentation quality
- test coverage for behavior changes

## CI Enforcement

This repository includes a GitHub Actions workflow that validates:

- Docker Compose configuration
- ShellCheck linting
- Bash syntax
- functional test behavior

To fully enforce merge safety, enable required status checks in GitHub branch protection for `main` and `staging`.

## Reporting Issues

When reporting a bug, please include:

- operating system
- Bash version if relevant
- Docker version
- the exact command or input used
- the observed output
- the expected behavior

## License

If you plan to keep the repository open source, add a license file such as `LICENSE` with an SPDX-recognized license before wider distribution.
