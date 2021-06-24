local display = {}

local utils = require'nirc.utils'
local keymaps = require'nirc.keymaps'
local api = vim.api

function display.open_view()
  local nirc_data = require'nirc.data'
  local server_name = nirc_data.active_client
  nirc_data.display = nirc_data.display
  if nirc_data.display[server_name] then
    -- Page layput already available switch to it
    local server_data = nirc_data.display[server_name]
    local tab_no = server_data.tab_no
    if tab_no and api.nvim_tabpage_is_valid(tab_no) then
      api.nvim_set_current_tabpage(tab_no)
      local server_win = server_data.win
      if server_win and api.nvim_win_is_valid(server_win) then
        api.nvim_set_current_win(server_win)
        vim.cmd('silent! startinsert')
        return true
      end
    end
  end

  -- create layout as it doesn't exist
  local server_data = {}
  nirc_data.display[server_name] = server_data
  nirc_data.channel_list[server_name] = {}

  vim.cmd("tabnew")
  server_data.tab_no = api.nvim_get_current_tabpage()
  server_data.buf = api.nvim_get_current_buf()
  server_data.win = api.nvim_get_current_win()
  api.nvim_set_current_buf(server_data.buf)

  -- set options
  api.nvim_win_set_option(server_data.win, 'number', false)
  api.nvim_win_set_option(server_data.win, 'relativenumber', false)
  api.nvim_buf_set_option(server_data.buf, 'filetype', 'nirc')
  api.nvim_buf_set_option(server_data.buf, 'syntax', 'nirc')
  api.nvim_buf_set_option(server_data.buf, 'buftype', 'prompt')
  api.nvim_buf_set_name(server_data.buf, server_name)
  vim.fn.prompt_setprompt(server_data.buf, "NIRC > ")
  vim.fn.prompt_setcallback(server_data.buf, keymaps.send)
  vim.cmd('silent! startinsert')
  return true
end

function display.close_view()
  local nirc_data = require'nirc.data'
  local server_name = nirc_data.active_client
  if not server_name then return false end
  local server_data = nirc_data.display[server_name]
  api.nvim_buf_delete(server_data.buf, {force = true})
  vim.cmd([[
  silent! tabclose
  silent! stopinsert
  ]])
  server_data.win = nil
  server_data.tab_no = nil
  for _, channel in pairs(nirc_data.channel) do
    api.nvim_buf_delete(channel.buf_id)
  end
  nirc_data.display[server_name] = nil
  nirc_data.channel_list = nil
  nirc_data.active_channel = nil
end

-- Open a new buffer for channel chan_name and return the buffer
function display.new_channel(chan_name)
  local buf = api.nvim_create_buf(false, false)
  api.nvim_buf_set_option(buf, 'filetype', 'nirc')
  api.nvim_buf_set_option(buf, 'syntax', 'nirc')
  api.nvim_buf_set_option(buf, 'buftype', 'prompt')
  api.nvim_buf_set_name(buf, chan_name)
  api.nvim_buf_set_var(buf, "NIRC_chan_name",chan_name)
  vim.fn.prompt_setprompt(buf, utils.get_prompt())
  vim.fn.prompt_setcallback(buf, keymaps.send)

  local nirc_data = require'nirc.data'
  table.insert(nirc_data.channels, {
    buf_no = buf,
    name = chan_name})
  nirc_data.channel_list[chan_name] = #nirc_data.channels
  nirc_data.channel_list[buf] = #nirc_data.channels
  return buf
end

-- Remove the channel chan_name
function display.remove_channel(chan_name)
  local nirc_data = require'nirc.data'
  local channel_id = nirc_data.channel_list[chan_name]
  if not channel_id then return false end
  local buf_id = nirc_data.channels[channel_id].buf_no
  api.nvim_buf_delete(buf_id)
  nirc_data.channel_list[buf_id] = nil
  nirc_data.channel_list[chan_name] = nil
  table.remove(nirc_data.channels, channel_id)
  return true
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
    api.nvim_buf_set_lines(nirc_data.display.preview_win.buf, -1, -1, false, msg_strs)
    local current_wins = api.nvim_tabpage_list_wins(0)
    for _, win_no in pairs(current_wins) do
      if win_no == nirc_data.display.preview_win.win then
        local cur_win = api.nvim_get_current_win()
        api.nvim_set_current_win(nirc_data.display.preview_win.win)
        vim.cmd[[silent! normal! G]]
        api.nvim_set_current_win(cur_win)
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
  if #name > max_size then
    name = string.format('<%s.>',name:sub(1, max_size - 1))
  elseif #name < max_size then
    local size = #name
    local r_padding = math.floor((max_size - size) / 2)
    local l_padding
    if ((2 * r_padding) + size) == max_size then
      l_padding = r_padding
    else
      l_padding = r_padding + 1
    end
    name = string.format('%s<%s>%s', string.rep(' ', l_padding), name, string.rep(' ', r_padding))
  else
    name = '<'..name..'>'
  end
  local message = msg.args[#msg.args]
  local splited_message = utils.str_split_len(message, vim.fn.winwidth(0) - (1+5+2+2+max_size+2+2+1+2+5))
  local formated_message = {}
  table.insert(formated_message, string.format(' %s  %s  %s  %s', time, name, separator, splited_message[1]))
  for i=2, #splited_message do
    table.insert(formated_message, string.format(' %s  %s  %s  %s', string.rep(' ', 5), string.rep(' ', max_size + 2), separator, splited_message[i]))
  end
  return formated_message
end

-- Switch to channel chan_name
function display.switch_channel(chan_name)
  local nirc_data = require'nirc.data'
  local chan_id = nirc_data.channel_list[chan_name]
  if not chan_id then return false end
  api.nvim_set_current_buf(nirc_data.channels[chan_id].buf_no)
  -- vim.cmd[[silent! normal! G]]
end

function display.next_channel()
  local nirc_data = require'nirc.data'
  if #nirc_data.channels < 2 then return end
  local chan_name = ''
  local current_channel = vim.b.NIRC_channel_name
  if not current_channel then return end
  local channel_id  = nirc_data.channel_list[current_channel]
  if nirc_data.channels[channel_id + 1] then
    chan_name = nirc_data.channels[channel_id + 1].name
  else
    -- last channel wrap arround
    chan_name = nirc_data.channels[1].name
  end
  display.switch_channel(chan_name)
end

function display.prev_channel()
  local nirc_data = require'nirc.data'
  if #nirc_data.channels < 2 then return end
  local chan_name = ''
  local current_channel = vim.b.NIRC_channel_name
  if not current_channel then return end
  local channel_id  = nirc_data.channel_list[current_channel]
  if nirc_data.channels[channel_id - 1] then
    chan_name = nirc_data.channels[channel_id - 1].name
  else
    -- last channel wrap arround
    chan_name = nirc_data.channels[#nirc_data.channels].name
  end
  display.switch_channel(chan_name)
end

function display.channels()
  local nirc_data = require'nirc.data'
  local chan_names = {}
  for _, channel in pairs(nirc_data.channels) do
    table.insert(chan_names, channel.name)
  end
  return chan_names
end

return display
