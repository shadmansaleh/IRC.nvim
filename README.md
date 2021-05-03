### IRC.nvim

Irc client for neovim.

Currently it's at very early stage of devlopment . And not really
usable.

### ScreenShot

![Screenshot](https://user-images.githubusercontent.com/13149513/116909188-aaabeb00-ac65-11eb-82e0-8eb66772680e.png)

### Usage instruction

You create client with

```lua
  require'nirc'.setup(config)
```

Where default server config is
```lua
local default_config = {
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
      freenode = {
        nick = 'user',
        username = 'user',
        server = 'irc.freenode.net',
        port = 6667,
      }
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

### TODO
- [ ] Quite literally alot.
- [ ] Proper implementation of the client with as many commands supported as possible.
- [ ] A proper UI to make it usable

### what's not in the list
For now SSL support is out of scope . I don't want to write an
entire ssl library.  If you've a better idea on how to add ssl
support please let me know :)
