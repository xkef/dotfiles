# Run scripts inherit the PATH of the shell that ran chezmoi. On a fresh Mac
# that shell predates Homebrew, so the tools the packages script installed
# are invisible to every script after it, and a run_once script that finds
# nothing records itself as done. Put the install prefixes first.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
