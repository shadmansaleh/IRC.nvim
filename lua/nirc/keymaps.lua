local keymaps = {}

function keymaps.send_msg(msg)
  local nirc_data = require'nirc.data'
  nirc_data.clients[nirc_data.active_client]:prompt(msg)
end

return keymaps
