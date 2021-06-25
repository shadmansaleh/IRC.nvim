local keymaps = {}

local utils = require'nirc.utils'

function keymaps.send_msg(msg)
  local nirc_data = require'nirc.data'
  local current_channel = utils.buf_get_var(0, 'NIRC_chan_name')
  vim.api.nvim_buf_set_lines(0, -3, -2, false, {})
  nirc_data.clients[nirc_data.active_client]:prompt(msg, current_channel)
end

return keymaps
