" Menu Dictionary structure
" { 'menu1' : { 'name': 'name1', 'func': 'func1' },
"   'menu2' : ... }
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
    let l:res = {}
    let l:res = a:menu

    call map(l:res, { key, val -> {'name':
                \substitute(
                \substitute(key, "\\u", " \\l&", "gc"),
                \"\^.", "\\u&", "g")
                \, 'func': val} } )

    let l:sortedKeys = sort(keys(a:menu), "venu#util#sortByValues", a:menu)
    let l:res['_sortedKeys'] = l:sortedKeys

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
    let l:menuIterator = 0
    for key in a:menu['_sortedKeys']
        let l:menuIterator = l:menuIterator + 1
        echo l:menuIterator . ". " . a:menu[key].name
    endfor
    echo "0. Exit"

    let l:char = nr2char(getchar())

    if l:char == "\<ESC>" || l:char == 0
        redrawstatus
        return
    endif

    " Poll input as long as input invalid
    while l:char-1 < 0 || l:char-1 >= l:menuIterator
        let l:char = nr2char(getchar())
        if l:char == "\<ESC>" || l:char == 0
            redrawstatus
            return
        endif
    endwhile

    redrawstatus

    let l:key = a:menu['_sortedKeys'][l:char-1]
    let l:name = a:menu[l:key]['name'] " a:menu['_names'][l:char-1]
    let l:Submenu = a:menu[l:key]['func']
    if type(l:Submenu)==type({})
        " Call buffered submenu
        call venu#printMenuInternal(l:Submenu, a:title . " " . l:name)
    else
        let l:res = l:Submenu()
        if type(0)==type(l:res)
            return
        elseif type(l:res)==type({})
            " Buffer submenu
            let a:menu[l:key]['func'] = venu#prepareMenu(l:res)
            call venu#printMenuInternal(a:menu[l:key]['func'],
                                        \a:title . " > " . l:name)
        endif
    endif
endfunction
