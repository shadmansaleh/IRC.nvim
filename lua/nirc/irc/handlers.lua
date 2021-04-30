--[[

  Mainly handles replies from server
  If a handler named command exists in handlers
  table it'll be called .

  And default_handler will be called for all cases

--]]
local handlers = {}

local protocol = require'nirc.irc.protocol'

local buffer_text = {}

-- Temporary solution for testing
local function show(buf_nr, ...)
  for _, arg in pairs({...}) do
    if type(arg) == 'string' then
      for line in vim.gsplit(arg,'\n') do
        table.insert(buffer_text, line)
      end
    end
  end
  vim.api.nvim_buf_set_lines(buf_nr, 0, -1, false, buffer_text)
end

-- Gets called for all events
function handlers.default_handler(client, responce)
  show(client.buffer, string.format('%s > %s', responce.nick or responce.addr or responce.source, table.concat(responce.args, ' ')))
  vim.api.nvim_set_current_win(require'nirc.display'.data.preview_win.win)
  vim.cmd[[silent! normal! G]]
  vim.api.nvim_set_current_win(require'nirc.display'.data.prompt_win.win)
end

-- Handle pings
function handlers.PING(client, responce)
  client:send_raw('PONG :%s', responce.args[#responce.args])
end

-- Handle Nick name already in use
handlers['433'] = function(client, _)
  client.config.nick = '_'..client.config.nick
  client:send_cmd("nick", client.config.nick)
end

function handlers.ERROR(client, responce)
  if responce.args[#responce.args]:upper():find('QUIT') then
    client:disconnect()
  end
end

-- Makes initial contact with the server
function handlers.post_connect(client)
  if client.config.pass then
    client:send_cmd('pass', client.config.pass)
  end
  client:send_cmd('nick', client.config.nick)
  client:send_cmd('user', client.config.username, client.config.username)
end

local function handshake(client, responce)
  -- we are accepted
  if responce.cmd == '001' then
    return true
  --username already in use
  elseif responce.cmd == '433' then
    client.config.nick = '_'..client.config.nick
    client:send_cmd("nick", client.config.nick)
    client:send_cmd('user', client.config.username, client.config.username)
    return false
  -- Ping from server or anything else
  elseif handlers[responce.cmd] then
    handlers[responce.cmd](client, responce)
    return false
  end
end

local chunk_buffer = ''

-- Handles responses from the server
function handlers.responce_handler(client, err, chunk)
  if not err and chunk then
    chunk = chunk_buffer .. chunk
    local lines = vim.split(chunk, '\r\n')
    if not vim.endswith(chunk, '\r,\n') then
      chunk_buffer = lines[#lines] or ''
      table.remove(lines, #lines)
    end
    for _, line in pairs(lines) do
      if #line > 1 then
        local responce = protocol.parse_msg(line)
        if not client.config.handshake_done then
          client.config.handshake_done = handshake(client, responce)
        elseif handlers[responce.cmd] then
          handlers[responce.cmd](client, responce)
        end
        handlers.default_handler(client, responce)
      end
    end
  end
end

return handlers
