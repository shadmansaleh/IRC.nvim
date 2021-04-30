local keymaps = {}

function keymaps.init(client)
  keymaps.client = client
  -- vim.cmd('silent! inoremap <silent> <Plug>IRC_send_msg lua require("nirc.keymaps").send_msg()<CR>')
end

function keymaps.send_msg()
  local line = vim.api.nvim_get_current_line()
  keymaps.client:prompt(line)
  vim.api.nvim_del_current_line()
end

return keymaps
