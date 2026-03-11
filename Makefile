DOTFILES := $(shell pwd)
STOW_PACKAGES := $(shell cat .stow-packages)

.PHONY: help install update test stow unstow restow fmt lint tools clean

help: ## Show this help
	@grep -E '^[a-z][a-z_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk -F ':.*## ' '{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Full install (packages + stow + tools)
	./install

install-adopt: ## Install, adopting existing files into the repo
	./install --adopt

update: ## Pull, re-stow, update plugins and tools
	dotfiles-update

test: ## Run smoke tests
	./test

stow: ## Stow all packages into ~
	@for pkg in $(STOW_PACKAGES); do \
		stow --dir=$(DOTFILES) -t $(HOME) $$pkg || true; \
	done

unstow: ## Remove all symlinks from ~
	@for pkg in $(STOW_PACKAGES); do \
		stow --dir=$(DOTFILES) -t $(HOME) -D $$pkg || true; \
	done

restow: ## Re-stow all packages (fixes stale symlinks)
	@for pkg in $(STOW_PACKAGES); do \
		stow --dir=$(DOTFILES) -t $(HOME) -R $$pkg || true; \
	done

tools: ## Install mise tools (languages + formatters)
	mise install

fmt: ## Format all dotfiles
	stylua nvim/.config/nvim/
	shfmt -w install test install-bins.sh local/.local/bin/*
	prettier --write '**/*.{json,yaml,yml,toml,css,html,md}' \
		--ignore-path .gitignore 2>/dev/null || true

lint: ## Lint shell scripts and neovim config
	@printf '\n  Linting...\n\n'
	@shellcheck -S warning install test install-bins.sh \
		local/.local/bin/dotfiles-update local/.local/bin/theme \
		tmux/.local/bin/tmux-sessionizer tmux/.local/bin/tmux-sysstat
	@nvim --headless +"lua require('lazy')" +qa
	@printf '\n  All clean\n\n'

clean: ## Remove caches and generated files
	find . -name .DS_Store -delete 2>/dev/null || true
	rm -rf nvim/.config/nvim/.luarc.json
