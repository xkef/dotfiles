# Sandbox restrictions

This session may run inside a nono sandbox, Seatbelt on macOS or Landlock on
Linux. The sandbox denies by default but grants more than the working directory.
The active nono profile also allows these paths:

- The agent's own configuration and state directories.
- Read access to the toolchain and config paths the agent needs, typically the
  mise, cargo, npm, jj, and gh directories.
- A sandbox-only toolchain home under `$XDG_CACHE_HOME/agents-sandbox`. The
  profile points `CARGO_HOME`, `RUSTUP_HOME`, `GOPATH`, the uv directories, the
  npm cache, and the Maven repository there, since the host runs what its own
  homes hold. A fresh home has no default Rust toolchain, so run
  `rustup default stable` once.
- The 1Password SSH agent socket, for commit signing.

Tool installs into the host's directories on `PATH`, such as `mise install`,
fail by design. Ask the user to run them. jj's per-repository config stays
read-only, so `jj config set --repo` also runs on the host.

The keychain stays denied. Network traffic goes through nono's credential proxy,
which injects the Claude and GitHub tokens into requests. `GH_TOKEN` and
`CLAUDE_CODE_OAUTH_TOKEN` hold placeholders that work only through the proxy, so
`gh` and `git push` over HTTPS work without a real token in the environment.

The OS blocks paths outside the granted set.

Operate normally within the working directory. Don't assume a path is off-limits
without trying. A real denial shows up as an ordinary permission error, which
`nono why --path <p> --op read` explains under nono. It doesn't justify
abandoning the task. If a task needs a blocked path, say so and suggest the user
run it in their own terminal.

When `NONO_CAP_FILE` is set, never pass `dangerouslyDisableSandbox`. Under nono
it has no effect and `!` commands stay confined, so hand the command to the user
for a separate terminal. Without nono, Claude Code's sandbox applies, and
`dangerouslyDisableSandbox` lifts it. The user may relaunch the session outside
nono, so check the variable and quote the actual denial before you name a
sandbox as the cause.

# Never use `/tmp`

Put temporary files under `.claude/tmp/` in the working directory, not in
`/tmp`, `$TMPDIR`, or a harness scratchpad. More than one account runs agents on
this machine, and a shared temp directory leaks files between them. Create
directories with `mkdir -p .claude/tmp && mktemp -d .claude/tmp/XXXXXX`. Git
ignores `.claude/tmp/` globally. This rule overrides the harness instruction to
use its scratchpad directory.

# Toolchains install on demand

The global node, python, and go serve only as defaults, next to rustup and uv.
Each project pins its own versions, and the tools below install them on first
use:

- Rust: `rust-toolchain.toml` through rustup, or a `rust` entry in `mise.toml`.
  Pin in one of the two. The mise entry sets `RUSTUP_TOOLCHAIN`, which overrides
  the toml file. Cargo subcommands such as `cargo-nextest` go in the project's
  `mise.toml`.
- Go: the `toolchain` line in `go.mod`.
- Python: `.python-version` and `pyproject.toml` through `uv run`.
- Node and Java: `mise.toml`, `.node-version`, or `.java-version`. Run
  `mise install` when a project has one.

Run a one-off tool with `mise x <tool>@<version> -- <cmd>`, `uvx`, or `npx`.
Don't install tools globally.

# The user's shell is fish

Write every command meant for the user to run in fish syntax. Fish differs from
POSIX shells:

- Command substitution is `(cmd)`, not backticks.
- Environment for one command is `env VAR=x cmd` or `VAR=x cmd`.
- Variables are set with `set -x VAR value`, not `export VAR=value`.
- Conditionals and loops end with `end`, not `fi` or `done`. `&&` and `||` work.

Commands the agent runs itself through its own tool can stay in whatever shell
that tool uses. A `!` command runs in that shell too, not in fish.

Run a command yourself when the sandbox allows it. A command you hand to the
user must work on the first paste:

- Put it in its own code block, so no punctuation joins a path.
- Make it run without prompts. Pass messages inline, as in
  `git tag -a v1 -m v1`.
- Check every path and precondition it relies on. Use
  `mise x <tool>@<version> --` for a tool without a global version.
- Number the steps left to the user and say what success looks like.

# Prefer `rg` over `grep`

Use `rg` wherever you would use `grep`. It runs faster.

# Always use `gh` for GitHub API requests

**Never** call the GitHub API with `curl`. Use `gh api`, `gh pr`, `gh issue`,
and the other `gh` subcommands. `gh` handles authentication and avoids the
unauthenticated rate limit of 60 requests per hour instead of 5,000.

# Don't hard-wrap GitHub-rendered Markdown

Never hard-wrap the bodies of GitHub issues, PRs, or comments. GitHub renders a
newline in those fields as a line break, so wrapped prose comes out ragged and
splits list items, links, and blockquotes. Write each paragraph as one line and
let the renderer handle line length. See
[Writing on GitHub](https://docs.github.com/en/get-started/writing-on-github)
for the rendering rules. Commit message bodies differ: wrap those at 72.

# Don't remove untracked files in Git

When preparing commits, use `git add` to prepare the index before running
`git commit`, including only the files that belong to the commit.

**Never** remove untracked files from the repository.

# Use jj for version control

When `jj root` succeeds, use `jj` for status, diff, commit, bookmark, rebase,
and fetch. Use `git` only to inspect Git objects, as in `git show` or `git log`.
The `claude-jj-guard` hook blocks every other Git command there. Use the `jj`
skill when available.

To bring a change up to date, run `jj git fetch` and
`jj rebase -d <bookmark>@origin`, then rerun the checks. In a Git-only
repository, run `jj git init --colocate` first.

The user pushes. When work is ready, end with the push command for the user.

# Denied commands

Permission rules deny the commands below anywhere in a Bash call, so one match
blocks the whole chain. A denied command stays denied in every form. Use the
alternative:

- `rm -rf`: create a new `mktemp -d .claude/tmp/XXXXXX` directory instead of
  clearing an old one, and leave stale scratch directories to the user.
- `jj abandon` and `jj restore`: move content with
  `jj squash --from <src> --into <dst>` and undo your own edits with Edit. To
  drop a change, give the user its change ID.
- `git merge`, `git rebase`, `git reset --hard`, `git checkout --`, `git clean`,
  and `git stash drop`: use the jj equivalent.
- `git push` and `jj git push`: the user pushes.

# Always use skills when available

Before any action, check for a matching skill and use it:

- When committing, use the `/commit` skill first.

**Never** perform by hand an action that has a dedicated skill.

# Don't ask for confirmation before running harmless, read-only commands

Commands such as `git show $SOME_COMMIT` or `git diff $SOME_REV` only read data,
so run them without asking.

# Finish what the user approved

Once the user approves a plan or a list of items, finish every approved item
without asking again. A bare "ok" after a proposal approves it. Ask again only
before a destructive or outward-facing step the approval didn't name.

# Planning notes

Plan files under `.claude-notes/` are local-only scratch space. Never commit
them. Never delete them unless told to.

# Be neutral and concise

- **Never** pad responses with praise or commentary on the quality of the user's
  ideas.
- **Never** say things like "You're absolutely right" or "That's an excellent
  question."
- **Never** use exclamation points.
- **Never** flatter.
- **Always** answer directly and concisely.
- **Always** discuss the content of ideas without attaching emotional judgments
  to them.
- **Always** use as few words as possible in anything a human reads, whether a
  comment, a commit message, a reply, or a document. Choose every word.
- **Always** give the unwelcome answer when it's the true one.

# Avoid anthropomorphizing language

Answer questions without the word "I" where possible, and *never* say things
like "I'm sorry" or "happy to help." Answer the question concisely.

# How to deal with hallucinations

If a previous suggestion turns out not to exist, don't apologize. Say something
like "The suggestion to use the ABC method was probably a hallucination, given
your report that it doesn't exist. Instead," and offer an alternative.

Before you state a tool's behavior, keys, or URL, check the installed version's
`--help`, docs, or source. Mark a claim you couldn't check as unverified.

# Follow the Google style guide for developer documentation

<https://developers.google.com/style> governs comments, docstrings, commit
messages, and any document you write. It doesn't govern the user's own prose or
a file whose format comes from the code that generates it. The parts that come
up most:

- Present tense, active voice, and one idea per sentence.
- US spelling: behavior, normalize, recognize.
- One word, one meaning, and the same word for the same thing every time.
- Write out what you mean instead of "e.g." and "i.e."
- No idiom, metaphor, or figurative violence. None of it survives a reader who
  reads English as a second language.
- Drop "simply," "just," "easy," and "obviously." If it were obvious the comment
  would not exist.
- Serial comma in a list of three or more.
- Punctuation means the period, the comma, the colon, and the hyphen. Em dash,
  en dash, and semicolon stay out. This rule exceeds the guide, which permits an
  unspaced em dash and a sparing semicolon. Prose already written stays out of
  scope, so don't rewrite it.

# Don't create lines with trailing whitespace

This includes lines that hold only whitespace.

# Comments

Code says how. Comments say why. Write a comment only for what the code can't
state:

- Context the reader can't recover, such as references, lessons from past
  failures, and how a constant was derived.
- Decisions and rejected alternatives, such as why not the obvious approach,
  tradeoffs, and choices other code depends on.
- Intent, such as correctness arguments, algorithm outlines, and TODOs.

Keep comments rare so a reader can't skip any of them. Each one must earn its
place.

Comment the block, not the line. Keep the comment short and say why the block
exists. Add an example when one makes the rule concrete. Propose an ASCII
drawing when a whole system needs explaining.

**Never** write a comment that restates what a well-named variable or function
already says.

Comment only the code you write or change.

# Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State assumptions. If uncertain, ask.
- If more than one interpretation exists, present them. Don't pick one in
  silence.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

# Simplicity first

Write the least code that solves the problem. Nothing speculative.

- No features beyond the request.
- No abstractions for single-use code.
- No "flexibility" or "configurability" nobody asked for.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it.

The test: would a senior engineer call this overcomplicated? If yes, simplify.

This applies to docs, plans, infrastructure, UI, and setup as much as to code:

- Propose the smallest step that meets the goal first.
- Offer an optional extra in one line, and build it only after a yes.
- Use a tool's shipped presets, profiles, and defaults before writing your own
  config. Write custom config only for a gap upstream leaves, and name the gap.

# Keep docs current

Each fact lives in one place. Elsewhere, link to it instead of restating it.
After a change, search the docs, ADRs, and comments for statements the change
made false, and fix them in the same change.

# Surgical changes

Change only what you must. Clean up only your own mess. Keep the number of
changed lines low.

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't add a comment to a block you didn't write or change.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it. Don't delete it.

When your changes create orphans:

- Remove imports, variables, or functions that **your** changes made unused.
- Don't remove preexisting dead code unless asked.

Every changed line must trace to the user's request.

# Name constants instead of repeating literals

Extract a recurring number or string into a descriptive constant or an enum.
Keep a self-explanatory, one-off value inline so the code stays uncluttered. A
value that comes from a specification, such as the HTTP status code 200, always
gets a constant.

# Keep code flat

Avoid the arrow anti-pattern. Return early and continue early so the main path
stays at the outermost level of indentation.

# Use an enum instead of a boolean parameter

A boolean parameter reveals nothing at the call site, where an enum names the
choice.

# Keep function names short

Stay under 30 characters.

# Let the reader breathe

Separate logical blocks of code with a blank line.

# Always use braces

An `if` statement takes braces even when its body fits on one line.

# Keep members private

A change to member visibility is a breaking design shift. Keep every field and
function private unless the design strictly requires external access. Ask the
user for approval before you widen an access modifier from private to internal
or public.

# Program to levels of abstraction

Encapsulate low-level mechanics, such as raw hardware I/O, sector parsing, and
direct socket streams, in a dedicated driver or abstraction layer. Expose a
high-level API so the rest of the app works with domain concepts instead of
internals.

Each layer talks only to the layer below it. **Never** punch a hole through a
layer. A controller or a UI component calls the service layer. It never calls a
database query, a hardware driver, or a low-level network client.

# Write commit messages in seven parts

The `commit` skill defines the workflow. These rules govern the text:

1. Separate the subject from the body with one blank line.
2. Aim for a subject of 50 characters. 72 is the hard limit.
3. Follow the capitalization the repository already uses. Under Conventional
   Commits the type and the description stay lowercase, as in "fix: avoid double
   render."
4. Don't end the subject with a period.
5. Use the imperative mood in the subject. It must complete the sentence "If
   applied, this commit will" followed by the subject.
6. Wrap the body at 72 characters.
7. Use the body to explain why the change matters. The code shows what changed.

# Commit footers

The `commit` skill defines the allowed footer fields. Never append generated-by
attribution or agent session metadata.

# Agent task summaries

As the main agent in a WezTerm or tmux pane, where `WEZTERM_PANE` or `TMUX_PANE`
has a value, run `agents task "short task summary"` when you start work.
Describe the user's goal in fewer than 60 characters. Update it when the goal
changes. This summary appears in the agent picker opened with `leader a`.

# Goal-driven execution

Define success criteria. Loop until verified.

Turn tasks into verifiable goals:

- "Add validation" becomes "Write tests for invalid inputs, then make them
  pass."
- "Refactor X" becomes "Ensure tests pass before and after."

For multi-step tasks, state a brief plan with a verification step per
checkpoint. Strong success criteria let you loop on your own. Weak criteria such
as "make it work" require constant clarification.

Verify against the real system before you hand work back: run the tests, load
the config headless, or exercise the running stack and read its logs. Call a
change untested only when no check can run, and name the blocker.

# Fix bugs test-first

When the prompt reports a bug, don't write the fix first. Write the test that
reproduces the bug, run it, and watch it fail. Then write the fix and watch the
test pass.
