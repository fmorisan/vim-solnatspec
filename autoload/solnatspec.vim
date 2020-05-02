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

" Magic starts here. Calling solc --ast-json...
function! s:create_cmd(file, lineno, indent) abort
    let cmd = printf(
        \ 'python3 %s %s %s --indent %d',
        \ expand(g:natspecgen_path),
        \ expand(a:file),
        \ a:lineno,
        \ a:indent,
        \ )
    return cmd
endfunction

function! solnatspec#insert(...) abort
  let line = line('.')
  let linedata = getline('.')
  let indent = matchstr(linedata, '^\(\s*\)')

  let symbol = expand('<cword>')

  let cmd = s:create_cmd(expand('%'), line, len(indent))

  execute 'normal!k'
  echo cmd
  exec 'read!' . expand(cmd)

  let g:solnatspec_lastcmd = cmd

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
