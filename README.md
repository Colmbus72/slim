# slim
Interact with slack using vim!

Disclaimer:
    This is my first vim plugin and I know I am doing some things wrong, I would love to know how to make this better.
    This project is very much still a work in progress, there are many known issues and many features yet to be implemented
    My goal was to try to write as much as possible of the app in vimscript and to use the outside world as little as possible

Requirements:
    Pathogen - https://github.com/tpope/vim-pathogen
    Vim must be compiled with conceal. 
        To find out if it is or not run :version in vim. If there is a + then you have it
    A slack application in your workspace that can write and read as your user.

TODO: all the other requirements and stuff..

clone this into `~/.vim/bundle/`
you need to give a slack app permission to your workspace and then store the tokens in login file
also need to copy .data/login_template.slima to .data/login.slima
paste in your token and test them out with `tw<CR>`
if you see a check for your workspace that means it was able to confirm your token has the required scopes
when you call `:W` it will generate all your workspace and channel files and overwrite anything in the .data/workspaces dir

If you dont have a leader key setup I would recommend doing so.

Commands:

`<leader>l` - refresh the channel page

`<leader>q` - close slack

`<leader>c` - change to channel list and start search

`<leader>b` - change to write buffer and insert at the end

`<leader>w` - send entire write buffer to slack as a message
