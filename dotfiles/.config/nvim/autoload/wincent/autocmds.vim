let g:WincentColorColumnBufferNameBlacklist = ['__LanguageClient__']
let g:WincentColorColumnFileTypeBlacklist = ['command-t', 'diff', 'fugitiveblame', 'undotree', 'nerdtree', 'qf']
let g:WincentCursorlineBlacklist = ['command-t']
let g:WincentMkviewFiletypeBlacklist = ['diff', 'hgcommit', 'gitcommit']

function! wincent#autocmds#attempt_select_last_file() abort
  let l:previous=expand('#:t')
  if l:previous !=# ''
    call search('\v<' . l:previous . '>')
  endif
endfunction

function! wincent#autocmds#should_colorcolumn() abort
  if index(g:WincentColorColumnBufferNameBlacklist, bufname(bufnr('%'))) != -1
    return 0
  endif
  return index(g:WincentColorColumnFileTypeBlacklist, &filetype) == -1
endfunction

function! wincent#autocmds#should_cursorline() abort
  return index(g:WincentCursorlineBlacklist, &filetype) == -1
endfunction

" Loosely based on: http://vim.wikia.com/wiki/Make_views_automatic
function! wincent#autocmds#should_mkview() abort
  return
        \ &buftype ==# '' &&
        \ index(g:WincentMkviewFiletypeBlacklist, &filetype) == -1 &&
        \ !exists('$SUDO_USER') " Don't create root-owned files.
endfunction

function! wincent#autocmds#mkview() abort
  try
    if exists('*haslocaldir') && haslocaldir()
      " We never want to save an :lcd command, so hack around it...
      cd -
      mkview
      lcd -
    else
      mkview
    endif
  catch /\<E186\>/
    " No previous directory: probably a `git` operation.
  catch /\<E190\>/
    " Could be name or path length exceeding NAME_MAX or PATH_MAX.
  endtry
endfunction

function! s:get_spell_settings() abort
  return {
        \   'spell': &l:spell,
        \   'spellcapcheck': &l:spellcapcheck,
        \   'spellfile': &l:spellfile,
        \   'spelllang': &l:spelllang
        \ }
endfunction

function! s:set_spell_settings(settings) abort
  let &l:spell=a:settings.spell
  let &l:spellcapcheck=a:settings.spellcapcheck
  let &l:spellfile=a:settings.spellfile
  let &l:spelllang=a:settings.spelllang
endfunction

function! wincent#autocmds#blur_window() abort
  if wincent#autocmds#should_colorcolumn()
    let l:settings=s:get_spell_settings()
    ownsyntax off
    set nolist
    if has('conceal')
      set conceallevel=0
    endif
    call s:set_spell_settings(l:settings)
  endif
endfunction

function! wincent#autocmds#focus_window() abort
  if wincent#autocmds#should_colorcolumn()
    if !empty(&ft)
      let l:settings=s:get_spell_settings()
      ownsyntax on
      set list
      let l:conceal_exclusions=get(g:, 'indentLine_fileTypeExclude', [])
      if has('conceal') && index(l:conceal_exclusions, &ft) == -1
        set conceallevel=1
      endif
      call s:set_spell_settings(l:settings)
    endif
  endif
endfunction

function! wincent#autocmds#blur_statusline() abort
  " Default blurred statusline (buffer number: filename).
  let l:blurred='%{wincent#statusline#gutterpadding()}'
  let l:blurred.='\ ' " space
  let l:blurred.='\ ' " space
  let l:blurred.='\ ' " space
  let l:blurred.='\ ' " space
  let l:blurred.='%<' " truncation point
  let l:blurred.='%f' " filename
  let l:blurred.='%=' " split left/right halves (makes background cover whole)
  call s:update_statusline(l:blurred, 'blur')
endfunction

function! wincent#autocmds#focus_statusline() abort
  " `setlocal statusline=` will revert to global 'statusline' setting.
  call s:update_statusline('', 'focus')
endfunction

function! s:update_statusline(default, action) abort
  let l:statusline = s:get_custom_statusline(a:action)
  if type(l:statusline) == type('')
    " Apply custom statusline.
    execute 'setlocal statusline=' . l:statusline
  elseif l:statusline == 0
    " Do nothing.
    "
    " Note that order matters here because of Vimscript's insane coercion rules:
    " when comparing a string to a number, the string gets coerced to 0, which
    " means that all strings `== 0`. So, we must check for string-ness first,
    " above.
    return
  else
    execute 'setlocal statusline=' . a:default
  endif
endfunction

function! s:get_custom_statusline(action) abort
  if &ft ==# 'command-t'
    " Will use Command-T-provided buffer name, but need to escape spaces.
    return '\ \ ' . substitute(bufname('%'), ' ', '\\ ', 'g')
  elseif &ft ==# 'diff' && exists('t:diffpanel') && t:diffpanel.bufname ==# bufname('%')
    return 'Undotree\ preview' " Less ugly, and nothing really useful to show.
  elseif &ft ==# 'undotree'
    return 0 " Don't override; undotree does its own thing.
  elseif &ft ==# 'nerdtree'
    return 0 " Don't override; NERDTree does its own thing.
  elseif &ft ==# 'qf'
    if a:action ==# 'blur'
      return
            \ '%{wincent#statusline#gutterpadding()}'
            \ . '\ '
            \ . '\ '
            \ . '\ '
            \ . '\ '
            \ . '%<'
            \ . '%q'
            \ . '\ '
            \ . '%{get(w:,\"quickfix_title\",\"\")}'
            \ . '%='
    else
      return g:WincentQuickfixStatusline
    endif
  endif

  return 1 " Use default.
endfunction

function! wincent#autocmds#idleboot() abort
  " Make sure we automatically call wincent#autocmds#idleboot() only once.
  augroup WincentIdleboot
    autocmd!
  augroup END

  " Make sure we run deferred tasks exactly once.
  doautocmd User WincentDefer
  autocmd! User WincentDefer
endfunction

" Directories where we want to perform auto-encryption on save.
let s:encrypted={}
let s:encrypted[expand('~/code/ansible-configs')]='vendor/git-cipher/bin/git-cipher'
let s:encrypted[expand('~/code/wincent')]='vendor/git-cipher/bin/git-cipher'

" Update encryptable files after saving.
function! wincent#autocmds#encrypt(file) abort
  let l:base=fnamemodify(a:file, ':h')
  let l:directories=keys(s:encrypted)
  for l:directory in l:directories
    if stridx(a:file, l:directory) == 0
      let l:encrypted=l:base . '/.' . fnamemodify(a:file, ':t') . '.encrypted'
      if filewritable(l:encrypted) == 1
        let l:executable=l:directory . '/' . s:encrypted[l:directory]
        if executable(l:executable)
          call system(
                \   fnamemodify(l:executable, ':S') .
                \   ' encrypt ' .
                \   shellescape(a:file)
                \ )
        endif
      endif
      break
    endif
  endfor
endfunction

" Filetypes that we might want to apply directory-specific overrides to.
let s:wincent_override_filetypes=[
      \   'bnd',
      \   'conf',
      \   'groovy',
      \   'html',
      \   'java',
      \   'javascript',
      \   'jproperties',
      \   'json',
      \   'jsp',
      \   'ignore',
      \   'npmbundler',
      \   'scss',
      \   'soy',
      \   'tsx',
      \   'typescript',
      \   'xml'
      \ ]


function! wincent#autocmds#apply_overrides(file, type) abort
  let l:pattern=join(s:wincent_override_filetypes, '\|')
  if match(a:type, '\<\(' . l:pattern . '\)\>') != -1
    let l:detected=wincent#liferay#detect(a:file)
    if l:detected
      setlocal noexpandtab
      setlocal shiftwidth=4
      setlocal tabstop=4
      setlocal noshiftround

      if match(&formatprg, '^par ') != -1
        " "T", turns tabs to spaces, and I can't seem to turn it off, but I can
        " at least make it use the right number of them...
        let &l:formatprg=substitute(&formatprg, 'T\d*', 'T4', '')

        " ... and then override the |gq| operator to do a |:retab!| after
        " applying.
        map <buffer> gq <Plug>(operator-format-and-retab)
        call operator#user#define('format-and-retab', 'wincent#autocmds#format')
      endif

      if l:detected == 2
        " Additional settings for main liferay-portal repo, but not for *.js or
        " *.scss.
        if match(a:type, '\<\(javascript\|scss\)\>') == -1
          setlocal noendofline
          setlocal nofixendofline
        endif
      endif
    endif
  endif
endfunction

function! wincent#autocmds#format(motion) abort
  if has('ex_extra')
    let l:v=operator#user#visual_command_from_wise_name(a:motion)
    silent execute 'normal!' '`[' . l:v . '`]gq'
    '[,']retab!
  endif
endfunction
