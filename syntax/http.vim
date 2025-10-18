" Vim syntax file
" Language: HTTP Request
" Maintainer: nrest.nvim
" Latest Revision: 2025

if exists("b:current_syntax")
  finish
endif

" HTTP Methods
syn keyword httpMethod GET POST PUT PATCH DELETE HEAD OPTIONS CONNECT TRACE
hi def link httpMethod Statement

" HTTP Version
syn match httpVersion /HTTP\/[0-9.]\+/
hi def link httpVersion Special

" URLs
syn match httpUrl /https\?:\/\/[^ ]\+/
hi def link httpUrl Underlined

" Headers
syn match httpHeader /^[A-Za-z0-9-]\+:/
hi def link httpHeader Keyword

" Comments
syn match httpComment /^#.*$/
syn match httpComment /^\/\/.*$/
hi def link httpComment Comment

" Separators
syn match httpSeparator /^###.*$/
hi def link httpSeparator PreProc

" JSON
syn region httpJson start=/{/ end=/}/ contains=httpJsonKey,httpJsonString,httpJsonNumber,httpJsonBoolean,httpJsonNull
syn match httpJsonKey /"\w\+"\s*:/he=e-1 contained
syn region httpJsonString start=/"/ skip=/\\"/ end=/"/ contained
syn match httpJsonNumber /\<\d\+\>/ contained
syn keyword httpJsonBoolean true false contained
syn keyword httpJsonNull null contained

hi def link httpJsonKey Identifier
hi def link httpJsonString String
hi def link httpJsonNumber Number
hi def link httpJsonBoolean Boolean
hi def link httpJsonNull Constant

" Status codes (for responses)
syn match httpStatusCode /^HTTP\/[0-9.]\+ \zs[0-9]\{3\}/
hi def link httpStatusCode Number

let b:current_syntax = "http"
