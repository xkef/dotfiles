DOTFILES_DIR := $(shell pwd)
PACKAGE_MANIFEST := stow-packages
STOW_PACKAGES := $(shell sed 's/\#.*//; s/[[:space:]]*$$//; /^[[:space:]]*$$/d' $(PACKAGE_MANIFEST))
TRACKED_FILES := $(shell if [ -d .jj ] && command -v jj >/dev/null 2>&1; then jj --config signing.behavior=drop file list --no-pager 2>/dev/null || git ls-files 2>/dev/null; else git ls-files 2>/dev/null; fi)
TRACKED_TEXT_FILES := $(filter-out %.png %.jpg %.jpeg %.gif %.webp,$(TRACKED_FILES))
SHELL_FILES := $(shell awk 'FNR == 1 && /^\#!.*(env[[:space:]]+bash|\/bash|\/sh)([[:space:]]|$$)/ { print FILENAME }' $(TRACKED_TEXT_FILES) 2>/dev/null)
FISH_FILES := $(filter %.fish,$(TRACKED_FILES)) $(shell awk 'FNR == 1 && /^\#!.*(env[[:space:]]+fish|\/fish)([[:space:]]|$$)/ { print FILENAME }' $(TRACKED_TEXT_FILES) 2>/dev/null)

define stow_each
	@for pkg in $(STOW_PACKAGES); do \
		stow --dir=$(DOTFILES_DIR) -t $(HOME) $(1) $$pkg || true; \
	done
endef

.PHONY: help install update doctor test stow unstow restow stow-smoke fmt lint tools macos-defaults ai-render uninstall clean

help: ## Show this help
	@rg -N '^[a-z][a-z_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk -F ':.*## ' '{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Full install (packages + stow + tools)
	./install

install-adopt: ## Install, adopting existing files into the repo
	./install --adopt

update: ## Fetch/pull, re-stow, update plugins and tools
	dots update

doctor: ## Check dotfiles health (binaries, symlinks, configs)
	dots doctor

test: stow-smoke doctor ## Run smoke tests and doctor

stow: ## Stow all packages into ~
	$(call stow_each)

unstow: ## Remove all symlinks from ~
	$(call stow_each,-D)

restow: ## Re-stow all packages (fixes stale symlinks)
	$(call stow_each,-R)

stow-smoke: ## Stow all packages into a temporary HOME
	@tmp=$$(mktemp -d); \
	cleanup() { rm -rf "$$tmp"; }; \
	trap cleanup EXIT; \
	for pkg in $(STOW_PACKAGES); do \
		stow --dir=$(DOTFILES_DIR) -t "$$tmp" "$$pkg" || exit $$?; \
	done; \
	for path in \
		.local/bin/dots \
		.local/bin/theme \
		.config/fish/config.fish \
		.config/tmux/tmux.conf \
		.config/git/config \
		.config/lazyvim/init.lua \
		.config/ghostty/config; do \
		if [ ! -e "$$tmp/$$path" ]; then \
			echo "missing $$path"; \
			exit 1; \
		fi; \
	done; \
	if [ -e "$$tmp/.ideavimrc" ]; then \
		echo "unexpected .ideavimrc"; \
		exit 1; \
	fi; \
	echo "stow smoke ok"

tools: ## Install mise tools (languages + formatters)
	mise install

fmt: ai-render ## Format all dotfiles
	stylua nvim/.config/lazyvim/ nvim/.config/kickstart/ theme/.config/lazyvim/ vcs/.config/lazyvim/
	shfmt -w $(SHELL_FILES)
	fish_indent -w $(FISH_FILES)
	prettier --write '**/*.{json,yaml,yml,css,html,md}' \
		--ignore-path .gitignore \
		--ignore-path .prettierignore 2>/dev/null || true
	taplo fmt

lint: ## Lint shell scripts, neovim config, and markdown
	@printf '\n  Linting...\n\n'
	@shellcheck -S warning $(SHELL_FILES)
	@NVIM_APPNAME=lazyvim nvim --headless +"lua require('lazy')" +qa
	@markdownlint-cli2
	@printf '\n  All clean\n\n'

macos-defaults: ## Apply macOS system defaults
	./macos-defaults

ai-render: ## Regenerate per-tool AGENTS files from ai-shared/
	@DOTS_DIR=$(DOTFILES_DIR) ai/.local/bin/ai-agents-render

uninstall: unstow ## Remove all symlinks from ~ (alias for unstow)

clean: ## Remove caches and generated files
	find . -name .DS_Store -delete 2>/dev/null || true
	rm -rf nvim/.config/lazyvim/.luarc.json
