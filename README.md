# Nuke: xplr file viwer and opener

Plugin for [xplr](https://github.com/sayanarijit/xplr): view and open files in apps by file type or mime

inspired by [nnn](https://github.com/jarun/nnn) file manager [nuke plugin](https://github.com/jarun/nnn/blob/master/plugins/nuke).

## Requirements

  | File type  | Open                    | Smart View               | Info view         |
  |:-----------|:------------------------|:-------------------------|:------------------|
  | *          |                         |                          | exiftool/file     |
  | Image      | viu/timg/chafa/cacaview | viu/chafa/catimg/img2txt | mediainfo         |
  | Video      | mpv/mplayer             |                          | mediainfo/mplayer |
  | Audio      | mpv/mplayer             |                          |                   |
  | PDF        | termpdf                 | pdftotext                |                   |
  | DJVU       | termpdf                 | djvused                  |                   |
  | PostScript |                         | ps2ascii                 |                   |
  | Markdown   |                         | glow/lowdown/mdless      |                   |
  | HTML       |                         | w3m/elinks/lynx          |                   |
  | MS doc     |                         | antiword/catdoc/wvWare   |                   |
  | MS docx    |                         | libreoffice              |                   |
  | MS xls     |                         | xlhtml/xls2csv           |                   |
  | MS xlsx    |                         | libreoffice              |                   |
  | Epub       |                         |                          | einfo             |

  *recomended terminal emulator with support of [Terminal graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)*

- **View:** bat/pygmentize/less
- **Hex view:** hx/hexyl/huxd/hxl/hexdump

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

## Usage
  
```lua
require("nuke").setup()

-- Or

require("nuke").setup{
  pager = "more", -- default: less -R
  open = {
    run_executables = true, -- default: false
    custom = {
      {extension = "jpg", command = "sxiv {}"},
      {mime = "video/mp4", command = "vlc {}"},
      {mime_regex = "^video/.*", command = "smplayer {}"}
      {mime_regex = ".*", command = "xdg-open {}"}
    }
  },
  view = {
    show_line_numbers = true, -- default: false
  }
}
```

### Key bindings

```lua
  local key = xplr.config.modes.builtin.default.key_bindings.on_key
  
  key.v = {
    help = "nuke",
    messages = {"PopMode", {SwitchModeCustom = "nuke"}}
  }
  key["f3"] = xplr.config.modes.custom.nuke.key_bindings.on_key.v
  key["enter"] = xplr.config.modes.custom.nuke.key_bindings.on_key.o
```
