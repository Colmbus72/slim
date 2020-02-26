TailStart

setlocal autoread
setlocal noswapfile
setlocal concealcursor=nc
setlocal conceallevel=3
highlight NameTag cterm=bold
" syntax match NameTag  /^\w\(\w\|\s\)\+/
syntax region NameTag start=/^\w/ end=/\ze\d/

syntax region SlimId start=/\[=/ end=/=\]/ conceal
setlocal statusline=%t
