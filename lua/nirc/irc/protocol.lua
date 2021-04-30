local protocol = {}

-- Supported comands
protocol.commands = {
  join = {'JOIN %s', args = 1},
  part = {'PART %s',  args = 1},
  msg  = {'PRIVMSG %s %s', args = 2},
  nick = {'NICK %s', args = 1},
  user = {'USER %s 0 * %s', args = 2},
  quit = {'QUIT', args = 1}
}

-- Supported alaises
protocol.aliases = {
  j = 'join',
  p = 'part',
  m = 'msg'
}

function protocol.cmd_format(...)
  local args = {...}
  local cmd = args[1]
  table.remove(args, 1)
  if protocol.aliases.cmd then cmd = protocol.aliases[cmd] end
  if protocol.commands[cmd] then
    local msg = {}
    for i=protocol.commands[cmd].args, #args do
      table.insert(msg, args[i])
    end
    table.insert(args, protocol.commands[cmd].args, ':'..table.concat(msg, ' '))
    return string.format(protocol.commands[cmd][1], unpack(args))
  end
  return nil, 'Unsupported command'
end

--[[ Valid massege example
  :irc.example.com CAP LS * :multi-prefix extended-join sasl\r\n

  @id=234AB :dan!d@localhost PRIVMSG #chan :Hey what's up!\r\n

  CAP REQ :sasl\r\n
--]]

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
  index = msg:find(' ', index) + 1 -- add one to skip space
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
