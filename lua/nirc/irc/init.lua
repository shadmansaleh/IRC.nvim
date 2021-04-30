local client = {}

local log = require('nirc.log')
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
  local server_data = uv.getaddrinfo(conf.server, nil, {family = 'inet', socktype = 'stream'})
  if server_data then conf.server_ip = server_data[1].addr
  else error("Unable to locate " .. conf.server) end
  self.conc = uv.new_tcp()
  uv.tcp_connect(self.conc, conf.server_ip, conf.port, function(err)
    assert(not err, err)
    self.conc:read_start(vim.schedule_wrap(function(err, chunk)
      handlers.responce_handler(self, err, chunk)
    end))
  end)
end

function client:send_cmd(cmd, ...)
  local msg = protocol.cmd_format(cmd, ...)
  self.conc:write(msg..'\r\n')
end

function client:send_raw(...)
  local msg = string.format(...)
  self.conc:write(msg..'\r\n')
end

function client:prompt(str)
  local snip = vim.split(str, ' ')
  if snip[1]:sub(1,1) == '/' then
    local cmd = snip[1]:sub(2)
    table.remove(snip, 1)
    self:send_cmd(cmd, unpack(snip))
  end
end

return client
