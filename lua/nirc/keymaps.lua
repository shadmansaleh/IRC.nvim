local keymaps = {}

local utils = require'nirc.utils'

function keymaps.send_msg()
  local nirc_data = require'nirc.data'
  local line = vim.api.nvim_get_current_line()
  local prompt = utils.get_prompt()
  line = utils.remove_prompt(line, prompt)
  nirc_data.clients[nirc_data.active_client]:prompt(line)
  vim.api.nvim_del_current_line()
  vim.api.nvim_buf_set_lines(nirc_data.display.prompt_win.buf, 1, 1, false, {prompt})
end

function keymaps.goto_prompt()
  local nirc_data = require'nirc.data'
  vim.api.nvim_set_current_win(nirc_data.display.prompt_win.win)
  vim.cmd('silent! startinsert')
end

return keymaps
