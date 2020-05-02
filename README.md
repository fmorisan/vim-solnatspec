# vim-solnatspec

Tired of writing NatSpec comments by hand?  
Saw the format and thought to yourself, *wow that doesn't look fun to type out*?

**Then, this is the plugin for you!**

## Requirements
- `solc` in your path. The real, full `solc`, none of that `solcjs` nonsense
- `python3 >= 3.6` we using f-strings here, beware

## Installation

If you're using some sort of plugin manager, just add this to your init.vim
```vim
Plug 'fmorisan/vim-solnatspec'
```
And before you ask, yes - it works with both NeoVim and Vim.

## Usage

Put your cursor on a function's name (preferrably in its definition line) and exec  
```
:SolNatSpec
```
This will insert an already formatted NatSpec comment above your cursor. Feel free to bind this call somewhere.

## Contributing
Just throw a PR here. Help would be great. I don't understand VimScript fully, but this was fun to hack together.
