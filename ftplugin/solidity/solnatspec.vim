let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 -range=0 -complete=customlist,solnatspec SolNatSpec call solnatspec#insert(<q-args>, <count>, <line1>, <line2>)

if !exists('g:solnatspec_enable_mapping')
  let g:solnatspec_enable_mapping = 1
endif

if g:solnatspec_enable_mapping == 1 || hasmapto('<Plug>(solnatspec)')
  nnoremap <silent> <buffer> <Plug>(solnatspec) :call solnatspec#insert()<CR>
  if !hasmapto('<Plug>(solnatspec)')
    nmap <silent> <C-l> <Plug>(solnatspec)
  endif
endif

let &cpo = s:save_cpo
unlet s:save_cpo
