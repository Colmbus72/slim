function! slim#app#init()
    tabe editor
    nnoremap <leader>q :tabc<CR>
    nnoremap <leader>l :call slim#app#requestChannelHistory(g:current_workspace_channel)<CR>
    nnoremap <leader>c <c-w>h<c-w>j/

    if empty(g:current_workspace)
        let g:current_workspace = keys(g:id_map.slim_workspace)[0]
        call slim#util#updateConfig('', {"g:current_workspace": g:current_workspace})
    endif
    if empty(g:current_workspace_channel)
        let g:current_workspace_channel = keys(g:id_map.slim_channel)[0]
        call slim#util#updateConfig('', {"g:current_workspace_channel": g:current_workspace_channel})
    endif
    " Split open our windows and arrange them
    call s:openEditor(g:current_workspace, g:current_workspace_channel)
    call s:openChannel(g:current_workspace, g:current_workspace_channel)
    call s:openChannelList(g:current_workspace)
    execute "normal! \<c-w>H"
    vertical resize 30
    call s:openWorkspaceList()
    resize 12
    execute "normal! \<c-w>l"
    execute "normal! \<c-w>j"
    resize 8 
    " call s:StartListening(g:current_workspace, g:current_workspace_channel)
endfunction

function! s:openEditor(workspace, channel)
    execute 'e '.g:data_path 
        \ .'/workspaces/'
        \ .a:workspace
        \ .'/channels/'
        \ .a:channel
        \ .'.slime'
    inoremap <buffer> <ESC> <ESC>:w<CR>
    nnoremap <buffer> <leader>w ggVG"md:call slim#app#sendMessage(@m, '')<CR>:w<CR><c-w>kj<c-w>j
endfunction

function! s:openChannelList(workspace)
    execute 'sp '.g:data_path 
        \ .'/workspaces/'
        \ . a:workspace
        \ .'/channel.slimc'
    nnoremap <buffer> <CR> 0wvt[h"zy:call slim#app#changeChannel(@z)<CR>
endfunction

function! s:openChannel(workspace, channel)
    execute 'sp '.g:data_path 
        \ .'/workspaces/'
        \ .a:workspace
        \ .'/channels/'
        \ .a:channel
        \ .'.slimv'
endfunction

function! s:openWorkspaceList()
    execute 'sp '.g:data_path 
        \ .'/workspaces/'
        \ .'/workspace.slimc'
    nnoremap <buffer> <CR> 0f[2lvt]h"wy:call slim#app#changeWorkspace(@w)<CR>
    call s:loadWorkspaceMappings()
endfunction

function! slim#app#sendMessage(text, channel)
    let l:uri = 'https://slack.com/api/chat.postMessage'

    " let l:channel = ""
    if empty(a:channel)
        let l:hi = expand('%:t')
        let l:channel_name = matchstr(expand('%:t'),'.*\ze\.')
        let l:channel = g:id_map['slim_channel'][l:channel_name]
    else
        let l:channel = g:id_map['slim_channel'][a:channel]
    endif

    let l:request = {
        \ 'method': 'POST',
        \ 'uri': l:uri,
        \ 'params': {
        \   "token": get(g:id_map.slim_workspace,g:current_workspace),
        \   'text': a:text,
        \   'channel': l:channel
        \   }
        \ }
    let l:curl = slim#util#getCurlCommand(l:request)
    let l:response = system(l:curl)
    let l:decoded = json_decode(l:response)
endfunction

function! slim#app#changeChannel(channel)
    if g:current_workspace_channel ==# a:channel
        return
    endif

    call slim#util#updateConfig('',{'g:current_workspace_channel': a:channel})
    tabclose
    call slim#StartSlack()
    exe "normal! \<c-w>kjk"
    " exe normal! \<c-w>h"
    " exe normal! /".@z."\<cr>"
endfunction

function! slim#app#changeWorkspace(workspace)
    if g:current_workspace ==# a:workspace
        return
    endif
    call slim#util#updateConfig('',{'g:current_workspace': a:workspace, 'g:current_workspace_channel': ''})
    tabclose
    call slim#StartSlack()
    exe "normal! \<c-w>h\<c-w>k"
    exe "normal! /".@w."\<cr>"
endfunction

function! s:loadWorkspaceMappings()
    let l:workspaces = readfile(g:data_path.'/workspaces/workspace.slimc')
    for l:workspace in l:workspaces
        let l:mapping = matchstr(l:workspace,'^\zs.*\ze\s[\s')
        let l:workspace_name = matchstr(l:workspace,'\[\s\zs.*\ze\s\]')
        if !empty(l:mapping) && !empty(l:workspace_name)
            exe 'nnoremap '.l:mapping.' :call slim#app#changeWorkspace("'.l:workspace_name.'")'.'<CR>'
        endif
    endfor
endfunction

function! slim#app#requestChannelHistory(channel_name)
    echom "REQUESTING HISTORY"
    let l:url = 'https://slack.com/api/conversations.history'

    let l:request = {
        \ 'method': 'GET',
        \ 'uri': l:url,
        \ 'params': {
        \   "token": get(g:id_map.slim_workspace,g:current_workspace),
        \   "channel": get(g:id_map.slim_channel,a:channel_name)
        \   }
        \ }
    let l:curl = slim#util#getCurlCommand(l:request)
    let l:response = system(l:curl)
    let l:decoded = json_decode(l:response)
    let l:lines = []
    let l:messages = reverse(l:decoded['messages'])
    for l:message in l:messages
        let l:user_name = get(g:id_map.slack_member, l:message.user, 'Member')
        let l:user_id = l:message.user
        let l:text = ' ' .l:message.text
        let l:time = strftime("%I:%M %p", l:message.ts)

        call add(l:lines, l:user_name . ' ' . l:time . ' [='.l:user_id.'=]')
        call add(l:lines, '-------')
        call add(l:lines, l:text)
        call add(l:lines, '')
    endfor
    let l:file_path = g:data_path
        \ . '/workspaces/'
        \ . g:current_workspace
        \ . '/channels/'
        \ . a:channel_name.'.slimv'
    call writefile(l:lines, l:file_path)
endfunction
