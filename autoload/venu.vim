" a menu should have the following structure:
" {
"   name: <string>,
"   _filetypes: <[<string>, <string>, ...],
"   _items: [
"    { name: <string>,
"      cmd: <string> or <funcref> or <menu>
"      _filetypes: [<string>, <string>, ...]
"    }]
let s:menus=[]

function! venu#create(name) abort
    let l:menu = {'name': a:name, '_filetypes': [], '_items': []}
    return l:menu
endfunction

function! venu#addItem(menu, name, cmd, ...) abort
    if a:0 > 1
        echoerr "Only optional argument allowed: <filetype> or [<filetype>, ...]"
    elseif a:0 == 1 && type(a:1)!=v:t_string && type(a:1)!=v:t_list
        echoerr "<filetype> must be a string or a list of strings"
    endif
    if a:0 > 0 && type(a:1)==v:t_string
        let a:1 = [a:1]
    endif

    call add(a:menu['_items'], { 'name': a:name, 'cmd': a:cmd,
                                \'_filetypes': a:0 > 0 ? a:1 : []})
endfunction

function! venu#register(menu, ...) abort
    if a:0 > 1
        echoerr "Only optional argument allowed: <filetype> or [<filetype>, ...]"
    elseif a:0 == 1 && type(a:1)!=v:t_string && type(a:1)!=v:t_list
        echoerr "<filetype> must be a string or a list of strings"
    endif

    let l:filetypes = []
    if a:0 > 0
        if type(a:1)==v:t_string
            let l:filetypes = [a:1]
        elseif type(a:1)==v:t_list
            let l:filetypes = a:1
        endif
    endif

    let l:found = index(map(copy(s:menus), "v:val.name"), a:menu.name)

    if l:found >= 0
        let l:menu = get(s:menus, l:found)

        " Calling register without ft specification -> show for all
        if len(l:filetypes) == 0
            let l:menu._filetypes = []
        else
            for ft in l:filetypes
                if index(l:menu._filetypes, ft) < 0
                    add(l:menu._filetypes, ft)
                endif
            endfor
        endif
    else
        call extend(a:menu._filetypes, l:filetypes)
        call add(s:menus, a:menu)
    endif
endfunction

function! venu#print() abort
    let l:availableMenus = filter(copy(s:menus),
            \"len(v:val._filetypes) == 0 || index(v:val._filetypes, &ft) >= 0")

    if len(l:availableMenus) == 1
        call venu#printInternal(l:availableMenus[0].name,
                                    \l:availableMenus[0]._items)
    elseif len(l:availableMenus) > 1
        call venu#printInternal("Menu", l:availableMenus)
    else
        echo "No menu available"
    endif
endfunction

" Prints menu and polls user for a choice.
" Handles both: a list of menus for submenus
"               and a single menu given its items
function! venu#printInternal(name, itemsOrMenus) "menu, title) abort
    echohl Title
    echo a:name
    echohl None

    let l:filtered = filter(copy(a:itemsOrMenus),
            \"len(v:val._filetypes)==0 || index(v:val._filetypes, &ft) >= 0")

    let l:menuIterator = 0
    for item in l:filtered
        let l:menuIterator = l:menuIterator + 1
        echo l:menuIterator . ". " . item.name
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

    let l:choice = l:filtered[l:char-1]

    " We are dealing with a menu
    if type(l:choice)==v:t_dict && has_key(l:choice, '_items')
        call venu#printInternal(l:choice.name, l:choice._items)
        return
    endif

    " It's a menu item!
    if type(l:choice.cmd)==v:t_func
        let l:result = l:choice.cmd()
        return
    elseif type(l:choice.cmd)==v:t_string
        exe l:choice.cmd
        return
    " A submenu
    elseif type(l:choice.cmd)==v:t_dict
        call venu#printInternal(l:choice.cmd.name, l:choice.cmd._items)
        return
    endif
endfunction
