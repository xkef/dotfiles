DOTFILES_DIR := $(shell pwd)
# Top-level dirs that are NOT stow packages (repo assets, docs, …).
# Keep in sync with STOW_IGNORE in the install script.
STOW_IGNORE := docs
STOW_PACKAGES := $(filter-out $(STOW_IGNORE),$(patsubst %/,%,$(wildcard */)))
SHELL_FILES := $(shell git ls-files '*.sh' '*.bash' install macos-defaults 2>/dev/null)
FISH_FILES := $(shell git ls-files '*.fish' 'local/.local/bin/vm' 'local/.local/bin/dots-*' 2>/dev/null)

define stow_each
	@for pkg in $(STOW_PACKAGES); do \
		stow --dir=$(DOTFILES_DIR) -t $(HOME) $(1) $$pkg || true; \
	done
endef

.PHONY: help install update doctor test stow unstow restow fmt lint tools macos-defaults ai-render uninstall clean

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

test: doctor ## Alias for doctor

stow: ## Stow all packages into ~
	$(call stow_each)

unstow: ## Remove all symlinks from ~
	$(call stow_each,-D)

restow: ## Re-stow all packages (fixes stale symlinks)
	$(call stow_each,-R)

tools: ## Install mise tools (languages + formatters)
	mise install

fmt: ai-render ## Format all dotfiles
	stylua nvim/.config/lazyvim/ nvim/.config/kickstart/
	shfmt -w $(SHELL_FILES)
	fish_indent -w $(FISH_FILES)
	prettier --write '**/*.{json,yaml,yml,css,html,md}' \
		--ignore-path .gitignore 2>/dev/null || true
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
