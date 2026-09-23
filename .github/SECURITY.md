# Security policy

## Reporting a vulnerability

Report vulnerabilities through GitHub's private vulnerability reporting on
this repository:
<https://github.com/xkef/dotfiles/security/advisories/new>

Don't open a public issue for a security problem. One maintainer reads the
reports, so response times vary.

## Scope

This repository holds personal dotfiles and the scripts that install them.
Reports of interest:

- Install or update scripts (`install`, `dots`, mise tasks) that run
  untrusted input or fetch artifacts over insecure channels.
- Workflow or token-permission weaknesses in `.github/workflows/`.
- Secrets or credentials committed to the repository.

## Supported versions

Only the current state of `main` receives fixes. No releases or backports
exist.
