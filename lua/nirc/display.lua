local display = {}

display.data = {}

function display.open_view()
  if display.data.tab_no then
    -- Page layput already available switch to it
    local tab_no = display.data.tab_no
    if tab_no and vim.api.nvim_tabpage_is_valid(tab_no) then
      vim.api.nvim_set_current_tabpage(tab_no)
      local prompt_win_no = display.data.prompt_win.win
      if prompt_win_no and vim.api.nvim_win_is_valid(prompt_win_no) then
        vim.api.nvim_set_current_win(prompt_win_no)
        vim.cmd('silent! startinsert')
        return true
      end
    end
  end
  -- create layout
  vim.api.nvim_exec([[
  silent! tabnew
  silent! setlocal splitbelow
  silent! setlocal nonumber
  silent! setlocal norelativenumber
  silent! setlocal autoread
  silent! setlocal syn=irc
  silent! setlocal linebreak
  silent! setlocal breakindent
  silent! setlocal breakindentopt=shift:31
  silent! setlocal breakat&
  silent! setlocal buftype=nofile
  silent! call nvim_buf_set_name(0, 'IRC_preview')
  silent! 5split
  silent! enew
  " silent! setlocal backspace=start,indent
  silent! setlocal nonumber
  silent! setlocal buftype=nofile
  silent! setlocal bufhidden=hide
  silent! setlocal norelativenumber
  silent! setlocal virtualedit=onemore
  silent! call nvim_buf_set_name(0, 'IRC_prompt')
  silent! inoremap <silent><buffer> <CR> <cmd>lua require("nirc.keymaps").send_msg()<CR>
  ]], false)
  display.data = {
    tab_no = vim.api.nvim_get_current_tabpage(),
    prompt_win = {
      buf = vim.api.nvim_get_current_buf(),
      win = vim.api.nvim_get_current_win(),
    }
  }
  vim.cmd('silent! wincmd k')
  display.data.preview_win = {
    buf = vim.api.nvim_get_current_buf(),
    win = vim.api.nvim_get_current_win(),
  }
  vim.api.nvim_set_current_win(display.data.prompt_win.win)
  vim.cmd('silent! startinsert')
  return true
end

return display
