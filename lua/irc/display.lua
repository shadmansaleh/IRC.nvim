local display = {}

local utils = require'irc.utils'
local keymaps = require'irc.keymaps'
local api = vim.api
local fmt = string.format

local win_width = 80 -- TODO: Figure out what to do with it :P

function display.open_view()
  local irc_data = require'irc.data'
  local server_name = irc_data.active_client
  irc_data.display = irc_data.display
  if irc_data.display[server_name] then
    -- Page layput already available switch to it
    local server_data = irc_data.display[server_name]
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
  irc_data.display[server_name] = server_data
  irc_data.channel_list[server_name] = {}

  vim.cmd("tabnew")
  server_data.tab_no = api.nvim_get_current_tabpage()
  server_data.buf = api.nvim_get_current_buf()
  server_data.win = api.nvim_get_current_win()
  api.nvim_set_current_buf(server_data.buf)

  -- set options
  api.nvim_win_set_option(server_data.win, 'number', false)
  api.nvim_win_set_option(server_data.win, 'relativenumber', false)
  server_data.buf = display.new_channel(server_name, server_data.buf)
  vim.fn.prompt_setprompt(server_data.buf, "IRC > ")
  vim.cmd('silent! startinsert')
  return true
end

function display.close_view()
  local irc_data = require'irc.data'
  local server_name = irc_data.active_client
  if not server_name then return false end
  local server_data = irc_data.display[server_name]
  api.nvim_buf_delete(server_data.buf, {force = true})
  vim.cmd([[
  silent! tabclose
  silent! stopinsert
  ]])
  server_data.win = nil
  server_data.tab_no = nil
  for _, channel in pairs(irc_data.channels) do
    api.nvim_buf_delete(channel.buf_id or 0, {force=true})
  end
  irc_data.display[server_name] = {}
  irc_data.channel_list = {}
end

-- Open a new buffer for channel chan_name and return the buffer
function display.new_channel(chan_name, buf_id)
  local buf = api.nvim_create_buf(true, true)
  if buf_id then
    -- Abit hacky . But opening new tab doesn;t give me a scratch
    -- buffer . So we open a new one and delete the older one
    api.nvim_set_current_buf(buf)
    api.nvim_buf_delete(buf_id, {force=true})
  end
  api.nvim_buf_set_option(buf, 'filetype', 'irc')
  api.nvim_buf_set_option(buf, 'syntax', 'irc')
  api.nvim_buf_set_option(buf, 'buftype', 'prompt')
  api.nvim_buf_set_option(buf, 'swapfile', false)
  api.nvim_buf_set_name(buf, chan_name)
  api.nvim_buf_set_var(buf, "IRC_channel_name",chan_name)
  vim.fn.prompt_setprompt(buf, utils.get_prompt())
  vim.fn.prompt_setcallback(buf, keymaps.send_msg)
  vim.cmd(fmt('autocmd IRC BufEnter <buffer=%d> startinsert', buf))

  local irc_data = require'irc.data'
  table.insert(irc_data.channels, {
    buf_no = buf,
    name = chan_name})
  irc_data.channel_list[chan_name] = #irc_data.channels
  irc_data.channel_list[buf] = #irc_data.channels
  return buf
end

-- Remove the channel chan_name
function display.remove_channel(chan_name)
  local irc_data = require'irc.data'
  local channel_id = irc_data.channel_list[chan_name]
  if not channel_id then return false end
  local buf_id = irc_data.channels[channel_id].buf_no
  api.nvim_buf_delete(buf_id, {force=true})
  irc_data.channel_list[buf_id] = nil
  irc_data.channel_list[chan_name] = nil
  table.remove(irc_data.channels, channel_id)
  return true
end

-- Display mesaage
function display.show(msg)
  local irc_data = require'irc.data'
  local client = irc_data.clients[irc_data.active_client]

  -- Figure out what the xhannels name is suppose to be
  local chan_name = 'UnDetected' -- Shouldn't ever be the case
  if msg.cmd == 'PRIVMSG' or msg.cmd == 'NOTICE'then
    if msg.args[1] == client.config.nick then
      chan_name = msg.nick or irc_data.active_client
    else
      if not msg.nick then
        chan_name = irc_data.active_client
      else
        chan_name = msg.args[1]
      end
    end
  else
    chan_name = irc_data.active_client
  end

  -- Redirect these channels to different destination
  local redirect_channels = {
    NickServ = irc_data.active_client,
    ChanServ = irc_data.active_client,
    SaslServ = irc_data.active_client,
  }

  if redirect_channels[chan_name] then
    chan_name = redirect_channels[chan_name]
  end

  if not irc_data.channel_list[chan_name] then
    -- First message on this channel. Create the channel buffer
    -- [[ Don't think ever should happen
    -- if #irc_data.active_channel <= 0 then
    --   irc_data.active_channel = chan_name
    -- end
    -- ]]
    display.new_channel(tostring(chan_name)) -- TODO: Error chack
  end

  local buf_id = irc_data.channels[irc_data.channel_list[chan_name]].buf_no
  local msg_strs = display.format_msg(msg)
  local line_cnt = api.nvim_buf_line_count(buf_id)
  if #msg_strs > 0 then
    local time = os.date('%2H:%2M')
    if utils.buf_get_var(buf_id, 'IRC_last_message_time') ~= time then
      -- If last message was older then 1 minute show current time
      api.nvim_buf_set_var(buf_id, 'IRC_last_message_time', time)
      vim.fn.appendbufline(buf_id, line_cnt - 1,
                           string.rep(' ', win_width - 9 - 10)..'[ '..time..' ]')
      line_cnt = line_cnt + 1
    end
  end
  -- Add the message to 2nd last line of buffer
  vim.fn.appendbufline(buf_id, line_cnt - 1, msg_strs)
end

function display.format_msg(msg)
  if msg.disp_msg then return {msg.disp_msg} end
  local name = msg.nick or msg.addr
  local message = msg.args[#msg.args]
  local splited_message = utils.str_split_len(message, win_width - #name - 3)
  local formated_message = {}
  table.insert(formated_message, fmt('%s > %s', name, splited_message[1]))
  for i=2, #splited_message do
    table.insert(formated_message, fmt('%s > %s', string.rep(' ', #name),
                                       splited_message[i]))
  end
  return formated_message
end

-- Switch to channel chan_name
function display.switch_channel(chan_name)
  local irc_data = require'irc.data'
  local chan_id = irc_data.channel_list[chan_name]
  if not chan_id then return false end
  api.nvim_set_current_buf(irc_data.channels[chan_id].buf_no)
  -- vim.cmd[[silent! normal! G]]
end

function display.next_channel()
  local irc_data = require'irc.data'
  if #irc_data.channels < 2 then return end
  local chan_name = ''
  local current_channel = vim.b.IRC_channel_name
  if not current_channel then return end
  local channel_id  = irc_data.channel_list[current_channel]
  if irc_data.channels[channel_id + 1] then
    chan_name = irc_data.channels[channel_id + 1].name
  else
    -- last channel wrap arround
    chan_name = irc_data.channels[1].name
  end
  display.switch_channel(chan_name)
end

function display.prev_channel()
  local irc_data = require'irc.data'
  if #irc_data.channels < 2 then return end
  local chan_name = ''
  local current_channel = vim.b.IRC_channel_name
  if not current_channel then return end
  local channel_id  = irc_data.channel_list[current_channel]
  if irc_data.channels[channel_id - 1] then
    chan_name = irc_data.channels[channel_id - 1].name
  else
    -- last channel wrap arround
    chan_name = irc_data.channels[#irc_data.channels].name
  end
  display.switch_channel(chan_name)
end

function display.channels()
  local irc_data = require'irc.data'
  local chan_names = {}
  for _, channel in pairs(irc_data.channels) do
    table.insert(chan_names, channel.name)
  end
  return chan_names
end

return display
