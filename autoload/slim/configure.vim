
" ------------------------------
" Public Functions
" ------------------------------

function! slim#configure#attemptLogin()
    let l:data = s:parseLoginFile()
    for [l:key, l:token] in items(l:data)
        let l:response = s:loadWorkspaceConfigs('test', l:token, l:key)
        exe '/'. l:token
        exe 'normal! 0dtWI        '.(l:response ==# 'Success' ? '✓ ' : 'x ')
    endfor
endfunction

" Add a new workspace to the login.slima file
function! slim#configure#addNewWorkspace()
    execute '/Workspace'
    exe 'normal! GN0f:hvT "ny'
    " TODO: Check if n is a number or a string
    exe 'normal! oWorkspace '.(@n[-1:]+1).' <leader>'.(@n[-1:]+1).': '
endfunction

function! slim#configure#saveConfigAndLoad()
    let l:data = s:parseLoginFile()
    call writefile([''], g:data_path.'/workspaces/workspace.slimc')
    for [l:key, l:token] in items(l:data)
        let l:response = s:loadWorkspaceConfigs('', l:token, l:key)
        exe '/'. l:token
        exe 'normal! I'.(l:response ==# 'Success' ? 'W ' : 'X ')
        let g:id_map = {}
    endfor
endfunction

" ------------------------------
" Private Functions
" ------------------------------

" Read in the users login.slima and return the workspaces with their mapping
" returns { mapping1: token1, mapping2: token2 }
function! s:parseLoginFile()
    let l:file_lines = readfile(g:data_path . '/login.slima')
    let l:data = {}
    let l:pattern = 'Workspace\s.*\s\(.*\):\s\(.*\)'
    for l:line in l:file_lines
        let l:matches = matchlist(l:line, l:pattern)
        if len(l:matches) > 0
            if !empty(l:matches[1]) && !empty(l:matches[2])
                let l:data[l:matches[1]] = l:matches[2]
            endif
        endif
    endfor
    return l:data
endfunction

" Request the workspaces members and parse them to local file
" params:
"    'env': string ['test' returns true or errors, '' writes to config files]
"    'token': string [required when env = 'test']
function! s:requestWorkspaceInfo(env, workspace_token, mapping)
    let l:uri = "https://slack.com/api/team.info"

    let l:request = {
        \ 'method': 'GET',
        \ 'uri': l:uri,
        \ 'params': {
        \   "token": a:workspace_token
        \   }
        \ }
    let l:curl = slim#util#getCurlCommand(l:request)
    let l:response = system(l:curl)
    let l:decoded = json_decode(l:response)
    let l:lines = ['Workspaces', '']
    if empty(l:decoded)
        return 0
    endif
    if has_key(l:decoded, 'needed')
        return l:decoded.needed
    endif
    if has_key(l:decoded,'error')
        return l:decoded.error
    endif
    if a:env ==# 'test'
        return 1
    endif

    let g:current_workspace = l:decoded.team.name

    let l:workspace_dir = g:data_path . '/workspaces/' .g:current_workspace 
    " if !filereadable(l:workspace_dir)
    call mkdir(l:workspace_dir.'/channels',"p")
    " endif

    let l:lines = ['', a:mapping.' [ '.l:decoded.team.name.' ] [='.a:workspace_token.'=]']

    let l:file_path = g:data_path
        \ . '/workspaces/'
        \ . '/workspace.slimc'
    call writefile(l:lines, l:file_path, 'a')
    return l:decoded.team.name
endfunction

" Request the workspaces members and parse them to local file
" params:
"    'env': string ['test' returns true or errors, '' writes to config files]
"    'token': string [required when env = 'test']
function! s:requestWorkspaceMembers(env, workspace_token, workspace_name)
    let l:uri = "https://slack.com/api/users.list"

    let l:request = {
        \ 'method': 'GET',
        \ 'uri': l:uri,
        \ 'params': {
        \   "token": a:workspace_token
        \   }
        \ }
    let l:curl = slim#util#getCurlCommand(l:request)
    let l:response = system(l:curl)
    " let l:response = slim#airplane#getUsers()
    let l:decoded = json_decode(l:response)
    let l:lines = ['Users', '']
    if empty(l:decoded)
        return 0
    endif
    if has_key(l:decoded, 'needed')
        return l:decoded.needed
    endif
    if has_key(l:decoded,'error')
        return l:decoded.error
    endif
    if a:env ==# 'test'
        return 1
    endif

    for l:member in l:decoded.members
        let l:member_line = (has_key(l:member, 'real_name') ? l:member.real_name : l:member.name) .' [='. l:member.id .'=]'
        call add(l:lines, l:member_line)
    endfor
    let l:file_path = g:data_path
        \ . '/workspaces/'
        \ . a:workspace_name
        \ . '/member.slimc'
    call writefile(l:lines, l:file_path)
endfunction

" params:
"    'env': string ['test' returns true or errors, '' writes to config files]
"    'token': string [required when env = 'test']
function! s:requestConversations(env, workspace_token)
    let l:uri = "https://slack.com/api/conversations.list"

    let l:request = {
        \ 'method': 'GET',
        \ 'uri': l:uri,
        \ 'params': {
        \   "token": a:workspace_token,
        \   "types": "public_channel,private_channel,mpim,im"
        \   }
        \ }
    let l:curl = slim#util#getCurlCommand(l:request)
    let l:response = system(l:curl)
    " let l:response = slim#airplane#getConversations()
    let l:decoded = json_decode(l:response)
    if empty(l:decoded)
        return 0
    endif
    if has_key(l:decoded, 'needed')
        return l:decoded.needed
    endif
    if has_key(l:decoded,'error')
        return l:decoded.error
    endif
    if a:env ==# 'test'
        return 1
    endif
    if !has_key(g:id_map.slack_workspace, a:workspace_token)
        return 1
    endif

    let l:lines = {'channels': ['Channels',''], 'dms': ['Direct Messages', '']}
    for l:convo in l:decoded.channels
        if has_key(l:convo, 'is_channel')
            " TODO: add other types of conversations:
            " multi person ims
            if eval(l:convo.is_channel) || eval(l:convo.is_group)
                if l:convo.is_private
                    let l:channel_line = '🔒 '
                else
                    let l:channel_line = '# '
                endif
                let l:channel_line = l:channel_line . l:convo.name .' [='. l:convo.id .'=]'
                call add(l:lines.channels, l:channel_line)
            endif
        endif
        if has_key(l:convo, 'is_im') && l:convo.is_im && !l:convo.is_user_deleted
            if !has_key(g:id_map.slack_member, l:convo.user)
                echom "Dont have ".l:convo.user." - ".l:convo.id
            else 
                let l:channel_line = '@ ' . g:id_map.slack_member[l:convo.user] . ' [='. l:convo.id .'=]'
                call add(l:lines.dms, l:channel_line)
            endif
        endif
    endfor
    let l:write_lines = l:lines.channels + ['',''] + l:lines.dms
    let l:file_path = g:data_path
        \ . '/workspaces/'
        \ . get(g:id_map.slack_workspace, a:workspace_token)
        \ . '/channel.slimc'
    call writefile(l:write_lines, l:file_path)
endfunction

" Request all the required information from slack to create our configuration files
" and save them to their paths
" params:
"    'env': string ['test' returns true or errors, '' writes to config files]
"    'token': string [required when env = 'test']
function! s:loadWorkspaceConfigs(env, workspace_token, mapping)
    let l:workspace_response = s:requestWorkspaceInfo(a:env, a:workspace_token, a:mapping)
    let l:user_response = s:requestWorkspaceMembers(a:env, a:workspace_token, l:workspace_response)
    if a:env !=# 'test'
        " Conversations reference ids and since we got the users we can correctly map to usernames
        " we dont need it when testing so dont call it 
        call slim#util#loadIdMap()
    endif
    let l:conversation_response = s:requestConversations(a:env, a:workspace_token)

    if a:env ==# 'test' && l:user_response && l:conversation_response
        return "Success"
    endif
endfunction
