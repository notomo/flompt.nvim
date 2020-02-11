
let s:helper = FlomptTestHelper()
let s:suite = s:helper.suite('plugin.flompt')
let s:assert = s:helper.assert

function! s:suite.open_and_send()
    let channel_id = s:helper.open_terminal_sync()
    call s:helper.buffer_log()

    Flompt
    call s:assert.window_count(2)

    call s:helper.input(['echo 123'])

    let before_line = line('.')
    Flompt send
    call s:helper.wait_terminal(channel_id)
    call s:assert.line_number(before_line + 1)

    Flompt close
    call s:helper.buffer_log()

    call s:assert.prompt('')
    call s:assert.command_result_line('123')
endfunction

function! s:suite.close_one()
    Flompt

    Flompt close
    call s:assert.window_count(1)
endfunction

function! s:suite.close_none()
    Flompt close
    call s:assert.window_count(1)
endfunction

function! s:suite.not_open_prompt_from_prompt()
    Flompt
    Flompt
    call s:assert.window_count(2)
endfunction

function! s:suite.not_open_two_prompt_from_same_window()
    Flompt

    wincmd p
    Flompt

    call s:assert.window_count(2)
endfunction

function! s:suite.nop_logger()
    call flompt#logger#clear()

    Flompt

    Flompt send
endfunction
