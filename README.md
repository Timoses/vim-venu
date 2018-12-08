# V̂enu

<!-- vim-markdown-toc GFM -->

* [Install](#install)
* [Example Usage](#example-usage)
* [Documentation](#documentation)
* [Contribute](#contribute)
* [The ^ in V̂enu ?](#the--in-V̂enu-)
* [Alternatives](#alternatives)

<!-- vim-markdown-toc -->

V̂enu is a vim plugin that allows the definition of menus for different filetypes removing the need to remember commands and key combinations.

<a href="https://asciinema.org/a/cqN0nkYnxmXFXW2EeY3Fkpv9Y"><img width=400 src="https://asciinema.org/a/cqN0nkYnxmXFXW2EeY3Fkpv9Y.png"></img></a>

## Install

Using [vim-plug](https://github.com/junegunn/vim-plug):
```
Plug 'Timoses/vim-venu'
```

Or use any other vim plugin manager.

## Example Usage

A simple example:
```
let s:menu1 = venu#create('My first Venu')
call venu#addOption(s:menu1, 'Option of first menu', 'echo "Called first option"')
call venu#register(s:menu1)

function! s:myfunction() abort
    echo "I called myfunction"
endfunction

let s:menu2 = venu#create('My second Venu')
call venu#addOption(s:menu2, 'Call a function ref', function("s:myfunction"))

let s:submenu = venu#create('My awesome subVenu')
call venu#addOption(s:submenu, 'Option 1', ':echo "First option of submenu!"')
call venu#addOption(s:submenu, 'Option 2', ':echo "Second option of submenu!"')

" Add the submenu to the second menu
call venu#addOption(s:menu2, 'Sub menu', s:submenu)

call venu#register(s:menu2)
```

The following command will open the V̂enu:
```
:VenuPrint
```

Calling `:VenuPrint` again will close the menu without any action.

## Documentation

----
```
venu#create(name)
```
Creates a menu with the given name and returns a handle to it.

----
```
venu#addOption(menuHandle, name, cmd [, filetype])
```
Add an option with the given `name` to the menu with the handle `menuHandle`.
`cmd` can be a
* string - executed with `exe <string>`
* FuncRef - executed with `call <FuncRef>`
* another menu handle - a submenu is displayed

`filetype` can be a string or an array of strings. This argument allows showing an option only for specific filetypes. Note that when `venu#register` is not called with the filetype the menu will not be shown. Logically, the herein specified `filetype` argument should be a subset of the filetypes passed to `venu#register`.


----
```
venu#register(menuHandle [, filetype])
```
Register the menu so that it is displayed with `venu#print`. If only one menu is available its options are directly displayed. If several menus are registered the user has to select the menu which to show the options of.

----
```
venu#print()
```
Prints the menu.


## Contribute

If you would like to contribute feel free to create a Pull Request or mention your ideas and problems as an Issue.

## The ^ in V̂enu ?
I personally mapped `:VenuPrint` to the `^` key on a German keyboard which is easily reachable. Hence, the name.

## Alternatives
* [quickmenu](https://github.com/skywind3000/quickmenu.vim)
    * opens a menu on the side, can use cmdline menu as well
    * no support for submenus
