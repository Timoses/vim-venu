# Importing vim menus to V̂enu

V̂enu can import vim's native menu entries (`:help menu`). This document
provides reference for `vim#native` module used for this purpose.

## Functions

---

```vim
venu#native#import([menu_filter])
```

Imports VIM native menu entries to V̂enu.

Optionally takes a callback function `menu_filter` used for filtering which
entries to import and modifying menu entries before they get imported. By
default, the value of `g:venu_native_menu_filter` is used if provided,
otherwise `venu#native#defaultFilter` is used. See [Filtering Menus](#filtering-menus)
section for more details about menu filters.

---

```vim
venu#native#parseMenu([menu_cmd])
```

Parses output of vim menu printing command and returns a list of menu
dictionaries.

Optional argument `menu_cmd` controls which command is used to retrieve vim's
native menu. By default, the value of `g:venu_native_menu_cmd` is used if provided,
otherwise `amenu` is used.

Note that returned menu dictionaries have a different format than those used by
V̂enu (see `venu#native#createVenuFromMenu`). Menu dictionaries returned by this function have these keys:

- `name`: Name of the menu entry. It doesn't include right aligned text
(provided by `desc`) or ampersand preceding the shortcut character (provided
by `shortcut`).
- `desc`: Right aligned text of the menu entry, if there is one. This is the
portion following `<TAB>` special character in the menu entry name.
- `priority`: Priority of the menu entry. If two menus are in the same level,
the one with greater priority value will be closer to the right side (see `:help
menu-property`). This is similar to V̂enu's use of priority where menus with greater
priority values are rendered closer to the bottom.
- `shortcut`: Shortcut letter denoted with a preceding ampersand (&) in the
menu name.
- `submenus`: A list of menu entry dictionaries for submenus.
A submenu entry has the same keys as its parent menu (i.e. this list).
- `mode`: A dictionary of modes (`n`, `v`, `i`...) defined for this menu. Each
mode value also keeps a dictionary where `flag` keeps the flag of mode and
`cmd` keeps the command that will be executed when the menu entry is selected.
- `is_separator`: Whether the menu is just a seperator. vim treats menus with
names beginning and ending with dash (-) as separators.

---

```vim
venu#native#createVenuFromMenu(menu)
```

Converts native menu dictionary to V̂enu's dictionary format.

---

```vim
venu#native#defaultFilter(key, menu)
```

Recursively removes separators and menus without any commands or submenus. See
[Filtering Menus](#filtering-menus) section for more details about menu filters.

## Configurations

```vim
" Default menu filter used for importing
g:venu_native_menu_filter = function('venu#native#defaultFilter')

" Default menu command used for listing vim native menus
g:venu_native_menu_cmd = 'amenu'
```

## Filtering Menus

Menu entries can be filtered (or even modified) before being imported. This is
done through menu filtering functions. A menu filter function is expected to
take two arguments: `key`, the index of menu entry, and `menu`, the menu
dictionary. If the function returns true, `menu` will be imported. `menu`
argument can be modified inside this function to modify any properties of the
menu entry before importing. See `venu#native#parseMenu` for all properties
defined in a menu dictionary.

This function will be called for only menus on the root level. It is left to
the implementation of this function to traverse over submenus of root menus.
Note that submenus are accessible and modifiable through `menu.submenus`
property.

## Example

Import only 'PO-Editing' menu while removing separators and empty submenus it
may include:

```vim
function! MyVenuFilter(key, menu)
  return a:menu.name == 'PO-Editing'
    \ && venu#native#defaultFilter(a:key, a:menu)
endfunction

call venu#native#import(function('MyVenuFilter'))

" or:
"
" g:venu_native_menu_filter = function('MyVenuFilter')
" call venu#native#import()
```
