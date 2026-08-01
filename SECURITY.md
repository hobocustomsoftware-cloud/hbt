# Security Policy — HoBo Transport Platform

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x (MVP) | ✅ Active development |
| < 1.0 | ❌ Pre-release |

## Reporting a Vulnerability

We take security seriously. If you discover a vulnerability in HBT:

1. **DO NOT** open a public GitHub issue.
2. **DO NOT** post about it in public forums.
3. Send details to **security@hoboplatform.com** (PGP key below).
4. Include: affected version, vulnerability type, steps to reproduce, and (optional) proposed fix.

**Response SLA:**
- Acknowledgment: within 48 hours
- Initial assessment: within 5 business days
- Fix timeline: communicated after assessment

## PGP Key

```
-----BEGIN PGP PUBLIC KEY BLOCK-----

[PASTE YOUR PGP PUBLIC KEY HERE]

-----END PGP PUBLIC KEY BLOCK-----
```

## Scope

In scope:
- HBT Django backend (`apps/*`)
- HBT Flutter mobile application (`lib/*`)
- CI/CD pipeline (`.github/workflows/`)
- Infrastructure configurations (`devops/`, `docker/`)

Out of scope:
- Third-party dependencies (report via their respective maintainers)
- Infrastructure not owned by HoBo Platform (cloud provider, DNS, etc.)

## Security Practices

- All code changes undergo automated SAST (bandit, semgrep) before merge
- Dependencies are scanned for known vulnerabilities (pip-audit) in CI
- Database secrets are encrypted at rest
- API access requires JWT authentication with refresh rotation
- Rate limiting enforced on all API endpoints
- Production deployments require signed commits and 2FA
