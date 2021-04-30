local handlers = {}

local protocol = require'nirc.irc.protocol'

local buffer_text = {}
local buf_nr = 111
local pr = print

-- Temporary solution for testing
local function print(...)
  for _, arg in pairs({...}) do
    if type(arg) == 'string' then
      for line in vim.gsplit(arg,'\n') do
        table.insert(buffer_text, line)
        pr(line)
      end
    end
  end
  vim.api.nvim_buf_set_lines(buf_nr, 0, -1, false, buffer_text)
end

-- Gets called for all events
function handlers.default_handler(_, responce)
  print(string.format('%s(%s) > %s', responce.nick or responce.addr or responce.source, responce.cmd, responce.args[#responce.args]))
end

-- Makes initial contact with the server
local function handshake(client, responce)
  if responce.cmd == 'NOTICE' and responce.args[#responce.args]:find('No Ident response') then
    client:send_cmd('nick', client.config.nick)
    client:send_cmd('user', client.config.nick, client.config.nick)
    return false
  end
  -- we are accepted
  if responce.cmd == '376' then
    return true
  end
  --username already in use
  if responce.cmd == '433' then
    client.config.nick = '_'..client.config.nick
    client:send_cmd("nick", client.config.nick)
    client:send_cmd('user', client.config.nick, client.config.nick)
    return false
  end
  -- Ping from server
  if responce.cmd == 'PING' then
    client:send_raw('PONG :%s', responce.args[#responce.args])
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
