### IRC.nvim

Irc client for neovim.

Currently it's at very early stage of devlopment . It is some
what usable. Not really :D

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
        libera = {
          nick = 'user',
          username = 'user',
          server = 'irc.libera.chat',
          port = 6667,
        },
      }
      statusline = true,
    })
  end,
}
```

To connect to server run `NIRCConnect` command

```vim
:NIRCConnect libera
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
- statusline\
  Whether to show statusline containing channels\
  in preview window.\
  Default true

### Highlight groups
- NIRCTime -> Comment
- NIRXMessage -> Normal
- NIRCMention -> Special
- NIRCNick -> String

-> Means links to by default.

### Similar projects
- [marchelzo/ircnvim](https://github.com/marchelzo/ircnvim)
