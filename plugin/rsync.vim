if exists('g:loaded_rsync') | finish | endif " prevent loading file twice

" let LuaSearchSession = luaeval('require("telescope._extensions.session-lens.main").search_session')

" Available commands
" command! -nargs=0 SearchSession call LuaSearchSession()

" let OnFileSave = luaeval('')
"
" aug rsync
"   au!
"   au BufWritePost,FileWritePost * call OnFileSave()})
"
" aug end

let g:loaded_rsync = 1