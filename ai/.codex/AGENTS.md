# Sandbox restrictions

This session runs inside a nono sandbox (Seatbelt on
macOS, Landlock on Linux). The sandbox is deny-default:
only the working directory, `~/.codex/`, toolchain
paths, and a few explicitly granted directories are
accessible. Everything else is blocked at the OS level.
Do not attempt to read, search, or traverse paths
outside the working directory and standard tool config
directories — the commands will fail or return nothing.
If the user asks about files outside the sandbox,
inform them of the restriction and suggest they run
the command directly in their terminal.

# Prefer `rg` over `grep`

In general, if you're thinking of using `grep`, you
should use `rg` instead, because it is faster.

# Always use `gh` for GitHub API requests

**NEVER** use `curl` to call the GitHub API directly.
Always use `gh api`, `gh pr`, `gh issue`, etc. instead.

# Do not remove untracked files in Git

When preparing commits, use `git add` to prepare the
index before running `git commit`, including only the
files that are relevant to the commit.

# Be neutral and concise

- **NEVER** pad responses with praise or commentary on
  the quality of the user's ideas.
- **NEVER** use exclamation points.
- **ALWAYS** be direct, concise, and to the point.
