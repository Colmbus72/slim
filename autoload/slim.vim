let g:data_path = expand('<sfile>:p:h:h') . '/.data'

function! slim#StartSlack()
    " Source our 'current' variables saved when quiting app
    exe 'so '.g:data_path . '/app_state.vim'
  
    if !slim#util#loadIdMap()
        call slim#Login()
        return
    endif
  
    " if !filereadable(g:data_path.'/listen_cron')
    "     call slim#Listen()
    " endif
    call slim#app#init()
endfunction

function! slim#refreshChannels()
    call slim#loadPath()
    call slim#util#loadIdMap()
    
    let l:minute = strftime('%M')
    let l:command_start = 'vim -c ":call slim#loadPath()" -c ":call slim#util#loadIdMap()" -c ":call slim#app#requestChannelHistory(' . "'"
    let l:command_end = "'" . ')" -c ":q" &'
    
    while l:minute ==# strftime('%M') && strftime('%S') < 57
        let l:i = 0
        for l:channel in keys(g:id_map.slim_channel)
            " TODO: this is working synchronously right now
            "   need to come up with a way to make vim run in background because
            "   calling -es and using & isn't working properly with vim
    
            if l:i % 5 ==# 0
                sleep 1
                if l:minute !=# strftime('%M') || strftime('%S') > 57
                    break
                endif
            endif
            call system(l:command_start . l:channel . l:command_end)
            let l:i += 1
            " let l:p_id = system(l:command_start . l:channel . l:command_end .'; echo $!')
            " call writefile([l:channel.':'.l:p_id], g:data_path. '/current_pids','a')
            " call slim#util#requestChannelHistory(l:channel)
        endfor
    endwhile
endfunction

function! slim#Login()
    exe 'tabe '.g:data_path . '/login.slima'
    setlocal nowrap
    " nnoremap <buffer> <CR> "wyi[:call slim#runCommand(@w)<CR>
    nnoremap <buffer> ~ :call slim#configure#addNewWorkspace()<CR>:w<CR>
    nnoremap <buffer> tw<CR> :call slim#configure#attemptLogin()<CR>:w<CR>
    com! W call slim#configure#saveConfigAndLoad() | :w
    exe '/Workspace'
endfunction

function slim#Listen()
    " let l:lines = readfile(g:data_path.'/workspaces/'.g:current_workspace.'/channel.slimc')
    " let l:write_lines = []
    " for l:line in l:lines
    "     let l:channel_id = matchstr(l:line, '\[=\zs.*\ze=\]')
    "     if !empty(l:channel_id)
    "         if len(get(g:id_map.slack_channel, l:channel_id, '')) > 0
    "             let l:command = '* * * * *' . ' cd ' . g:data_path . '; for i in {1..15}; do vim -c ":call slim#loadPath()" -c ":call slim#util#loadIdMap()" -c ":call slim#app#requestChannelHistory(' . "'" . get(g:id_map.slack_channel, l:channel_id) . "'" . ')" -c ":q"; sleep 4; done'
    "             let l:write_lines = add(l:write_lines, l:command)
    "             " call slim#app#requestChannelHistory(get(g:id_map.slack_channel, l:channel_id))
    "         endif
    "     endif
    " endfor
    " call writefile(l:write_lines, g:data_path.'/listen_cron')
    " call system('crontab '.g:data_path.'/listen_cron')
endfunction

function slim#loadPath()
    let g:data_path = expand('<sfile>:p:h:h') . '/.data'
endfunction
