--[[

  This file implements abtraction layer over the connection.
  It connects, receives and sends messages to server.

  The user should call cliant:prompt() for all kinds of
  interaction with the server.

--]]

local client = {}

local handlers = require('nirc.irc.handlers')
local protocol = require('nirc.irc.protocol')

local uv = vim.loop

function client:new(config)
  if not config then config = {} end
  local new_client = {}
  local default_config = {
    server = 'irc.libera.chat',
    port = 6667,
    nick = os.getenv('USER') or 'nirc_user',
    username = os.getenv('USER') or 'nirc_user',
  }
  new_client.config = vim.tbl_extend('keep', config, default_config)
  return setmetatable(new_client, {__index = client})
end

function client:connect()
  local conf = self.config
  conf.handshake_done = false
  local server_data = uv.getaddrinfo(conf.server, nil, {family = 'inet', socktype = 'stream'})
  assert(server_data, "Unable to locate " .. conf.server)
  conf.server_ip = server_data[1].addr
  self.conc = uv.new_tcp()
  uv.tcp_connect(self.conc, conf.server_ip, conf.port, function(err)
    assert(not err, err)
    self.conc:read_start(vim.schedule_wrap(function(error, chunk)
      handlers.responce_handler(self, error, chunk)
    end))
    vim.schedule_wrap(function() handlers.post_connect(self) end)()
  end)
end

function client:send_cmd(cmd, ...)
  local ok, msg = protocol.cmd_execute(self, cmd, ...)
  if not ok then print(msg) end
end

function client:send_raw(...)
  local msg = vim.trim(string.format(...))
  if msg then self.conc:write(msg..'\r\n') end
end

function client:prompt(str, current_channel)
  local args = vim.split(str, ' ')
  local cmd = ''
  if args[1]:byte(1) == string.byte('/') then
    cmd = args[1]:sub(2)
    table.remove(args, 1)
  else
    cmd = 'msg'
    table.insert(args, 1, current_channel)
  end
  self:send_cmd(cmd, unpack(args))
end

function client:disconnect()
  local nirc_data = require'nirc.data'
  self.conc:read_stop()
  if not self.conc:is_closing() then
    self.conc:close()
  end
  nirc_data.clients[nirc_data.active_client] = nil
  nirc_data.active_client = nil
end

return client
