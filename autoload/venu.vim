let s:venupaths =
    \filter(split(&runtimepath,','), 'match(v:val, "vim-venu") > 0')
if len(s:venupaths) == 0
    let s:VERSION = 'v?'
else
    let s:VERSION = readfile(s:venupaths[0].'/version')[0]
endif

" a menu should have the following structure:
" {
"   name: <string>,
"   pos_pref:
"       Positional preference. Menus/Items with a higher 'priority' win.
"       Losers are positioned after winner.
"   priority:
"       Order and positional priority. Lower numbers have higher priority.
"   filetypes: <[<string>, <string>, ...],
"   items: [
"    { name: <string>,
"           Name of the menu.
"      cmd: <string> or <funcref> or <menu>
"           Cmd to be executed or menu to be displayed when selecting this
"           item.
"      pos_pref: <number>
"           See above menu property 'pos_pref'.
"      priority: <number>
"           See above menu property 'priority'.
"      filetypes: [<string>, <string>, ...]
"    }]
let s:menus=[]

" Optional arguments '...': pos_pref, priority
function! venu#create(name, ...) abort
    if a:0 > 0 && type(a:1)!=v:t_number
        echoerr "Positional preference pos_pref has to be a number"
    endif
    if a:0 > 1 && type(a:2)!=v:t_number
        echoerr "Priority has to be a number"
    endif

    let l:pos_pref = a:0 > 0 ?  a:1 : 0

    let l:priority = a:0 > 1 ? a:2 : 0
    if l:priority == 0
        let l:priority = 1000
    elseif l:priority > 999
        echoerr "Priority " l:priority " exceeds maximum 999"
    endif

    let l:menu = {'name': a:name,
                \'filetypes': [],
                \'pos_pref': l:pos_pref, 'priority': l:priority,
                \'items': []}
    return l:menu
endfunction

" Optional arguments '...': pos_pref, priority, filetypes
function! venu#addItem(menu, name, cmd, ...) abort
    if a:0 > 3
        echoerr "Only optional argument allowed: pos_pref, priority and <filetype> or [<filetype>, ...]"
    endif

    if a:0 > 0 && type(a:1)!=v:t_number
        echoerr "Positional preference pos_pref has to be a number"
    endif
    if a:0 > 1 && type(a:2)!=v:t_number
        echoerr "Priority has to be a number"
    endif
    if a:0 == 3 && type(a:3)!=v:t_string && type(a:3)!=v:t_list
        echoerr "<filetype> must be a string or a list of strings"
    endif

    let l:pos_pref = a:0 > 0 ?  a:1 : 0
    let l:priority = a:0 > 1 ? a:2 : 0
    let l:filetypes = a:0 > 2 ? (type(a:3) == v:t_string ? [a:3] : a:3) : []

    if l:priority == 0
        let l:priority = 1000
    elseif l:priority > 999
        echoerr "Priority " l:priority " exceeds maximum 999"
    endif

    let l:newitem = { 'name': a:name, 'cmd': a:cmd,
                                \'pos_pref': l:pos_pref,
                                \'priority': l:priority,
                                \'filetypes': l:filetypes}

    call venu#addSorted(a:menu['items'], l:newitem)
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
            let l:menu.filetypes = []
        else
            for ft in l:filetypes
                if index(l:menu.filetypes, ft) < 0
                    call add(l:menu.filetypes, ft)
                endif
            endfor
        endif
    else
        call extend(a:menu.filetypes, l:filetypes)
        call venu#addSorted(s:menus, a:menu)
    endif
endfunction

function! venu#print() abort
    let l:availableMenus = filter(copy(s:menus),
            \"len(v:val.filetypes) == 0 || index(v:val.filetypes, &ft) >= 0")

    if len(l:availableMenus) == 1
        call venu#printInternal(l:availableMenus[0].name,
                                    \l:availableMenus[0].items)
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
    echo a:name . " (V̂enu " . s:VERSION . ")"
    echohl None

    let l:filtered = filter(copy(a:itemsOrMenus),
            \"len(v:val.filetypes)==0 || index(v:val.filetypes, &ft) >= 0")

    let l:menuIterator = 0
    for item in l:filtered
        let l:menuIterator = l:menuIterator + 1
        echo l:menuIterator . ". " . item.name .
                    \ (&verbose > 0 ? " (pos_pref: " . item.pos_pref .
                    \ " , priority: " . item.priority . ")"
                    \ : "")
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
    if type(l:choice)==v:t_dict && has_key(l:choice, 'items')
        call venu#printInternal(l:choice.name, l:choice.items)
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
        call venu#printInternal(l:choice.cmd.name, l:choice.cmd.items)
        return
    endif
endfunction

function! venu#addSorted(items, item)
    " pos_pref ranges from 1-x, with 0 meaning no preference
    let l:idx = a:item.pos_pref == 0 ? 0 : a:item.pos_pref

    " Item should be inserted at l:idx unless the current item
    " at l:idx has a higher priority. Then item pos_ref is ignored and item is
    " inserted before the next item with a lower priority.
    for item in a:items[l:idx : -1]
        if a:item.priority < item.priority
            break
        endif
        let l:idx = l:idx + 1
    endfor

    call insert(a:items, a:item, l:idx)
endfunction
