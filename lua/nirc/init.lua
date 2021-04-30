local keymaps = require'nirc.keymaps'
local display = require'nirc.display'
local irc = require'nirc.irc'

local nirc = {}

function nirc.setup(conf)
  nirc.client = irc:new(conf)
  keymaps.init(nirc.client)
  display.open_view()
  nirc.client:connect()
end

return nirc
