local keymaps = {}

local utils = require'nirc.utils'

function keymaps.send_msg()
  local nirc_data = require'nirc.data'
  local lines = vim.api.nvim_buf_get_lines(nirc_data.display.prompt_win.buf, 0, -1, false)
  local prompt = utils.get_prompt()
  lines[1] = utils.remove_prompt(lines[1], prompt)
  for _, line in pairs(lines) do
    nirc_data.clients[nirc_data.active_client]:prompt(line)
  end
  vim.api.nvim_buf_set_lines(nirc_data.display.prompt_win.buf, 0, -1, false, {prompt})
  vim.api.nvim_win_set_cursor(0, {1, #prompt - 1})
end

function keymaps.goto_prompt()
  local nirc_data = require'nirc.data'
  vim.api.nvim_set_current_win(nirc_data.display.prompt_win.win)
  vim.cmd('silent! startinsert')
end

return keymaps
