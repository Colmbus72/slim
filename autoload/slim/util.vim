
" Take in the request dictionary and return the corresponding curl command string
function! slim#util#getCurlCommand(request)
    let l:curl_fmt = "curl%s%s%s '%s'"
    let l:flags = ' -s'
    let l:method = printf(' -X %s', a:request.method)
    let l:url = fnameescape(a:request.uri)
    let l:data = ''
    if a:request.method ==? 'GET'
        let l:url = l:url . "?"
        for [l:param_key, l:param_value] in items(a:request.params)
            let l:url = l:url
                \ . fnameescape(l:param_key)
                \ . '='
                \ . fnameescape(l:param_value)
                \ . '&'
        endfor
    else
        for [l:param_key, l:param_value] in items(a:request.params)
            let l:data = l:data 
                \ . " -d "
                \ . printf('%s=%s', substitute(shellescape(l:param_key), '\\\n', "\n", 'g'), substitute(shellescape(l:param_value), '\\\n', "\n", 'g'))
                \ . ""
        endfor
    endif 
    let l:curl_request = printf(l:curl_fmt, l:flags, l:method, l:data, l:url)

    return l:curl_request
endfunction

" Read in the app config file and write all keys found in 
"  data that exist within the file
function! slim#util#updateConfig(env, data)
    if len(a:data) < 1
        return
    endif

    let l:file_name = g:data_path . '/app_state.vim'
    let l:current_list = readfile(l:file_name)
    let l:new_list = []
    for l:line in l:current_list
        let l:key = matchstr(l:line, 'let\s\zs.*\ze=')
        if has_key(a:data, l:key)
            let l:current_data = get(a:data,l:key)
            if type(l:current_data) ==# 4
                let l:new_line = ':let '.l:key.'={'
                for [l:_key, l:_value] in items(l:current_data)
                    let l:new_line = l:new_line .'"'. l:_key .'":"'. l:_value .'",'
                endfor
                let new_line = l:new_line . '}'
            else
                let l:new_line = substitute(l:line, '\".*\"', '"'.l:current_data.'"', "")
            endif
            call add(l:new_list, l:new_line)
        else
            call add(l:new_list, l:line)
        endif
    endfor
    call writefile(l:new_list, l:file_name)
endfunction

" Hey this is real dangerous as long as we are putting the workspace user tokens here
function! slim#util#loadIdMap()
    let g:id_map = {'slim_channel':{}, 'slack_channel':{}, 'slim_workspace':{}, 'slack_workspace':{}, 'slack_member':{}, 'slim_member':{}}

    if !filereadable(g:data_path . '/workspaces/workspace.slimc')
        return 0
    endif

    let l:workspace_list = readfile(g:data_path . '/workspaces/workspace.slimc')
    for l:line in l:workspace_list
        let l:key = matchstr(l:line, '\[=\zs.*\ze=\]')
        let l:name = matchstr(l:line, '\[\s\zs.*\ze\s\]')
        if !empty(l:key) || !empty(l:name)
            let g:id_map['slack_workspace'][l:key] = l:name
            let g:id_map['slim_workspace'][l:name] = l:key
        endif
    endfor

    if empty(g:id_map.slim_workspace)
        return 0
    end
    if !exists('g:current_workspace')
        let g:current_workspace = keys(g:id_map.slim_workspace)[0]
    endif
    if empty(get(g:id_map.slim_workspace, g:current_workspace, ''))
        let g:current_workspace = keys(g:id_map.slim_workspace)[0]
    end
    if !has_key(g:id_map.slim_workspace, g:current_workspace)
        return 0
    endif

    let l:workspace_dir = g:data_path . '/workspaces/' .g:current_workspace 

    let l:channel_file_name = l:workspace_dir. '/channel.slimc'
    if !filereadable(l:channel_file_name)
        call writefile([], l:channel_file_name)
    endif
    let l:channel_list = readfile(l:channel_file_name)
    for l:line in l:channel_list
        let l:key = matchstr(l:line, '\[=\zs.*\ze=\]')
        let l:name = matchstr(l:line, '[\#\|🔒\|\@]\s\zs.*\ze\s')
        if !empty(l:key) || !empty(l:name)
            let g:id_map['slack_channel'][l:key] = l:name
            let g:id_map['slim_channel'][l:name] = l:key
        endif
    endfor

    let l:member_file_name = l:workspace_dir.'/member.slimc'
    if !filereadable(l:member_file_name)
        call writefile([], l:member_file_name)
    endif
    let l:member_list = readfile(l:member_file_name)
    for l:line in l:member_list
        let l:key = matchstr(l:line, '\[=\zs.*\ze=\]')
        let l:name = matchstr(l:line, '^\zs.*\ze\s')
        if !empty(l:key) || !empty(l:name)
            let g:id_map['slack_member'][l:key] = l:name
            let g:id_map['slim_member'][l:name] = l:key
        endif
    endfor
    return 1
endfunction
