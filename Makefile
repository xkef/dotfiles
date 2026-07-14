TRACKED_FILES := $(shell git ls-files)
TRACKED_TEXT_FILES := $(filter-out %.png %.jpg %.jpeg %.gif %.webp,$(TRACKED_FILES))
SHELL_FILES := $(shell awk 'FNR == 1 && /^\#!.*(env[[:space:]]+bash|\/bash|\/sh)([[:space:]]|$$)/ { print FILENAME }' $(TRACKED_TEXT_FILES) 2>/dev/null)
FISH_FILES := $(filter %.fish,$(TRACKED_FILES))

.PHONY: help fmt lint lint-sh lint-fish lint-md lint-nvim check clean

help: ## Show this help
	@rg -N '^[a-z][a-z_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk -F ':.*## ' '{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

fmt: ## Format all dotfiles
	stylua home/dot_config/lazyvim/ home/dot_config/kickstart/
	shfmt -w $(SHELL_FILES)
	fish_indent -w $(FISH_FILES)
	prettier --write '**/*.{json,yaml,yml,css,html}' \
		--ignore-path .gitignore 2>/dev/null || true
	dprint fmt
	taplo fmt

lint: lint-sh lint-fish lint-md lint-nvim ## Lint everything

lint-sh: ## Shellcheck bash scripts
	shellcheck -S warning $(SHELL_FILES)

lint-fish: ## Syntax-check fish files
	@for f in $(FISH_FILES); do fish --no-execute $$f || exit 1; done

lint-md: ## Lint markdown
	rumdl check

lint-nvim: ## Load LazyVim headless (local only; needs plugins)
	NVIM_APPNAME=lazyvim nvim --headless +"lua require('lazy')" +qa

check: ## Apply the source tree into a throwaway HOME and assert results
	@tmp=$$(mktemp -d); \
	cleanup() { rm -rf "$$tmp"; }; \
	trap cleanup EXIT; \
	mkdir -p "$$tmp/home"; \
	chezmoi init --source . --destination "$$tmp/home" \
		--config "$$tmp/chezmoi.toml" --persistent-state "$$tmp/state.db" \
		--promptBool "work machine (render 1Password git identity)=false" \
		--exclude scripts --apply || exit 1; \
	for path in \
		.local/bin/theme \
		.local/bin/dots-keys \
		.local/bin/macos-defaults \
		.config/theme.d/ghostty.fish \
		.config/fish/config.fish \
		.config/tmux/tmux.conf \
		.config/git/config \
		.config/lazyvim/init.lua \
		.config/ghostty/config \
		.claude/CLAUDE.md; do \
		if [ ! -e "$$tmp/home/$$path" ]; then \
			echo "missing $$path"; \
			exit 1; \
		fi; \
	done; \
	test -x "$$tmp/home/.local/bin/theme" || { echo "theme not executable"; exit 1; }; \
	test ! -e "$$tmp/home/.config/git/config.work" || { echo "unexpected config.work"; exit 1; }; \
	chezmoi verify --source . --destination "$$tmp/home" \
		--config "$$tmp/chezmoi.toml" --persistent-state "$$tmp/state.db" \
		--exclude scripts || exit 1; \
	echo "chezmoi smoke ok"

clean: ## Remove caches and generated files
	find . -name .DS_Store -delete 2>/dev/null || true
	rm -rf home/dot_config/lazyvim/.luarc.json
