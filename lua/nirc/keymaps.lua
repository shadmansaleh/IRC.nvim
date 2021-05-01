local keymaps = {}

local utils = require'nirc.utils'
local display = require'nirc.display'

function keymaps.init(client)
  keymaps.client = client
end

function keymaps.send_msg()
  local line = vim.api.nvim_get_current_line()
  local prompt = utils.get_prompt(keymaps.client)
  line = utils.remove_prompt(line, prompt)
  keymaps.client:prompt(line)
  vim.api.nvim_del_current_line()
  vim.api.nvim_buf_set_lines(display.data.prompt_win.buf, 1, 1, false, {prompt})
end

function keymaps.goto_prompt()
  vim.api.nvim_set_current_win(display.data.prompt_win.win)
  vim.cmd('silent! startinsert')
end

return keymaps
