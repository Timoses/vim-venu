" Dict of menuKey -> function
let s:menus={}
" List of sorted menu keys (sorted by order of function in menu)
let s:menuKeysSorted={}
" List of menu names
let s:menuKeyNames={}
function! venu#registerMenu(filetype, menu) abort
    if type('')!=type(a:filetype)
        throw "Filetype needs to be a string"
    endif
    if has_key(s:menus, a:filetype)
        return
    endif

    let l:menuKeys = sort(keys(a:menu), "venu#util#sortByValues", a:menu)

    let s:menus[a:filetype] = a:menu
    let s:menuKeysSorted[a:filetype] = l:menuKeys
    let s:menuKeyNames[a:filetype] = map(copy(l:menuKeys), {key,item ->
                \substitute(
                \substitute(item, "\\u", " \\l&", "gc"),
                \"\^.", "\\u&", "g")})
endfunction

function! venu#register(...) abort

endfunction

function! venu#printMenu() abort
    if !has_key(s:menus, &ft)
        echo "No menu available for filetype " . &ft
        return
    endif

    echohl Title
    echo toupper(&ft) . ' commands:'
    echohl None
    let l:menuIt = 0
    for cmd in s:menuKeyNames[&ft]
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

    call s:menus[&ft][s:menuKeysSorted[&ft][l:char-1]]()
endfunction
