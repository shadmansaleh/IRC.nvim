### IRC.nvim

Irc client for neovim.

Currently it's at very early stage of devlopment . It is some
what usable. Not really :D

### ScreenShot

![Screenshot](https://user-images.githubusercontent.com/13149513/117023116-9f66c700-ad1a-11eb-98fa-21ff31e2f850.png)

### Usage instruction

You create client with

```lua
  require'nirc'.setup(config)
```

Where default server config is
```lua
local default_server_config = {
  server = 'irc.freenode.net',
  port = 6667,
  nick = os.getenv('USER') or 'nirc_user',
  username = os.getenv('USER') or 'nirc_user',
  password = nil,
}
```

Packer config example:
```lua
use {'shadmansaleh/IRC.nvim', 
  config = function()
    require'nirc'.setup({
      servers = {
        freenode = {
          nick = 'user',
          username = 'user',
          server = 'irc.freenode.net',
          port = 6667,
        },
      }
      prompt_height = 1,
      statusline = true,
      default_keymaps = true,
    })
  end,
}
```

To connect to server run `NIRCConnect` command

```vim
:NIRCConnect freenode
```

Then you'll be at a screen with two windows the one above is
preview window and the one below is prompt window. You'll have to
type commands in the prompt window

You'll have to type in commands to interact with the server.  If
an input starts with '/' it is treated as a command . And if it
doesn't Then It's treated as a message and is sent to current
channel.
```
  /msg shadman hello shadman!
```

To join neovim's chennel 
```
  /join #neovim
```

To send message to a chennel
```
  /msg #neovim hello everybody
```
ore just
```
hello everybody
```
If you have neovim's chennel opened in preview window

### Available vim commands
- `NIRCConnect` server-name (Connect to server)
- `NIRCChannelNext` (Go to next channel)
- `NIRCChannelPrev` (Go to previous channel)
- `NIRCChannelSwitch` channel-name (Go to specific channel)

### Supported IRC commands:
<details>
<summary>Commands</summary>

- admin
- away
- connect
- die
- info
- invite
- ison
- join aliased j
- kick
- kill
- links
- list
- lusers
- mode
- motd
- msg  aliased m
- names
- nick
- notice
- oper
- part aliased p
- quit
- raw
- rehash
- restart
- servlist
- stats
- squery
- squit
- summon
- time
- topic
- trace
- userhost
- users
- version
- wallops
- who
- whois
- whowas

</details>


### Config Options
- servers\
  Server configuration table
- prompt_height\
  Height of prompt buffer.\
  Defaults: 1.
- statusline\
  Whether to show statusline containing channels\
  in preview window.\
  Default true
- default_keymaps\
  Whether to set default keymaps.\
  Default: true

### Keymaps
- `<Plug>NIRC_goto_prompt` sends user to prompt window
- `<Plug>NIRC_send_msg` sends message in prompt

By default i,I,a,A,o,O in preview buffer in normal mode
is bound to `<Plug>NIRC_goto_prompt`. Basically preview
buffer is not for editing but prompt buffer is so sending
you there. If you want to go to insert mode in preview
buffer then you can just use `:startinsert`

Also `<CR>` in prompt buffer in insert mode is bound to
`<Plug>NIRC_send_msg`. So typeing enter will send the message.
If you write multiple lines in the buffer and then trigger
`<Plug>NIRC_send_msg` every line will be sent as indivisual
message at once.

If config option `default_keymaps` is set to false then
only `<Plug>` bindings will be created but nothing will
be bound to them . It's upto the users to choose what to
do with them.

You can easily send multiline mesaages by setting
default_keymaps to false and binding `<Plug>NIRC_send_msg`
to some other key but `<CR>` . Also while you're at
it you can make the prompt win bigger with
`prompt_height` config option to make it easier.

The prompt buffer has filetype of `nirc_prompt`
and preview buffer has filetype of `nirc_preview`
You can esialy set keymaps/options for them
targeting their filetype with `autocmd FileType`

### Highlight groups
- NIRCTime -> Comment
- NIRXMessage -> Normal
- NIRCMention -> Special
- NIRCNick -> String

-> Means links to by default.

### TODO
- [ ] Quite literally alot.
- [ ] Proper implementation of the client with as many commands supported as possible.
- [ ] A proper UI to make it usable

### what's not in the list
For now SSL support is out of scope . I don't want to write an
entire ssl library.  If you've a better idea on how to add ssl
support please let me know :) . I want to add it but don't have
a good enough way to do it.

### Similar projects
- [marchelzo/ircnvim](https://github.com/marchelzo/ircnvim)
