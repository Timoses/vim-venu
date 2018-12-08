# V̂enu

<!-- vim-markdown-toc GFM -->

* [Install](#install)
* [Example Usage](#example-usage)
* [Contribute](#contribute)
* [The ^ in V̂enu ?](#the--in-V̂enu-)

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
To define a menu for markdown files we will add the following in the file `~/.vim/ftplugin/markdown.vim`:

```
let s:functions={}

function! s:functions.markdownPreview() abort
    " Using Plug 'iamcco/markdown-preview.vim'
    if exists(":MarkdownPreviewStop")
        :MarkdownPreviewStop
    endif
    :MarkdownPreview
endfunction

function! s:functions.generateToc() abort
    " Define a submenu by returning another Dictionary containing the submenu functions.
    return s:tocs
endfunction
    let s:tocs={}
    " Using Plug 'mzlogin/vim-markdown-toc'
    function! s:tocs.githubFlavoredMarkdown() abort
        :GenTocGFM
    endfunction
    function! s:tocs.redcarpet() abort
        :GenTocRedcarpet
    endfunction
    function! s:tocs.gitLab() abort
        :GenTocGitLab
    endfunction
    function! s:tocs.marked() abort
        :GenTocMarked
    endfunction

" Register the menu with V̂enu
call venu#registerMenu(&ft, s:functions)
```

Open a markdown `.md` file and call

```
:VenuPrint
```

Calling `:VenuPrint` again will close the menu without any action.

## Contribute

If you would like to contribute feel free to create a Pull Request or mention your ideas and problems as an Issue.

## The ^ in V̂enu ?
I personally mapped `:VenuPrint` to the `^` key on a German keyboard which is easily reachable.

