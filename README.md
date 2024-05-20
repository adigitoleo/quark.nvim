# ∴ quark.nvim

> Sure he hasn't got much of a bark
> And sure any he has it's all beside the mark.

Fuzzy pickers to open files, switch buffers and execute ex-commands.
Minimal configuration; tiny hackable source code.
Ce n'est pas un [télescope](https://github.com/nvim-telescope/telescope.nvim).

This [NeoVim](https://neovim.io) plugin, written in Lua, offers just three
commands to (1) open files from a directory, (2) switch between open buffers
and (3) open files from recent history (see `:help shada-file`).
There is also an optional function which can be used to find and execute
ex-commands. Recommended configuration:

```lua
quark = require("quark").setup{
    -- Requires ripgrep: <https://github.com/BurntSushi/ripgrep>
    fzf = { default_command = "rg --files --hidden --no-messages" }
}
if quark ~= nil then
    vim.keymap.set("n", ";", quark.fuzzy_cmd, { desc = "Search for (and execute) ex-commands" })
    -- Optional mappings for quick fuzzy-picker launching.
    vim.keymap.set("n", [[<Leader>b]], [[<Cmd>QuarkSwitch<Cr>]], { desc = "Launch buffer switcher" })
    vim.keymap.set("n", [[<Leader>f]], [[<Cmd>QuarkFind<Cr>]], { desc = "Launch file browser" })
    vim.keymap.set("n", [[<Leader>r]], [[<Cmd>QuarkRecent<Cr>]], { desc = "Launch recent file browser" })
end
```

Pickers don't list the currently open buffer. I only have Win11 and Linux to
test, so it might be broken on MacOS. Patches welcome.

Supported fuzzy-finder backends:
- [x] [fzf](https://github.com/junegunn/fzf)
- [ ] [fzy-lua](https://github.com/swarn/fzy-lua)

Install the plugin using your preferred plugin manager. Alternatively, NeoVim
can load packages if they are added to your 'packpath'.

Available commands and options are described in `:help quark`.

Please send patches/queries to my [public inbox](https://lists.sr.ht/~adigitoleo/public-inbox).
