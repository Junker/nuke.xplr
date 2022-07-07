# Nuke: xplr file opener

Plugin for [xplr](https://github.com/sayanarijit/xplr): open files in apps by file type or mime

inspired by [nnn](https://github.com/jarun/nnn) file manager [nuke plugin](https://github.com/jarun/nnn/blob/master/plugins/nuke).

## Requirements

| File type    | Program                |
|:-------------|:-----------------------|
| Image        | viu/timg/chafa/img2txt |
| Video        | mpv/mplayer            |
| Audio        | mpv/mplayer            |
| Archive      | atool/dtrx/ouch        |
| OpenDocument | odt2txt                |
| HTML         | w3m/lynx/elinks        |
| PDF          | termpdf/pdftotext      |
| DJVU         | termpdf                |
| Executable   | dialog                 |

*recomended terminal emulator with support of [Terminal graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)*

## Installation

### Install manually

- Add the following line in `~/.config/xplr/init.lua`

  ```lua
  local home = os.getenv("HOME")
  package.path = home
    .. "/.config/xplr/plugins/?/src/init.lua;"
    .. home
    .. "/.config/xplr/plugins/?.lua;"
    .. package.path
  ```

- Clone the plugin

  ```bash
  mkdir -p ~/.config/xplr/plugins

  git clone https://github.com/Junker/nuke.xplr ~/.config/xplr/plugins/nuke
  ```
  
### Install with [xpm](https://github.com/dtomvan/xpm.xplr)

  ```lua
  require("xpm").setup({
    plugins = {
      'dtomvan/xpm.xplr',
      'Junker/nuke.xplr'
    }
  })
  ```

### Usage
  
  ```lua
  require("nuke").setup()

  -- Or

  require("nuke").setup{
    pager = "more", -- default: less -R
    run_executables = false, -- default: true
    custom = {
      {extension = "jpg", command = "sxiv {}"},
      {extension = "so", command = "ldd -r {} | less"},
      {mime = "video/mp4", command = "vlc {}"},
      {mime_regex = "^video/.*", command = "smplayer {}"}
      {mime_regex = ".*", command = "xdg-open {}"}
    }
  }
  
  xplr.config.modes.builtin.default.key_bindings.on_key["enter"] = {
    help = "nuke",
    messages = {
      {CallLuaSilently = "custom.nuke_handle_node"}
    }
  }
  ```
