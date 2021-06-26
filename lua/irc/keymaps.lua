local keymaps = {}

local utils = require'irc.utils'

function keymaps.send_msg(msg)
  local irc_data = require'irc.data'
  local current_channel = utils.buf_get_var(0, 'IRC_channel_name')
  vim.api.nvim_buf_set_lines(0, -3, -2, false, {})
  irc_data.clients[irc_data.active_client]:prompt(msg, current_channel)
end

return keymaps
