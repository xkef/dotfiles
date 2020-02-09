""
" @header
"
" @image https://raw.githubusercontent.com/wincent/vcs-jump/media/logo.png center

""
" @plugin vcs-jump vcs-jump plug-in for Vim
"
" # Intro
"
" This plug-in allows you to jump to useful places within a Git or Mercurial
" repository: diff hunks, merge conflicts, and "grep" results.
"
" The actual work is done by the included `vcs-jump` script, which is a Ruby
" port of the "git-jump" (shell) script from official Git repo, adapted to work
" transparently with either Git or Mercurial:
"
" https://git.kernel.org/pub/scm/git/git.git/tree/contrib/git-jump
"
" # Requirements
"
" - A Ruby interpreter must be available on the host system: the `vcs-jump`
"   script uses a "shebang" line of "/usr/bin/env ruby".
"
" # Installation
"
" To install vcs-jump, use your plug-in management system of choice.
"
" @footer
"
" # Website
"
" The official vcs-jump source code repo is at:
"
"   http://git.wincent.com/vcs-jump.git
"
" A mirror exists at:
"
"   https://github.com/wincent/vcs-jump
"
" Official releases are listed at:
"
"   http://www.vim.org/scripts/script.php?script_id=5790
"
"
" # License
"
" Copyright 2014-present Greg Hurrell. All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" 1. Redistributions of source code must retain the above copyright notice,
"    this list of conditions and the following disclaimer.
"
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
" LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
" CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
" SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
" INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
" CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
" POSSIBILITY OF SUCH DAMAGE.
"
"
" # Development
"
" ## Contributing patches
"
" Patches can be sent via mail to greg@hurrell.net, or as GitHub pull requests
" at: https://github.com/wincent/vcs-jump/pulls
"
" ## Cutting a new release
"
" At the moment the release process is manual:
"
" - Perform final sanity checks and manual testing
" - Update the |vcs-jump-history| section of the documentation
" - Verify clean work tree:
"
" ```
" git status
" ```
"
" - Tag the release:
"
" ```
" git tag -s -m "$VERSION release" $VERSION
" ```
"
" - Publish the code:
"
" ```
" git push origin master --follow-tags
" git push github master --follow-tags
" ```
"
" - Produce the release archive:
"
" ```
" git archive -o vcs-jump-$VERSION.zip HEAD -- .
" ```
"
" - Upload to http://www.vim.org/scripts/script.php?script_id=5790
"
"
" # Authors
"
" vcs-jump is written and maintained by Greg Hurrell <greg@hurrell.net>.
"
" Other contributors that have submitted patches include (in alphabetical
" order):
"
" - Pascal Lalancette
"
" # History
"
" ## master (not yet released)
"
" - Provide a meaningful title for the |quickfix| listing.
" - Run `git diff` with `--no-color` to prevent a `git config color.ui` setting
"   of "always" from breaking diff mode
"   (https://github.com/wincent/vcs-jump/issues/1)
"
" ## 0.1 (2 June 2019)
"
" - Initial release: originally extracted from my dotfiles in
"   https://wincent.com/n/vcs-jump-origin and then iterated on before extracting
"   into a standalone Vim plugin.
"

""
" @option g:VcsJumpLoaded any
"
" To prevent vcs-jump from being loaded, set |g:VcsJumpLoaded| to any value in
" your " |.vimrc|. For example:
"
" ```
" let g:VcsJumpLoaded=1
" ```
if exists('g:VcsJumpLoaded') || &compatible || v:version < 700
  finish
endif
let g:VcsJumpLoaded = 1

" Temporarily set 'cpoptions' to Vim default as per `:h use-cpo-save`.
let s:cpoptions = &cpoptions
set cpoptions&vim

""
" @command :VcsJump
"
" This command invokes the bundled `vcs-jump` script to get the list of
" "interesting" locations (diff hunks, merge conflicts, or grep results) in the
" repo, and put them in the |quickfix| list.
"
" Filename completion is available in the context of this command.
"
" Subcommands are:
"
" - "diff": Results are diff hunks. Arguments are passed on to the Mercurial or
"   Git `diff` invocation. This means that in the absence of any arguments, a
"   diff against the current "HEAD" will be performed, but you can change that
"   by passing options (eg. `--cached`) or specifying a target revision to
"   compare against.
" - "merge": Results are merge conflicts. Arguments are ignored.
" - "grep": Results are grep hits. Arguments are given to the underlying Git or
"   Mercurial `grep` command.
"
command! -nargs=+ -complete=file VcsJump call vcsjump#jump(<q-args>)

if !hasmapto('<Plug>(VcsJump)') && maparg('<Leader>d', 'n') ==# ''
  ""
  " @mapping <Plug>(VcsJump)
  "
  " This mapping invokes the bundled `vcs-jump` script, defaulting to "diff"
  " mode.
  "
  " By default, `<Leader>d` will invoke this mapping unless:
  "
  " - A mapping with the same |{lhs}| already exists; or:
  " - An alternative mapping to |<Plug>(VcsJump)| has already been defined in
  "   your |.vimrc|.
  "
  " You can create a different mapping like this:
  "
  " ```
  " " Use <Leader>g instead of <Leader>d
  " nmap <Leader>g <Plug>(VcsJump)
  " ```
  "
  nmap <unique> <Leader>d <Plug>(VcsJump)
endif

nnoremap <Plug>(VcsJump) :VcsJump diff<space>
