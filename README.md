### IRC.nvim

Irc client for neovim.

Currently it's at very early stage of devlopment . It is some
what usable. Not really :D

### Requirements
  - neovim 0.5
  - [openssl](https://github.com/zhaozg/lua-openssl) (optional | For ssl support)

### Instalation
  ** Packer **
  ```lua
    use {'shadmansaleh/IRC.nvim', rocks = 'openssl'}

  ```
  ** VimPlug **
  ```vim
    Plug "shadmansaleh/IRC.nvim"
  ```
  You'll have to install [openssl](https://github.com/zhaozg/lua-openssl) separatly.
  If you have luarocks installed you can system-wide install it with
  ```
    sudo luarocks install openssl
  ```
### Usage instruction

You create client with

```lua
  require'irc'.setup(config)
```

Where default server config is
```lua
local default_server_config = {
  server = 'irc.freenode.net',
  port = 6667,
  nick = os.getenv('USER') or 'irc_user',
  username = os.getenv('USER') or 'irc_user',
  password = nil,
  use_ssl = true,
}
```

Packer config example:
```lua
use {'shadmansaleh/IRC.nvim', rocks = 'openssl',
  config = function()
    require'irc'.setup({
      servers = {
        libera = {
          nick = 'user',
          username = 'user',
          server = 'irc.libera.chat',
          port = 6667,
          use_ssl = true,
        },
      }
      statusline = true,
    })
  end,
}
```

It's not recomanded toput password in configuration. You can open nvim
with password in IRC_{config_name} for example IRC_libera for
liberas password.  Or best don't do any of it, you'll be prompted for
password when connecting.

To connect to server run `IRCConnect` command

```vim
:IRCConnect libera
```

Then you'll be at a server buffer . This will show all communications
with server. When you join other channel or receive private message
from someone new buffers will be opend to store them.

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
or just
```
hello everybody
```
If you have neovim's chennel opened

### Available vim commands
- `IRCConnect` server-name (Connect to server)
- `IRCChannelNext` (Go to next channel)
- `IRCChannelPrev` (Go to previous channel)
- `IRCChannelSwitch` channel-name (Go to specific channel)

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
- statusline\
  Whether to show statusline containing channels\
  in preview window.\
  Default true

### Highlight groups
- IRCTime -> Comment
- NIRXMessage -> Normal
- IRCMention -> Special
- IRCNick -> String

-> Means links to by default.

### Similar projects
- [marchelzo/ircnvim](https://github.com/marchelzo/ircnvim)
