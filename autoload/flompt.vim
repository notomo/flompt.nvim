
let s:funcs = {
    \ '': { prompt -> prompt.open() },
    \ 'open': { prompt -> prompt.open() },
    \ 'close': { prompt -> prompt.close() },
    \ 'send': { prompt -> prompt.send() },
    \ 'start_sync': { prompt -> prompt.start_sync() },
    \ 'stop_sync': { prompt -> prompt.stop_sync() },
\ }

function! flompt#main(...) abort
    let arg = get(a:000, 0, '')
    if !has_key(s:funcs, arg)
        return flompt#messenger#new().error('invalid arg: ' . arg)
    endif

    call flompt#logger#new('main').log('arg: ' . arg)

    let [prompt, err] = flompt#prompt#get_or_create()
    if !empty(err)
        return flompt#messenger#new().warn(err)
    endif

    return s:funcs[arg](prompt)
endfunction
