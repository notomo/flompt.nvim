
let s:funcs = {
    \ '': { prompt -> prompt.open() },
    \ 'open': { prompt -> prompt.open() },
    \ 'close': { prompt -> prompt.close() },
    \ 'send': { prompt -> prompt.send() },
\ }

function! flompt#main(...) abort
    let arg = get(a:000, 0, '')
    if !has_key(s:funcs, arg)
        throw 'invalid arg: ' . arg
    endif

    call flompt#logger#new('main').log('arg: ' . arg)

    let prompt = flompt#prompt#get_or_create()
    return s:funcs[arg](prompt)
endfunction
