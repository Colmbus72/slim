setlocal nonu
setlocal concealcursor=nc
setlocal conceallevel=2
setlocal ai
syntax match token /Workspace.*:\s\zs.*\ze/ conceal cchar=+
setlocal statusline=Config
