local keymaps = {}

local utils = require'nirc.utils'

function keymaps.send_msg(msg)
  local nirc_data = require'nirc.data'
  local current_channel = utils.buf_get_var(vim.fn.bufnr(), 'NIRC_chan_name')
  nirc_data.clients[nirc_data.active_client]:prompt(msg, current_channel)
end

return keymaps
