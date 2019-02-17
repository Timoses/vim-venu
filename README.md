# V̂enu

<!-- vim-markdown-toc GFM -->

* [Install](#install)
* [Features](#features)
* [Example Usage](#example-usage)
    * [Simple example](#simple-example)
    * [Filetype example](#filetype-example)
    * [Opening the menu in vim](#opening-the-menu-in-vim)
* [Documentation](#documentation)
* [Contribute](#contribute)
* [The ^ in V̂enu ?](#the--in-V̂enu-)
* [Alternatives](#alternatives)

<!-- vim-markdown-toc -->

V̂enu is a vim plugin that allows the definition of menus for different filetypes removing the need to remember commands and key combinations.

[![asciicast](https://asciinema.org/a/227971.svg)](https://asciinema.org/a/227971)

## Install

Using [vim-plug](https://github.com/junegunn/vim-plug):
```
Plug 'Timoses/vim-venu'
```

Or use any other vim plugin manager.


## Features

* **Submenus**: Menus can contain any number of submenus.
* **Merging of menus submenus**: If a menu is registered and has the same `name` as an already registered menu and there is a filetype collision (meaning both submenus or items have at least one filetype in common) then its contents including its submenus are merged together. This allows creating very general commands within a menu which can be extended by more specific commands for various filetypes.
* **Filetype specific commands**: Each menu and menu item can be assigned a filetype or a list of filetypes. This allows creating different menus for different filetypes.
* **Position preference and ordering priority**: Each menu and menu item can be assigned a preference for its position in the menu and an ordering priority. Positions are not guaranteed. If a position is assigned to more than one entry then all entries for that position are ordered by each entry's priority and are listed consecutively. This may result in subsequent entries not meeting their preferred positions. Empty entries may appear in case a menu or menu item has a position which is higher than one above the previous menu or menu item.
* **Import of native vim menus**: Native menus can be imported to V̂enu. See [documentation](./docs/import.md) for more details.

## Example Usage

### Simple example
This example showcases the various `cmd` types that can be used in `venu#addItem`.
```vim
let s:menu1 = venu#create('My first V̂enu')
call venu#addItem(s:menu1, 'Item of first menu', 'echo "Called first item"')
call venu#register(s:menu1)

function! s:myfunction() abort
    echo "I called myfunction"
endfunction

let s:menu2 = venu#create('My second V̂enu')
call venu#addItem(s:menu2, 'Call a function ref', function("s:myfunction"))

let s:submenu = venu#create('My awesome subV̂enu')
call venu#addItem(s:submenu, 'Item 1', ':echo "First item of submenu!"')
call venu#addItem(s:submenu, 'Item 2', ':echo "Second item of submenu!"')

" Add the submenu to the second menu
call venu#addItem(s:menu2, 'Sub menu', s:submenu)

call venu#register(s:menu2)
```

### Filetype example
In this example the menu `Build` is filled from different places (i.e. its contents are merged). Each filetype executes different commands for `Compile` and `Compile & Run`. `ft1` displays `Compile` first (`pos_pref=1`) while `ft2` displays `Compile & Run` first. However, both filetypes use the same `Build -> Execute` command.
```vim
.vim/ftplugin/ft1:
    let s:build = venu#create('Build')
    call venu#addItem(s:build, 'Compile', 'echo "compile ft1"', 1, 0, &ft)
    call venu#addItem(s:build, 'Compile & Run', 'echo "compile & run ft1"', 2, 0, &ft)
    call venu#register(s:build)

.vim/ftplugin/ft2:
    let s:build = venu#create('Build')
    call venu#addItem(s:build, 'Compile', 'echo "compile ft2"', 2, 0, &ft)
    call venu#addItem(s:build, 'Compile & Run', 'echo "compile & run ft2"', 1, 0, &ft)
    call venu#register(s:build)

.vimrc:
    let s:build = venu#create('Build')
    call venu#addItem(s:build, 'Execute', 'echo "execute"')
    call venu#register(s:build)

```

### Opening the menu in vim

The following command will open the V̂enu:
```vim
:VenuPrint
```

Calling `:VenuPrint` again will close the menu without any action.



## Documentation

----
```vim
venu#create(name, [pos_pref, priority])
```
Creates a menu with the given name and returns a handle to it.

Optionally may contain a `pos_pref` (positional preference) with a `priority` value.
Values of `0` are ignored.

----
```vim
venu#addItem(menuHandle, name, cmd [,pos_pref, priority, filetype])
```
Add a menu item with the given `name` to the menu with the handle `menuHandle`.
`cmd` can be a
* string - executed with `exe <string>`
* FuncRef - executed with `call <FuncRef>`
* another menu handle - a submenu is displayed

`pos_pref` is the positional preference with given `priority`. Values of `0` are ignored.

`filetype` can be a string or an array of strings. This argument allows showing an item only for specific filetypes. Note that when `venu#register` is called with filetypes which do not contain the `filetype` specified here then the menu will not be displayed for that `filetype`. Logically, the herein specified `filetype` argument should be a subset of the filetypes passed to `venu#register`.


----
```vim
venu#register(menuHandle [, filetype])
```
Register the menu so that it is displayed with `venu#print`.

If only one menu was registered its items are displayed directly. If several menus were registered the user can select the (sub)menu.

If a menu with the same name exists already it (and all its contained submenus) will be merged together.

----
```vim
venu#print()
```
Prints the menu.

----
```vim
venu#unregisterAll()
```
Unregisters all menus.


## Contribute

If you would like to contribute feel free to create a Pull Request or mention your ideas and problems as an Issue.

## The ^ in V̂enu ?
I personally mapped `:VenuPrint` to the `^` key on a German keyboard which is easily reachable. Hence, the name.

## Alternatives
* [quickmenu](https://github.com/skywind3000/quickmenu.vim)
    * opens a menu on the side, can use cmdline menu as well
    * no support for submenus
