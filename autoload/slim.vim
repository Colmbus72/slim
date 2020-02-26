let g:data_path = expand('<sfile>:p:h:h') . '/.data'

function! slim#StartSlack()
    " Source our 'current' variables saved when quiting app
    exe 'so '.g:data_path . '/app_state.vim'
  
    if !slim#util#loadIdMap()
        call slim#Login()
        return
    endif
  
    call slim#app#init()
endfunction

" TODO: user will setup one command in crontab
" that will run this every minute.
" Need to efficiently send off background jobs to write to channel files
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
    nnoremap <buffer> ~ :call slim#configure#addNewWorkspace()<CR>:w<CR>
    nnoremap <buffer> tw<CR> :call slim#configure#attemptLogin()<CR>:w<CR>
    com! W call slim#configure#saveConfigAndLoad() | :w
    exe '/Workspace'
endfunction

function slim#loadPath()
    let g:data_path = expand('<sfile>:p:h:h') . '/.data'
endfunction
