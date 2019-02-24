let s:venupaths =
    \filter(split(&runtimepath,','), 'match(v:val, "vim-venu") > 0')
if len(s:venupaths) == 0
    let s:VERSION = 'v?'
else
    let s:VERSION = readfile(s:venupaths[0].'/version')[0]
endif

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

    let l:newitem = { 'name': a:name, 'cmd': a:cmd,
                                \'pos_pref': l:pos_pref,
                                \'priority': l:priority,
                                \'filetypes': l:filetypes}

    call s:add(a:menu.items, l:newitem)
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

    call extend(a:menu.filetypes, l:filetypes)

    call s:add(s:menus, a:menu)
endfunction

function! venu#unregisterAll()
    call remove(s:menus, 0, -1)
endfunction

function! s:add(to, itemOrMenu)
    let l:foundIdx = index(map(copy(a:to), "v:val.name"), a:itemOrMenu.name)

    if l:foundIdx >= 0
        let l:found = get(a:to, l:foundIdx)
        call s:merge(l:found, a:itemOrMenu)
    else
        call add(a:to, a:itemOrMenu)
        call s:sort(a:to)
    endif
endfunction

function! s:merge(targetItemOrMenu, merging) abort
    if s:isMenu(a:targetItemOrMenu) && s:isMenu(a:merging)
        call s:mergeMenus(a:targetItemOrMenu, a:merging)
    elseif s:isItem(a:targetItemOrMenu) && s:isItem(a:merging)
        call s:mergeItems(v:null, a:targetItemOrMenu, a:merging)
    else
        " TODO: This would be possible when no filetypes collide
        echoerr "Currently unable to merge item and menu"
    endif
endfunction

" Merges 'merging' into 'target'.
" Following merging rules exist:
"   * priority: The higher priority (lower number) is chosen
"   * pos_pref: The lower pos_pref is chosen
"   * filetypes: are merged together
" For items with name collision:
"   * priority, pos_pref and filetypes of the item are adjusted as above
"   * same cmd -> no issue
"   * cmd differs -> only allow if items' filetypes don't collide
function! s:mergeMenus(target, merging) abort
    call assert_true(s:isMenu(a:target) && s:isMenu(a:merging), "Only merging menus allowed in mergeMenus!")

    let a:target.pos_pref =
                \ min([a:target.pos_pref, a:merging.pos_pref]) == 0 ?
                \ max([a:target.pos_pref, a:merging.pos_pref]) :
                \ min([a:target.pos_pref, a:merging.pos_pref])
    let a:target.priority =
                \ min([a:target.priority, a:merging.priority]) == 0 ?
                \ max([a:target.priority, a:merging.priority]) :
                \ min([a:target.priority, a:merging.priority])
    let a:target.filetypes =
                \ uniq(sort(a:target.filetypes + a:merging.filetypes))

    for merge in a:merging.items
        " Entry with same name exists?
        let l:idx = index(map(copy(a:target.items), "v:val.name"), merge['name'])
        if l:idx >= 0
            let l:found = get(a:target.items, l:idx)

            if s:isMenu(l:found.cmd) && s:isMenu(merge.cmd)
                let l:found.pos_pref =
                    \ min([l:found.pos_pref, merge.pos_pref]) == 0 ?
                    \ max([l:found.pos_pref, merge.pos_pref]) :
                    \ min([l:found.pos_pref, merge.pos_pref])
                let l:found.priority =
                    \ min([l:found.priority, merge.priority]) == 0 ?
                    \ max([l:found.priority, merge.priority]) :
                    \ min([l:found.priority, merge.priority])
                let l:found.filetypes =
                        \ uniq(sort(l:found.filetypes + merge.filetypes))
                call s:mergeMenus(l:found.cmd, merge.cmd)
            elseif s:isItem(l:found) && s:isItem(merge)
                call s:mergeItems(a:target, l:found, merge)
            else
                echoerr "Currently unable to merge item and menu together"
            endif
        else
            call add(a:target.items, merge)
        endif
    endfor

    call s:sort(a:target.items)
endfunction

" Merges two items (target and merging) together
function! s:mergeItems(targetMenu, target, merging) abort
    call assert_true(s:isItem(a:target) && s:isItem(a:merging), "Only merging items allowed in mergeItems!")

    if s:isMenu(a:target.cmd) && s:isMenu(a:merging.cmd)
        call s:mergeMenus(a:target.cmd, a:merging.cmd)
        return
    endif

    let l:samefts = []
    for ft in a:merging.filetypes
        let l:sameftIdx = index(a:target.filetypes, ft)
        if l:sameftIdx >= 0
            call add(l:samefts, get(a:target.filetypes, l:sameftIdx))
        endif
    endfor

    " Filetype collision?
    if len(l:samefts) > 0 || a:target.filetypes == a:merging.filetypes
        if a:target.cmd != a:merging.cmd
            echoerr "Collision of menu items: Same name used: \"" . a:merging.name . "\" for the same filetypes \"" . string(l:samefts)
        else
            " TODO: Could also create a new item which is valid
            " only for the l:samefts and do below merging.
            " Then, for the other filetypes of each item, the
            " settings can remain the same (remove l:samefts from
            " a:target and a:merging items' filetypes)
            let a:target.pos_pref =
                \ min([a:target.pos_pref, a:merging.pos_pref]) == 0 ?
                \ max([a:target.pos_pref, a:merging.pos_pref]) :
                \ min([a:target.pos_pref, a:merging.pos_pref])
            let a:target.priority =
                \ min([a:target.priority, a:merging.priority]) == 0 ?
                \ max([a:target.priority, a:merging.priority]) :
                \ min([a:target.priority, a:merging.priority])
            let a:target.filetypes =
                \ uniq(sort(a:target.filetypes + a:merging.filetypes))
        endif
    else
        " If no filetype collision exists, merging these
        " items won't matter as both items will never be displayed
        " together.
        call add(a:target.items, a:merging)
    endif
endfunction

function! venu#print() abort
    let s:printCallback = get(g:, "venu_print_callback",
                \ function("s:print"))
    let s:selectCallback = get(g:, "venu_select_callback",
                \ function("s:select"))
    let s:formatEntryCallback = get(g:, "venu_format_entry_callback",
                \ function("s:formatEntry"))

    let l:availableMenus = filter(copy(s:menus),
            \"len(v:val.filetypes) == 0 || index(v:val.filetypes, &ft) >= 0")

    if len(l:availableMenus) == 1
        call s:startVenu(l:availableMenus[0].name,
                                    \l:availableMenus[0].items)
    elseif len(l:availableMenus) > 1
        call s:startVenu("Menu", l:availableMenus)
    else
        echo "No menu available"
    endif
endfunction

function! s:startVenu(name, itemsOrMenus)
    let l:choices = filter(copy(a:itemsOrMenus),
            \"len(v:val.filetypes)==0 || index(v:val.filetypes, &ft) >= 0")
    call s:printCallback(a:name, l:choices)
    let l:choice = s:selectCallback(l:choices)

    if type(l:choice) != v:t_number
        call s:executeSelection(l:choice)
    endif
endfunction

function! s:print(name, itemsOrMenus) abort
    echohl Title
    echo a:name . " (V̂enu " . s:VERSION . ")"
    echohl None

    let l:menuIterator = 1
    for item in a:itemsOrMenus
        echo s:formatEntryCallback(l:menuIterator, item)
        let l:menuIterator = l:menuIterator + 1
    endfor
    echo "0. Exit"
endfunction

function! s:formatEntry(rowNum, entry)
        return a:rowNum . ". " . a:entry.name .
                    \ (&verbose > 0 ? " (pos_pref: " . a:entry.pos_pref .
                    \ " , priority: " . a:entry.priority . ")"
                    \ : "")
endfunction

function! s:select(choices)
    let l:char = nr2char(getchar())

    if l:char == "\<ESC>" || l:char == 0
        redrawstatus
        return
    endif

    " Poll input as long as input invalid
    while l:char <= 0 || l:char > len(a:choices)
        let l:char = nr2char(getchar())
        if l:char == "\<ESC>" || l:char == 0
            redrawstatus
            return
        endif
    endwhile

    redrawstatus

    return a:choices[l:char-1]
endfunction

function! s:executeSelection(choice)
    if s:isMenu(a:choice)
        call s:startVenu(a:choice.name, a:choice.items)
        return
    endif

    " It's a menu item!
    if type(a:choice.cmd)==v:t_func
        let l:result = a:choice.cmd()
        return
    elseif type(a:choice.cmd)==v:t_string
        exe a:choice.cmd
        return
    " A submenu
    elseif s:isMenu(a:choice.cmd)
        call s:startVenu(a:choice.cmd.name, a:choice.cmd.items)
        return
    endif
endfunction


" Compares first by pos_pref and then by priority.
" pos_pref and priority values of 0 are are always last.
function! s:compare(i1, i2)
    if a:i1.pos_pref == a:i2.pos_pref
        if a:i1.priority < a:i2.priority
            return a:i1.priority == 0 ? 1 : -1
        elseif a:i1.priority > a:i2.priority
            return a:i2.priority == 0 ? -1 : 1
        else
            return 0
        endif
    elseif a:i1.pos_pref < a:i2.pos_pref
        return a:i1.pos_pref == 0 ? 1 : -1
    elseif a:i1.pos_pref > a:i2.pos_pref
        return a:i2.pos_pref == 0 ? -1 : 1
    endif
endfunction

" Tries to sort items so that each pos_pref is the items position in
" the array. 'pos_pref' of 0 is used as a filler when no other items
" are available.
" In case there is no item with 'pos_pref' = 0 a dummy is used (empty menu
" entry)
" Example:
"   Items with 'pos_pref' values: [5,2,0,0]
"   Will be sorted into:          [0,2,0,x,5]
"   x denots a dummy entry
function! s:sort(items)
    if len(a:items) == 0
        return
    endif

    call sort(a:items, "s:compare")

    let l:dummy = {'name': "", 'cmd': "", 'pos_pref': 0, 'priority': 0, 'filetypes': []}
    let l:zeropos = filter(copy(a:items), "v:val.pos_pref == 0 && v:val != l:dummy")

    let l:items = []
    let l:idx = 1
    for item in a:items
        while item.pos_pref > l:idx
            if len(l:zeropos) > 0
                call add(l:items, l:zeropos[0])
                let l:zeropos = l:zeropos[1:-1]
            else
                call add(l:items, l:dummy)
            end
            let l:idx = l:idx + 1
        endwhile

        if item.pos_pref > 0
            call add(l:items, item)
            let l:idx = l:idx + 1
        else
            break
        end
    endfor

    if len(l:zeropos) > 0
        call extend(l:items, l:zeropos)
    endif

    call remove(a:items, 0, -1)
    call extend(a:items, l:items)

endfunction

function! s:isMenu(object)
    return s:isVenuObject(a:object)
            \&& has_key(a:object, 'items') && type(a:object.items)==v:t_list
endfunction

function! s:isItem(object)
    return s:isVenuObject(a:object)
            \&& has_key(a:object, 'cmd')
endfunction

function! s:isVenuObject(object)
    return type(a:object)==v:t_dict && has_key(a:object, 'name')
            \&& has_key(a:object, 'pos_pref') && type(a:object.pos_pref)==v:t_number
            \&& has_key(a:object, 'priority') && type(a:object.priority)==v:t_number
            \&& has_key(a:object, 'filetypes') && type(a:object.filetypes)==v:t_list
endfunction

