" a:key is needed though unused, as this function is called by vim's filter()
function! venu#native#defaultFilter(key, menu) abort
  if a:menu.is_separator
    return 0
  endif

  if len(a:menu.submenus) > 0
    call filter(a:menu.submenus, function("venu#native#defaultFilter"))
    return len(a:menu.submenus) > 0
  endif

  return has_key(a:menu.mode, "n")
endfunction

let s:menu_filter = get(g:, "venu_native_menu_filter",
                      \ function("venu#native#defaultFilter"))
let s:menu_cmd    = get(g:, "venu_native_menu_cmd", "amenu")

if type(s:menu_filter) != v:t_func
  echoerr "Type of g:venu_menu_filter must be Funcref"
endif

function! s:ParseMenuLine(line) abort
  let l:until_eol_regex = '(.{-})\s*\r?$'
  let l:menu_regex = '\v^( *)(-?\d+) ' . l:until_eol_regex
  let l:cmd_regex = '\v^( *)([a-z])([*& ][s ][- ]) ' . l:until_eol_regex
  let l:match = matchlist(a:line, l:menu_regex)
  if len(l:match) > 0
    return [len(l:match[1]), l:match[2], l:match[3]]
  endif

  let l:match = matchlist(a:line, l:cmd_regex)
  if len(l:match) == 0
    return []
  endif
  return [len(l:match[1]), l:match[2], l:match[3], l:match[4]]
endfunction

" Extract <TAB>=^I separated description from name if there exists one
function! s:ExtractDesc(name) abort
  let l:tmp = matchlist(a:name, '\v^(.{-})\^I(.{-})$')
  if len(l:tmp) == 0
    let l:name = a:name
    let l:desc = ''
  else
    let l:name = l:tmp[1]
    let l:desc = l:tmp[2]
  endif
  return [l:name, l:desc]
endfunction

" Extract &Shortcut and replace escaped ampersands (&&).
function! s:ExtractShortcut(name) abort
  " These are not some curse words, just some regex to match first unescaped &.
  let l:tmp = matchend(a:name, '\v(\&)@<!%(\&\&)*(\&)(\&)@!')
  if l:tmp < 0
    let l:shortcut = ''
    let l:name = a:name
  else
    let l:shortcut = a:name[l:tmp]
    let l:name = substitute(
    \   strpart(a:name, 0, l:tmp - 1).strpart(a:name, l:tmp),
    \   "&&", "&", "g"
    \ )
  endif
  return [l:name, l:shortcut]
endfunction

function! venu#native#parseMenu(...) abort
  if a:0 == 0
    let l:menu_cmd = s:menu_cmd
  elseif a:0 == 1
    let l:menu_cmd = a:1
  else
    echoerr "Only optional argument allowed is menu command."
  endif
  let l:menu_str = execute(l:menu_cmd)
  let l:root = []
  let l:prevdepth = 0

  for l:line in split(l:menu_str, '\n')
    let l:line = s:ParseMenuLine(l:line)

    " If line matches a menu title or a menu command
    if len(l:line) > 0
      " If line matches a menu title
      if match(l:line[1], '\v^\d+$') == 0
        let l:indent   = l:line[0]
        let l:depth    = l:indent / 2
        let l:priority = str2nr(l:line[1])

        let l:tmp  = s:ExtractDesc(l:line[2])
        let l:name = l:tmp[0]
        let l:desc = l:tmp[1]

        let l:tmp      = s:ExtractShortcut(l:name)
        let l:name     = l:tmp[0]
        let l:shortcut = l:tmp[1]

        let l:menu = {
              \  'name': l:name,
              \  'desc': l:desc,
              \  'priority': l:priority,
              \  'shortcut': l:shortcut,
              \  'submenus': [],
              \  'mode': {},
              \  'is_separator': l:name =~ '^-.*-$',
              \}

        if l:depth == 0
          call add(l:root, l:menu)
          let l:stack = []
        elseif l:depth > l:prevdepth
          call assert_true(l:depth - l:prevdepth == 1)
          call add(l:stack[-1].submenus, l:menu)
        elseif l:depth == l:prevdepth
          call remove(l:stack, -1)
          call add(l:stack[-1].submenus, l:menu)
        else " l:depth < l:prevdepth
          call remove(l:stack, -(l:prevdepth - l:depth + 1), -1)
          call add(l:stack[-1].submenus, l:menu)
        endif

        call add(l:stack, l:menu)
        let l:prevdepth = l:depth

      " Else (if line matches a menu command)
      else
        " Ignore l:line[0] (indent) since it's not used
        let l:mode      = l:line[1]
        let l:mode_flag = l:line[2]
        let l:cmd       = l:line[3]
        let l:stack[-1].mode[l:mode] = {'flag': l:mode_flag, 'cmd': l:cmd}
      endif
    endif
  endfor
  return l:root
endfunction

function! venu#native#createVenuFromMenu(menu) abort
  " let l:venu = venu#create(a:menu.name, 0, a:menu.priority)
  let l:venu = venu#create(a:menu.name)

  for l:submenu in a:menu.submenus
    if len(l:submenu.submenus) > 0
      let l:subvenu = venu#native#createVenuFromMenu(l:submenu)
      call venu#addItem(l:venu, l:submenu.name, l:subvenu)
    elseif has_key(l:submenu.mode, "n")
      " Dirty trick adapted from: https://stackoverflow.com/a/16007121
      " Necessary to escape special key characters (<CR>, <ESC> etc.)
      let l:cmd = eval('"'. escape(l:submenu.mode["n"].cmd, '\"<') . '"')
      call venu#addItem(l:venu, l:submenu.name, "normal " . l:cmd)
    endif
  endfor

  return l:venu
endfunction

function! venu#native#import(...) abort
  if a:0 == 0
    let l:Filter = s:menu_filter
  elseif a:0 == 1
    let l:Filter = a:1
  else
    echoerr "Only optional argument allowed is filter."
  endif
  let l:menus = venu#native#parseMenu()
  call filter(l:menus, l:Filter)
  for l:menu in l:menus
    call venu#register(venu#native#createVenuFromMenu(l:menu))
  endfor
endfunction

function! s:DebugTraverse(entry, indent) abort
  let l:spaces = ''
  let l:i = 0
  while l:i < a:indent
    let l:spaces .= ' '
    let l:i += 1
  endwhile

  for l:entry in a:entry
    echo l:spaces."name='".l:entry.name
          \ ."', desc='".l:entry.desc
          \ ."', scut='".l:entry.shortcut
          \ ."', prio=".string(l:entry.priority)
          \ .", is_sep=".string(l:entry.is_separator)
          \ .", mode=".string(l:entry.mode)
    call s:DebugTraverse(l:entry.submenus, a:indent + 1)
  endfor
endfunction
