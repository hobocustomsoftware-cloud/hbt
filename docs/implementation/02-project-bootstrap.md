# AI Prompt — Repository and Project Bootstrap Specification

Act as a staff platform engineer, Django lead, Flutter lead, DevOps engineer, and developer-experience specialist.

Create an executable **Repository and Project Bootstrap Specification** for HBT.

## Specify

- Canonical repository tree and ownership
- Python and Flutter version pinning
- Dependency-management files and update policy
- Django settings layout
- Environment names and configuration precedence
- `.env.example` variables with descriptions and safe sample values
- Local PostgreSQL, Redis, MinIO, worker, and Nginx services
- Docker and Docker Compose layout
- Makefile or task-runner commands
- Formatting, linting, type checking, testing, and security scanning
- Pre-commit hooks
- Database creation, migration, and seed commands
- Flutter flavors and platform configuration
- CI workflow stages and required checks
- Health checks and startup dependency behavior
- First-run and troubleshooting instructions

Provide a file-by-file creation checklist, command contract, validation checklist, and expected output. Never include real secrets. Clearly distinguish required bootstrap work from future production infrastructure.
