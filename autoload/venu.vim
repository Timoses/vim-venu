let s:menus={}
function! venu#registerMenu(filetype, menu) abort
    if type('')!=type(a:filetype)
        throw "Filetype needs to be a string"
    endif
    if has_key(s:menus, a:filetype)
        return
    endif

    let s:menus[a:filetype] = venu#prepareMenu(a:menu)
endfunction

function! venu#prepareMenu(menu) abort
    let l:menuKeys = sort(keys(a:menu), "venu#util#sortByValues", a:menu)
    let l:res = {}
    let l:res = a:menu
    let l:res['_keys'] = l:menuKeys
    let l:res['_names'] = map(copy(l:menuKeys), {key,item ->
                \substitute(
                \substitute(item, "\\u", " \\l&", "gc"),
                \"\^.", "\\u&", "g")})
    return l:res
endfunction

function! venu#printMenu() abort
    if !has_key(s:menus, &ft)
        echo "No menu available for filetype " . &ft
        return
    endif

    call venu#printMenuInternal(s:menus[&ft], toupper(&ft))
endfunction

function! venu#printMenuInternal(menu, title) abort
    echohl Title
    echo a:title . ' commands:'
    echohl None
    let l:menuIt = 0
    for cmd in a:menu['_names']
        let l:menuIt = l:menuIt + 1
        echo l:menuIt . ". " . l:cmd
    endfor
    echo "0. Exit"

    let l:char = nr2char(getchar())

    if l:char == "\<ESC>" || l:char == 0
        redrawstatus
        return
    endif

    while l:char-1 < 0 || l:char-1 >= l:menuIt
        let l:char = nr2char(getchar())
        if l:char == "\<ESC>" || l:char == 0
            redrawstatus
            return
        endif
    endwhile

    redrawstatus

    let l:key = a:menu['_keys'][l:char-1]
    let l:name = a:menu['_names'][l:char-1]
    let l:Submenu = a:menu[l:key]
    if type(l:Submenu)==type({})
        " Call buffered submenu
        call venu#printMenuInternal(l:Submenu, a:title . " " . l:name)
    else
        let l:res = l:Submenu()
        if type(0)==type(l:res)
            return
        elseif type(l:res)==type({})
            " Buffer submenu
            let a:menu[l:key] = venu#prepareMenu(l:res)
            call venu#printMenuInternal(a:menu[l:key], a:title . " > " . l:name)
        endif
    endif
endfunction
