" Vim filetype plugin file
" Language: HTTP Request
" Maintainer: nrest.nvim

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Set local options
setlocal commentstring=#\ %s
setlocal comments=:#,://
setlocal formatoptions-=t
setlocal formatoptions+=croql

" Set buffer-local undo
let b:undo_ftplugin = "setlocal commentstring< comments< formatoptions<"
