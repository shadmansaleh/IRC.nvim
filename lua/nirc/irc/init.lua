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
    server = 'irc.freenode.net',
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
  if not self.buffer then
    vim.cmd('new')
    self.buffer = vim.fn.bufnr()
  end
  local server_data = uv.getaddrinfo(conf.server, nil, {family = 'inet', socktype = 'stream'})
  if server_data then conf.server_ip = server_data[1].addr
  else error("Unable to locate " .. conf.server) end
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
  if msg then
    self.conc:write(msg..'\r\n')
    local parsed_msg = protocol.parse_msg(msg)
    parsed_msg.nick = self.config.nick
    handlers.default_handler(self, parsed_msg)
  end
end

function client:prompt(str)
  local args = vim.split(str, ' ')
  if args[1]:sub(1,1) == '/' then
    local cmd = args[1]:sub(2)
    table.remove(args, 1)
    self:send_cmd(cmd, unpack(args))
  end
end

function client:disconnect()
  self.conc:read_stop()
  if not self.conc:is_closing() then
    self.conc:close()
  end
end

return client
