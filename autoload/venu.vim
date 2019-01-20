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
"       Position preference of '0' means no preference.
"   priority:
"       Order and positional priority. Lower numbers have higher priority.
"       Priority of '0' means no priority.
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

    call add(a:menu.items, l:newitem)
    call venu#sort(a:menu.items)
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

        call venu#mergeMenus(l:menu, a:menu)
    else
        call extend(a:menu.filetypes, l:filetypes)
        call add(s:menus, a:menu)
        call venu#sort(s:menus)
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
function! venu#mergeMenus(target, merging)
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

            if venu#isMenu(l:found.cmd) && venu#isMenu(merge.cmd)
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
                call venu#mergeMenus(l:found.cmd, merge.cmd)
            elseif l:found.cmd != merge.cmd
                " Trying to add an item with the same name but a different cmd
                " Only allow this if no overlap of filetypes
                let l:samefts = []
                for ft in merge.filetypes
                    let l:sameftIdx = index(l:found.filetypes, ft)
                    if l:sameftIdx >= 0
                        call add(l:samefts, get(l:found.filetypes, l:sameftIdx))
                    endif
                endfor
                if l:found.filetypes == merge.filetypes || len(l:samefts) > 0
                    echoerr "Collision of menu items: Same name used: \"" . merge.name . "\" for the same filetypes \"" . l:samefts
                else
                    call add(a:target.items, merge)
                endif
            else " cmd are equal
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
            endif
        else
            call add(a:target.items, merge)
    endfor

    call venu#sort(a:target.items)
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

    let l:menuIterator = 1
    for item in l:filtered
        echo l:menuIterator . ". " . item.name .
                    \ (&verbose > 0 ? " (pos_pref: " . item.pos_pref .
                    \ " , priority: " . item.priority . ")"
                    \ : "")
        let l:menuIterator = l:menuIterator + 1
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
    elseif venu#isMenu(l:choice.cmd)
        call venu#printInternal(l:choice.cmd.name, l:choice.cmd.items)
        return
    endif
endfunction

" Compares first by pos_pref and then by priority.
" pos_pref and priority values of 0 are are always last.
function! venu#compare(i1, i2)
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
function! venu#sort(items)
    if len(a:items) == 0
        return
    endif

    call sort(a:items, "venu#compare")

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

function! venu#isMenu(object)
    return type(a:object)==v:t_dict && has_key(a:object, 'name')
            \&& has_key(a:object, 'pos_pref') && type(a:object.pos_pref)==v:t_number
            \&& has_key(a:object, 'priority') && type(a:object.priority)==v:t_number
            \&& has_key(a:object, 'filetypes') && type(a:object.filetypes)==v:t_list
            \&& has_key(a:object, 'items') && type(a:object.items)==v:t_list
endfunction

