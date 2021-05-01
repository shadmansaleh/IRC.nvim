### IRC.nvim

Irc client for neovim.

Currently it's at very early stage of devlopment . And not really usable.

You create client with

```lua
  require'nirc':new(config)
```

Where default config are
```lua
local default_config = {
  server = 'irc.freenode.net',
  port = 6667,
  nick = os.getenv('USER') or 'nirc_user',
  username = os.getenv('USER') or 'nirc_user',
  password = nil,
}
```

Then you'll be at a screen with two windows the one above is preview window
and the one below is prompt window you'll have to type commands in the
prompt window

For now you need to type dirrect commands without much assistance
Like to messege shadman you'd run 
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

### Supported commands:
- admin
- away
- connect
- info
- invite
- ison
- join aliased j
- kick
- kill
- links
- list
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
- restart
- stats
- summon
- time
- trace
- userhost
- users
- version
- wallops
- who
- whois
- whowas

### TODO
- [ ] Quite litraly Alot.
- [ ] Proper implementation of the client with as many commands supported as posible.
- [ ] A prooer UI to make it usable

### what's not in the list
For now SSL support is out of scope . I don't want to write an entire ssl library.
If you've a better idea on how to add ssl support please let me know :)
