
function! flompt#messenger#clear() abort
    let f = {}
    function! f.default(message) abort
        echomsg a:message
    endfunction

    let s:func = { message -> f.default(message) }
endfunction

call flompt#messenger#clear()


function! flompt#messenger#set_func(func) abort
    let s:func = { message -> a:func(message) }
endfunction

function! flompt#messenger#new() abort
    let messenger = {
        \ 'func': s:func,
    \ }

    function! messenger.warn(message) abort
        echohl WarningMsg
        call self.func('[flompt] ' . a:message)
        echohl None
    endfunction

    function! messenger.error(message) abort
        echohl ErrorMsg
        call self.func('[flompt] ' . a:message)
        echohl None
    endfunction

    return messenger
endfunction
