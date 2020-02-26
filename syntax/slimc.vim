setlocal noswapfile
setlocal nonu
setlocal nomodifiable
setlocal nowrap
setlocal statusline=%t

let s:data_path = expand('<sfile>:p:h:h') . '/.data'

setlocal concealcursor=nc
setlocal conceallevel=3

execute 'syntax match ModeMsg /^.*\[\s'.(exists("g:current_workspace") ? g:current_workspace : '' ).'\s\]/'
execute 'syntax match ModeMsg /\s'.(exists("g:current_workspace_channel") ? g:current_workspace_channel : '' ).'/'

" Please make sure you have conceal available
" otherwise recompile vim with conceal enabled
syntax region channel start=/\[=/ end=/=\]/ conceal
