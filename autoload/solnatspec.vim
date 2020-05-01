" Insert NatSpec comments on Solidity contracts
" Inspired by heavenshell/vim-pydocstring
" Author:       Felipe Buiras
" WebPage:      http://github.com/fmorisan/vim-solnatspec
" Description:  Generate NatSpec comments for your Solidity files.
" License:      BSD, see LICENSE for more details

let s:save_cpo = &cpo
set cpo&vim

let g:solnatspec_template = get(g:, 'pydocstring_templates_path', '')
let g:solnatspec_formatter = get(g:, 'pydocstring_formatter', 'sphinx')
let g:solc_path = get(
  \ g:,
  \ 'solc_path',
  \ '/usr/bin/solc'
  \ )
let g:natspecgen_path = get(
  \ g:,
  \ 'natspecgen_path',
  \ printf('%s/lib/natspecgen.py', expand('<sfile>:p:h:h'))
  \ )

" NOTE: copied over from vim-pydocstring. Thanks!
function! s:get_range() abort
  " Get visual mode selection.
  let mode = visualmode(1)
  if mode == 'v' || mode == 'V' || mode == ''
    let start_lineno = line("'<")
    let end_lineno = line("'>")
    return {'start_lineno': start_lineno, 'end_lineno': end_lineno}
  endif
  let current = line('.')
  return {'start_lineno': 0, 'end_lineno': '$'}
endfunction

function! s:insert_natspec(natspec, end_lineno) abort
    let paste = &g:paste
    let &g:paste = 1
    
    silent! execute 'normal!' . a:end_lineno . 'G$'
    let current_lineno = line('.')

    " If current position is bottom, add docstring below.
    if a:end_lineno == current_lineno
        silent! execute 'normal! O' . a:docstrings['docstring']
    else
        silent! execute 'normal! o' . a:docstrings['docstring']
    endif

    let &g:paste = paste
    silent! execute 'normal! ' . a:end_lineno . 'G$'
endfunction

function! s:callback(msg, indent, start_lineno) abort
  let msg = join(a:msg, '')
  " Check needed for Neovim
  if len(msg) == 0
    return
  endif

  let docstrings = reverse(json_decode(msg))
  silent! execute 'normal! 0'
  let length = len(docstrings)
  for docstring in docstrings
    let lineno = 0
    if length > 1
      call cursor(a:start_lineno + docstring['start_lineno'] - 1, 1)
      let lineno = search('\:\(\s*#.*\)*$', 'n') + 1
    else
      let lineno = search('\:\(\s*#.*\)*$', 'n') + 1
    endif

    call s:insert_docstring(docstring, lineno)
  endfor
endfunction

function! s:format_callback(msg, indent, start_lineno) abort
  call extend(s:results, a:msg)
endfunction

function! s:exit_callback(msg) abort
  unlet s:job " Needed for Neovim
  if len(s:results)
    let view = winsaveview()
    silent execute '% delete'
    call setline(1, s:results)
    call winrestview(view)
    let s:results = []
  endif
endfunction

" Magic starts here. Calling solc --ast-json...
function! s:execute(cmd, lines, indent, start_lineno, cb, ex_cb) abort
  if !executable(expand(g:solc_path)) || !executable(expand(natspecgen_path))
    redraw
    echohl Error
    echo '`solc` or `natspecgen` not found. Install them.'
    echohl None
    return
  endif

  if has('nvim')
    if exists('s:job')
      call jobstop(s:job)
    endif

    let s:job = jobstart(a:cmd, {
      \ 'on_stdout': {_c, m, _e -> a:cb(m, a:indent, a:start_lineno)},
      \ 'on_exit': {_c, m, _e -> a:ex_cb(m)},
      \ 'stdout_buffered': v:true,
      \ })
  else
    if exists('s:job') && job_status(s:job) != 'stop'
      call job_stop(s:job)
    endif

    let s:job = job_start(a:cmd, {
      \ 'callback': {_, m -> a:cb([m], a:indent, a:start_lineno)},
      \ 'exit_cb': {_, m -> a:ex_cb([m])},
      \ 'in_mode': 'nl',
      \ })
  endif
endfunction

function! s:create_cmd(file, symbol, indent) abort
    let cmd = printf(
        \ '%s %s %s --indent %d',
        \ expand(g:natspecgen_path)
        \ a:file
        \ a:symbol
        \ a:indent
        \ )
    return cmd
endfunction

function! solnatspec#insert(...) abort
  let range = s:get_range()
  let pos = getpos('.')

  let line = getline('.')
  let indent = matchstr(line, '^\(\s*\)')

  let space = repeat(' ', &softtabstop)
  let indent = indent . space
  if len(indent) == 0
    let indent = space
  endif

  let symbol = expand('<cword>')

  let cmd = s:create_cmd(expand('%'), symbol, indent)

  call s:execute(
    \ cmd,
    \ )
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
