let s:menus={}
function! venu#registerMenu(filetype, menu) abort
    if type('')!=type(a:filetype)
        throw "Filetype needs to be a string"
    endif
    if has_key(s:menus, a:filetype)
        return
    endif

    let s:menus[a:filetype] = a:menu
endfunction

function! venu#printMenu() abort
    if !has_key(s:menus, &ft)
        echo "No menu available for filetype " . &ft
        return
    endif

    let l:menu = s:menus[&ft]

    echohl Title
    echo &ft . ' commands:'
    echohl None
    let l:cmds = keys(s:menus[&ft])
    let l:menuIt = 0
    for cmd in cmds
        let l:menuIt = l:menuIt + 1
        echo l:menuIt . ". " . l:cmd
    endfor
    let l:choice = nr2char(getchar()) - 1
    redrawstatus
    call l:menu[l:cmds[l:choice]]()
endfunction
