--[[

  Mainly hanldes sending properly formated messages to server.
  Besides that parse_message parses both massages ariving from
  server and messages sent to server.

  if a function exists with cammand name in command_handlers table
  it will be called to handle the cmd.
  Otherwise the default handler will be called to handle the cmd.

  Default handler looks up command_strs and formats the message

  In the end all messages are sent with client:send_raw()

--]]

local display = require'nirc.display'
local protocol = {}

-- Command patterns used by default handler to handle commands
protocol.commands_strs = {
  -- name = { format, arg_count }
  admin = {'ADMIN %s', 1},
  away = {'AWAY %s', 1},
  connect = {'CONNECT %s %s %s', 3},
  die = {'DIE', 0},
  info = {'INFO %s', 1},
  invite = {'INVITE %s %s', 2},
  ison = {'ISON %s', 1},
  join = {'JOIN %s %s', 2},
  kick = {'KICK %s %s %s', 3},
  kill = {'KILL %s %s', 2},
  links = {'LINKS %s %s', 2},
  list = {'LIST %s', 1},
  lusers = {'LUSERS %s %s', 2},
  mode = {'MODE %s %s %s', 3},
  motd = {'MOTD %s', 1},
  names = {'NAMES %s', 1},
  nick = {'NICK %s', 1},
  notice = {'NOTICE %s %s', 2},
  oper = {'OPER %s %s', 2},
  part = {'PART %s %s',  2},
  pass = {'PASS %s', 1},
  quit = {'QUIT %s', 1},
  rehash = {'REHASH', 0},
  restart = {'RESTART', 1},
  servlist = {'SERVLIST %s %s', 1},
  stats = {'STATS %s %s', 2},
  squery = {'SQUERY %s %s', 2},
  squit = {'SQUIT %s %s', 2},
  summon = {'SUMMON %s %s', 2},
  time = {'TIME %s', 1},
  topic = {'TOPIC %s %s', 2},
  trace = {'TRACE %s', 1},
  userhost = {'USERHOST %s %s %s %s %s', 5},
  users = {'USERS %s', 1},
  user = {'USER %s 8 * :%s', 2},
  version = {'VERSION %s', 1},
  wallops = {'WALLOPS, %s', 1},
  whois = {'WHOIS %s %s', 2},
  whowas = {'WHOWAS %s %s %s',3},
  who = {'WHO %s %s', 2},
}

-- Supported alaises
protocol.aliases = {
  j = 'join',
  p = 'part',
  m = 'msg'
}

local command_handlers = {}

function command_handlers.default(client, cmd, ...)
  local args = {...}
  if protocol.commands_strs[cmd] then
    if #args > protocol.commands_strs[cmd][2] then
      local joined_tail = {}
      for i=protocol.commands_strs[cmd][2], #args do
        table.insert(joined_tail, args[i])
      end
      table.insert(args, protocol.commands_strs[cmd][2], table.concat(joined_tail, ' '))
    elseif #args < protocol.commands_strs[cmd][2] then
      for i=#args + 1, protocol.commands_strs[cmd][2] do
        table.insert(args, i, '')
      end
    end
    client:send_raw(protocol.commands_strs[cmd][1], unpack(args))
    return true, 'command sent'
  end
  return false, 'Unsupported command'
end

-- raw commands
function command_handlers.raw(client, _, ...)
  client:send_raw(table.concat({...}, ' '))
  return true, 'Raw sent'
end

-- change nick name
function command_handlers.nick(client, _, ...)
  client.config.old_nick = client.config.nick
  client.config.nick = select(1, ...)
  client:send_raw(protocol.commands_strs.nick[1], ...)
  return true, 'Command sent'
end

-- Handle PRIVNSG
function command_handlers.msg(client, _, ...)
  local args = {...}
  local msg = {}
  for i=2, #args do
    table.insert(msg, args[i])
  end
  table.insert(args, 2, ':'..table.concat(msg, ' '))
  local message = vim.trim(string.format('PRIVMSG %s %s', unpack(args)))
  client:send_raw(message)
  local parsed_msg = {
    cmd = 'PRIVMSG',
    nick = client.config.nick,
    args = {args[1], args[2]:sub(2)},
  }
  parsed_msg.nick = client.config.nick
  require'nirc.display'.show(parsed_msg)
  return true, 'command sent'
end

function command_handlers.part(client, _, ...)
  local chan_name = select(1, ...)
  if chan_name == nil then
    chan_name = vim.b.NIRC_channel_name
  end
  client:send_raw(protocol.commands_strs.part[1], chan_name, select(2, ...) or '')
  display.remove_channel(chan_name)
  if vim.b.NIRC_channel_name == chan_name then
    require'nirc.display'.prev_channel()
  end
  return true, 'Command sent'
end

-- Calls a handler specific for the command if exists otherwise
-- Calls the default handler
function protocol.cmd_execute(client, cmd, ...)
  if protocol.aliases[cmd] then cmd = protocol.aliases[cmd] end
  if command_handlers[cmd] then
    return command_handlers[cmd](client, cmd, ...)
  else
    return command_handlers.default(client, cmd, ...)
  end
end


--[[ Valid massege example
  :irc.example.com CAP LS * :multi-prefix extended-join sasl\r\n

  @id=234AB :dan!d@localhost PRIVMSG #chan :Hey what's up!\r\n

  CAP REQ :sasl\r\n
--]]
-- Parses a message and returns a dict with relavent data extracted
-- from message
function protocol.parse_msg(msg)
  local result = {}
  result.args = {}
  local index = 1
  if msg:find('@') == 1 then
    local next_colon = msg:find(':', index)
    local next_space = msg:find(' ', index)
    local tags_end  = next_colon < next_space and next_colon or next_space
    -- sub 1 to remove separator(space)
    result.tags = msg:sub(index, tags_end - 1)
    index = tags_end + 1 -- add one to skip space
  end
  if msg:find(':') == index then
    local id = index + 1
    index = msg:find(' ', index) + 1 -- add one to skip space
    local source = msg:sub(id, index - 2)
    local name = source:find('!')
    local addr = source:find('@')
    if name and addr then
      result.nick, result.username, result.addr = source:match('(.-)!(.-)@(.*)')
    elseif not name and addr then
      result.nick, result.addr = source:match('(.-)@(.*)')
    else
      result.addr = source
    end
    result.source = source
  end
  result.cmd = msg:match('%S+', index)
  if msg:find(' ', index) then
    index = msg:find(' ', index) + 1 -- add one to skip space
  end
  local last_arg_start = msg:find(':', index)
  if not last_arg_start then
    result.args = vim.split(msg:sub(index, #msg), ' ')
  else
    if last_arg_start ~= index then
      -- substract 2 to skip space and ':'
      result.args = vim.split(msg:sub(index, last_arg_start - 2), ' ')
      -- plus 1 to skip ':'
      index = last_arg_start + 1
    else
      -- plus 1 to skip ':'
      index = index + 1
    end
    table.insert(result.args, msg:sub(index, #msg))
  end
  return result
end

return protocol
