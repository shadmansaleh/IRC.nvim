local display = {}

local utils = require'nirc.utils'

function display.open_view()
  local nirc_data = require'nirc.data'
  nirc_data.display = nirc_data.display
  if nirc_data.display.tab_no then
    -- Page layput already available switch to it
    local tab_no = nirc_data.display.tab_no
    if tab_no and vim.api.nvim_tabpage_is_valid(tab_no) then
      vim.api.nvim_set_current_tabpage(tab_no)
      local prompt_win_no = nirc_data.display.prompt_win.win
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
  silent! setlocal breakat&
  silent! setlocal buftype=nofile
  silent! call nvim_buf_set_name(0, 'IRC_preview')
  silent! nnoremap <silent><buffer> i <cmd>lua require("nirc.keymaps").goto_prompt()<CR>
  silent! nnoremap <silent><buffer> a <cmd>lua require("nirc.keymaps").goto_prompt()<CR>
  silent! nnoremap <silent><buffer> I <cmd>lua require("nirc.keymaps").goto_prompt()<CR>
  silent! nnoremap <silent><buffer> A <cmd>lua require("nirc.keymaps").goto_prompt()<CR>
  silent! 1split
  silent! enew
  silent! setlocal nonumber
  silent! setlocal buftype=nofile
  silent! setlocal bufhidden=hide
  silent! setlocal norelativenumber
  silent! setlocal virtualedit=onemore
  silent! call nvim_buf_set_name(0, 'IRC_prompt')
  silent! inoremap <silent><buffer> <CR> <cmd>lua require("nirc.keymaps").send_msg()<CR>
  ]], false)
  nirc_data.display = {
    tab_no = vim.api.nvim_get_current_tabpage(),
    prompt_win = {
      buf = vim.api.nvim_get_current_buf(),
      win = vim.api.nvim_get_current_win(),
    }
  }
  vim.cmd('silent! wincmd k')
  nirc_data.display.preview_win = {
    buf = vim.api.nvim_get_current_buf(),
    win = vim.api.nvim_get_current_win(),
  }
  vim.api.nvim_set_current_win(nirc_data.display.prompt_win.win)
  vim.cmd('silent! startinsert')
  return true
end

function display.close_view()
  local nirc_data = require'nirc.data'
  vim.api.nvim_buf_delete(nirc_data.display.preview_win.buf, {force = true})
  vim.api.nvim_buf_delete(nirc_data.display.prompt_win.buf, {force = true})
  vim.cmd('silent! tabclose')
  nirc_data.display.preview_win = nil
  nirc_data.display.prompt_win = nil
  nirc_data.display.tab_no = nil
end

function display.show(msg)
  local nirc_data = require'nirc.data'
  local client = nirc_data.clients[nirc_data.active_client]
  local chan_name = 'UnDetected'
  if msg.cmd == 'PRIVMSG' or msg.cmd == 'NOTICE'then
    if msg.args[1] == client.config.nick-- or
   --   (msg.args[1]:match('%A+') and
  --      (msg.args[1]:byte(1) ~= string.byte('#') or msg.args[1]:byte(1) ~= string.byte('&')))
        then
      chan_name = msg.nick or nirc_data.active_client
    else
      if not msg.nick then
        chan_name = nirc_data.active_client
      else
        chan_name = msg.args[1]
      end
    end
  -- elseif #nirc_data.active_channel > 0 then
  --   chan_name = nirc_data.active_channel
  else
    chan_name = nirc_data.active_client
  end
  if not nirc_data.channels.msgs[chan_name] then
    if #nirc_data.active_channel <= 0 then nirc_data.active_channel = chan_name end
    table.insert(nirc_data.channels.list, chan_name)
    nirc_data.channels.msgs[chan_name] = {}
  end
  local msg_strs = display.format_msg(msg)
  for _, msg_str in pairs(msg_strs) do
    table.insert(nirc_data.channels.msgs[chan_name], msg_str)
  end
  if not nirc_data.active_channel then
    nirc_data.active_channel = chan_name
  end
  if chan_name == nirc_data.active_channel then
    vim.api.nvim_buf_set_lines(nirc_data.display.preview_win.buf, -1, -1, false, msg_strs)
    local current_wins = vim.api.nvim_tabpage_list_wins(0)
    for _, win_no in pairs(current_wins) do
      if win_no == nirc_data.display.preview_win.win then
        local cur_win = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(nirc_data.display.preview_win.win)
        vim.cmd[[silent! normal! G]]
        vim.api.nvim_set_current_win(cur_win)
        break
      end
    end
  end
end

function display.format_msg(msg)
  if msg.disp_msg then return {msg.disp_msg} end
  local separator = '┊'
  local max_size = 10
  local time = os.date('%2H:%2M')
  local name = msg.nick or msg.addr
  if #name > max_size then name = name:sub(1, max_size - 2) .. '..' end
  if #name < max_size then
    local size = #name
    local r_padding = math.floor((max_size - size) / 2)
    local l_padding
    if ((2 * r_padding) + size) == max_size then
      l_padding = r_padding
    else
      l_padding = r_padding + 1
    end
    name = string.format('%s%s%s', string.rep(' ', l_padding), name, string.rep(' ', r_padding))
  end
  local message = msg.args[#msg.args]
  local splited_message = utils.str_split_len(message, vim.fn.winwidth(0) - (1+5+2+1+2+2+max_size+2+2+1+2+5))
  local formated_message = {}
  table.insert(formated_message, string.format(' %s  %s  ( %s )  %s  %s', time, separator, name, separator, splited_message[1]))
  for i=2, #splited_message do
    table.insert(formated_message, string.format(' %s  %s   %s   %s  %s', string.rep(' ', 5), separator, string.rep(' ', max_size + 2), separator, splited_message[i]))
  end
  return formated_message
end

function display.switch_channel(chan_name)
  local nirc_data = require'nirc.data'
  if not nirc_data.channels.msgs[chan_name] then return end
  nirc_data.active_channel = chan_name
  vim.api.nvim_buf_set_lines(nirc_data.display.preview_win.buf, 0, -1, false, nirc_data.channels.msgs[chan_name])
  local current_wins = vim.api.nvim_tabpage_list_wins(0)
  for _, win_no in pairs(current_wins) do
    if win_no == nirc_data.display.preview_win.win then
      local cur_win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_current_win(nirc_data.display.preview_win.win)
      vim.cmd[[silent! normal! G]]
      vim.api.nvim_set_current_win(cur_win)
      break
    end
  end
end

function display.next_channel()
  local nirc_data = require'nirc.data'
  if #nirc_data.channels.list < 2 then return end
  local chan_name = ''
  if nirc_data.active_channel == nirc_data.channels.list[#nirc_data.channels.list] then
    chan_name = nirc_data.channels.list[1]
  else
    for i=1,#nirc_data.channels.list do
      if nirc_data.active_channel == nirc_data.channels.list[i] then
        chan_name = nirc_data.channels.list[i + 1]
        break
      end
    end
  end
  display.switch_channel(chan_name)
end

function display.prev_channel()
  local nirc_data = require'nirc.data'
  if #nirc_data.channels.list < 2 then return end
  local chan_name = ''
  if nirc_data.active_channel == nirc_data.channels.list[1] then
    chan_name = nirc_data.channels.list[#nirc_data.channels.list]
  else
    for i=1,#nirc_data.channels.list do
      if nirc_data.active_channel == nirc_data.channels.list[i] then
        chan_name = nirc_data.channels.list[i - 1]
        break
      end
    end
  end
  display.switch_channel(chan_name)
end

function display.channels()
  local nirc_data = require'nirc.data'
  return nirc_data.channels.list
end

return display
