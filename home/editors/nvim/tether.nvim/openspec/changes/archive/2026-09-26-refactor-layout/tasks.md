# Tasks

## 1. Layout

- [x] 1.1 Move modules into `core/`, `ui/`, and `features/<name>/internal/`
- [x] 1.2 `core/registry` and `core/bus`; UI reads contributions from the
      registry
- [x] 1.3 `core/store` for review state; `core/vcs` split into jj and Git
      backends
- [x] 1.4 Features reach the core only through `tether.api`
- [x] 1.5 Tests: the existing suite unchanged, plus the layering test
