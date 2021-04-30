### NIRC

Irc client for neovim.

Currently it's at very early stage of devlopment . And not really usable.

You can initiate a connection with

```lua
local client = require'nirc.irc':new(args)
```

Where default args are
```lua
local default_config = {
  server = 'irc.freenode.net',
  port = 6667,
  nick = os.getenv('USER') or 'nirc_user',
  username = os.getenv('USER') or 'nirc_user',
}
```

Then 
```lua
client:connect()
```
to connect to the server


You can send commands to the server with `client:prompt()`
Like to messege shadman you'd run 
```lua
  client:prompt('/msg shadman hello shadman!')
```

To join neovim's chennel you'd run 
```lua
  client:prompt('/join #neovim')
```

### Supported commands:
- join
- part
- msg
- nick
- quit

### TODO
- [ ] Alot.
- [ ] Proper implementation of the client with as many commands supported as posible.
- [ ] A prooer UI to make it usable

### what's not in the list
For now SSL support is out of scope . I don't want to write an entire ssl library.
If you've a better idea on how to add ssl you're welcome :)
