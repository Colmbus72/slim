
setlocal autoread
setlocal noswapfile
setlocal concealcursor=nc
setlocal statusline=%t
setlocal conceallevel=3

syntax region NameTag start=/^\w/ end=/\ze\d/
syntax region SlimId start=/\[=/ end=/=\]/ conceal

" :syntax keyword Todo    TODO    contained
" :syntax match   Comment "//.*"  contains=Todo

syntax region CodeBlock start=/```/ end=/```/
syntax match InlineCode /`\zs.*\ze`/

highlight InlineCode ctermfg=red
highlight NameTag cterm=bold
highlight CodeBlock cterm=bold
