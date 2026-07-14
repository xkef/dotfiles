# Security policy

## Reporting a vulnerability

Report vulnerabilities privately through GitHub's private vulnerability
reporting on this repository:
<https://github.com/xkef/dotfiles/security/advisories/new>

Do not open a public issue for a security problem. Reports are
acknowledged on a best-effort basis; this is a single-maintainer
project.

## Scope

This repository holds personal dotfiles and the scripts that install
them. Reports of interest:

- Install or update scripts (`install`, `dots`, Makefile targets)
  executing untrusted input or fetching artifacts insecurely.
- Workflow or token-permission weaknesses in `.github/workflows/`.
- Secrets or credentials committed to the repository.

## Supported versions

Only the current state of `main` is supported. There are no releases
or backports.
