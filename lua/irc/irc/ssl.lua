-- Adapted from https://github.com/zhaozg/lua-openssl/blob/master/lib/luv/ssl.lua

local uv = vim.loop
-- local buf_size = 8192
local buf_size = 4096
-- local buf_size = 65536

local openssl = require 'openssl'
local ssl, bio, x509, pkey = openssl.ssl, openssl.bio, openssl.x509, openssl.pkey
-- local extension = require("openssl.x509.extension")

local print = print
-- support
local uv_ssl = {}

local function load (path)
  local f = io.open(path, 'rb')
  if f then
    local c = f:read '*a'
    f:close()
    return c
  end
end

function uv_ssl.new_ctx (params)
  params = params or {}
  local protocol = params.protocol or 'SSLv3_client'
  local ctx = ssl.ctx_new(protocol, params.ciphers)

  local xkey, xcert = nil, nil

  if params.certificate then
    local ctx = assert(load(params.certificate))
    xcert = assert(x509.read(ctx))
  end

  if params.key then
    if type(params.password) == 'nil' then
      xkey = assert(pkey.read(load(params.key), true, 'pem'))
    elseif type(params.password) == 'string' then
      xkey = assert(pkey.read(load(params.key), true, 'pem', params.password))
    elseif type(params.password) == 'function' then
      local p = assert(params.password())
      xkey = assert(pkey.read(load(params.key), true, 'pem', p))
    end
    assert(ctx:use(xkey, xcert))
  end

  if params.cafile or params.capath then
    ctx:verify_locations(params.cafile, params.capath)
  end

  if params.verify then
    ctx:verify_mode(params.verify)
  end
  if params.options and #params.options > 0 then
    local args = {}
    for i = 1, #params.options do
      table.insert(arg, params.options[i])
    end
    ctx:options(ssl.none)
  end

  if params.verifyext then
    ctx:set_cert_verify(params.verifyext)
  end
  if params.dhparam then
    ctx:set_tmp('dh', params.dhparam)
  end
  if params.curve then
    ctx:set_tmp('ecdh', params.curve)
  end
  return ctx
end

local S = {}
S.__index = {
  handshake = function (self, connected_cb)
    if not self.connecting then
      uv.read_start(self.socket, function (err, chunk)
          if err then
            -- print('ERR', err)
            if self.onerror then self:onerror(err) end
          end
          if chunk then
            self.inp:write(chunk)
            self:handshake(connected_cb)
          else
            self:close()
          end
        end)

      self.connecting = true
    end
    if not self.connected then
      local ret, err = self.ssl:handshake()
      if ret == nil then
        if self.onerror then
          self:onerror()
        elseif self.onclose then
          self:onclose()
        else
          self:close()
        end
      else
        local i, o = self.out:pending()
        if i > 0 then
          --client handshake
          uv.write(self.socket, self.out:read(), function ()
              self:handshake(connected_cb)
            end)
          return
        end
        if ret == false then
          return
        end

        self.connected = true
        uv.read_stop(self.socket)
        uv.read_start(self.socket, function (err, chunk)
            if err then
              -- print('ERR', err)
              if self.onerror then self:onerror(err) end
            end
            if chunk then
              local ret, err = self.inp:write(chunk)
              if ret == nil then
                if self.onerror then
                  self.onerror(self)
                elseif self.onend then
                  self.onend(self)
                end
                return
              end

              while self.connected and self.inp:pending()>0 do
                if o > 0 then
                  assert(false, 'never here')
                end
              -- TODO: need to either know the document size and set buffer accordingly beforehand,
              -- or poll for more chunks
                local ret, msg = self.ssl:read()
                if ret then
                  -- print("data: " .. (msg or ""))
                  self:ondata(ret)
                else
                  -- print("catch me: " .. msg)
                  -- local dog, cat = self.ssl:read()
                  -- print(dog)
                end
              end
            else
              self:close()
            end
          end)
        connected_cb(self)
      end

      return self.connected
    end
  end,
  shutdown = function(self, callback)
    if not self.shutdown then
      self.ssl:shutdown()
      self.socket:shutdown()
      if callback then
        callback(self)
      end
      self.shutdown = true
    end
  end,
  close = function (self)
    if self.connected then
      if self.onclose then
        self.onclose(self)
      end
      self:shutdown()
      if self.ssl then
        self.ssl:shutdown()
      end
      self.ssl = nil
      if self.inp then
        self.inp:close()
      end
      if self.out then
        self.out:close()
      end

      self.out, self.inp = nil, nil
      uv.close(self.socket)
      self.connected = nil
      self.socket = nil
    end
  end,
  write = function (self, data, cb)
    if not self.ssl then
      return
    end
    local ret, err = self.ssl:write(data)
    if ret == nil then
      if self.onerror then
        self.onerror(self)
      elseif self.onend then
        self.onend(self)
      end
      return
    end
    local i, o = self.out:pending()
    if i > 0 then
      uv.write(self.socket, self.out:read(), cb)
    end
    if o > 0 then
      assert(false, 'never here')
    end
  end,

}

function uv_ssl.new_ssl (ctx, socket, server)
  local s = {}
  s.inp, s.out = bio.mem(buf_size), bio.mem(buf_size)
  s.socket = socket
  s.mode = server and server or false
  s.ssl = ctx:ssl(s.inp, s.out, s.mode)
  uv.tcp_nodelay(socket, true)

  setmetatable(s, S)
  return s
end

function uv_ssl.connect (host, port, ctx, connected_cb)
  if type(ctx) == 'table' then
    ctx = ssl.new_ctx(ctx)
  end
  local socket = uv.new_tcp()
  local scli = uv_ssl.new_ssl(ctx, socket)

  uv.tcp_connect(socket, host, port, function (self, err)
      if err then
        -- print('ERROR', err)
      else
        -- print('SCLI', scli)
        scli:handshake(function (self)
            if connected_cb then
              connected_cb(self)
            end
          end)
      end
    end)

  return scli
end

function uv_ssl.error ()
  return openssl.error(true)
end

--Adapted from https://github.com/nvim-telescope/telescope-arecibo.nvim
local M = {}
local DEFAULT_CIPHERS = 'ECDHE-RSA-AES128-SHA256:AES128-GCM-SHA256:' ..   -- TLS 1.2
                        '!RC4:HIGH:!MD5:!aNULL:!EDH'                      -- TLS 1.0
function M.connect(args)
  local params = {
    protocol = "TLS",
    ciphers  = DEFAULT_CIPHERS,
    mode     = 'client',
  }
  local ctx = assert(uv_ssl.new_ctx(params))
  local cli = assert(uv_ssl.connect(args.host, args.port, ctx, args.connect_cb))

  function cli:ondata(chunk)
    return args.reader_cb(chunk)
  end
  return cli
end

return M
