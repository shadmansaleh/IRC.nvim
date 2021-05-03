--[[

  Mainly handles replies from server
  If a handler named command exists in handlers
  table it'll be called .

  otherwise default_handler will be called

--]]
local handlers = {}

local protocol = require'nirc.irc.protocol'

local numerics = {
  ['001'] = 'RPL_WELCOME',
  ['002'] = 'RPL_YOURHOST',
  ['003'] = 'RPL_CREATED',
  ['004'] = 'RPL_MYINFO',
  ['005'] = 'RPL_ISUPPORT',
  ['010'] = 'RPL_BOUNCE',
  ['221'] = 'RPL_UMODEIS',
  ['251'] = 'RPL_LUSERCLIENT',
  ['252'] = 'RPL_LUSEROP',
  ['253'] = 'RPL_LUSERUNKNOWN',
  ['254'] = 'RPL_LUSERCHANNELS',
  ['255'] = 'RPL_LUSERME',
  ['256'] = 'RPL_ADMINME',
  ['257'] = 'RPL_ADMINLOC1',
  ['258'] = 'RPL_ADMINLOC2',
  ['259'] = 'RPL_ADMINEMAIL',
  ['263'] = 'RPL_TRYAGAIN',
  ['265'] = 'RPL_LOCALUSERS',
  ['266'] = 'RPL_GLOBALUSERS',
  ['276'] = 'RPL_WHOISCERTFP',
  ['300'] = 'RPL_NONE',
  ['301'] = 'RPL_AWAY',
  ['302'] = 'RPL_USERHOST',
  ['303'] = 'RPL_ISON',
  ['305'] = 'RPL_UNAWAY',
  ['306'] = 'RPL_NOWAWAY',
  ['311'] = 'RPL_WHOISUSER',
  ['312'] = 'RPL_WHOISSERVER',
  ['313'] = 'RPL_WHOISOPERATOR',
  ['314'] = 'RPL_WHOWASUSER',
  ['317'] = 'RPL_WHOISIDLE',
  ['318'] = 'RPL_ENDOFWHOIS',
  ['319'] = 'RPL_WHOISCHANNELS',
  ['321'] = 'RPL_LISTSTART',
  ['322'] = 'RPL_LIST',
  ['323'] = 'RPL_LISTEND',
  ['324'] = 'RPL_CHANNELMODEIS',
  ['329'] = 'RPL_CREATIONTIME',
  ['331'] = 'RPL_NOTOPIC',
  ['332'] = 'RPL_TOPIC',
  ['333'] = 'RPL_TOPICWHOTIME',
  ['341'] = 'RPL_INVITING',
  ['346'] = 'RPL_INVITELIST',
  ['347'] = 'RPL_ENDOFINVITELIST',
  ['348'] = 'RPL_EXCEPTLIST',
  ['349'] = 'RPL_ENDOFEXCEPTLIST',
  ['351'] = 'RPL_VERSION',
  ['353'] = 'RPL_NAMREPLY',
  ['366'] = 'RPL_ENDOFNAMES',
  ['367'] = 'RPL_BANLIST',
  ['401'] = 'ERR_NOSUCHNICK',
  ['402'] = 'ERR_NOSUCHSERVER',
  ['403'] = 'ERR_NOSUCHCHANNEL',
  ['404'] = 'ERR_CANNOTSENDTOCHAN',
  ['405'] = 'ERR_TOOMANYCHANNELS',
  ['421'] = 'ERR_UNKNOWNCOMMAND',
  ['422'] = 'ERR_NOMOTD',
  ['432'] = 'ERR_ERRONEUSNICKNAME',
  ['433'] = 'ERR_NICKNAMEINUSE',
  ['441'] = 'ERR_USERNOTINCHANNEL',
  ['442'] = 'ERR_NOTONCHANNEL',
  ['443'] = 'ERR_USERONCHANNEL',
  ['451'] = 'ERR_NOTREGISTERED',
  ['461'] = 'ERR_NEEDMOREPARAMS',
  ['462'] = 'ERR_ALREADYREGISTERED',
  ['464'] = 'ERR_PASSWDMISMATCH',
  ['465'] = 'ERR_YOUREBANNEDCREEP',
  ['471'] = 'ERR_CHANNELISFULL',
  ['472'] = 'ERR_UNKNOWNMODE',
  ['473'] = 'ERR_INVITEONLYCHAN',
  ['474'] = 'ERR_BANNEDFROMCHAN',
  ['475'] = 'ERR_BADCHANNELKEY',
  ['481'] = 'ERR_NOPRIVILEGES',
  ['482'] = 'ERR_CHANOPRIVSNEEDED',
  ['483'] = 'ERR_CANTKILLSERVER',
  ['491'] = 'ERR_NOOPERHOST',
  ['501'] = 'ERR_UMODEUNKNOWNFLAG',
  ['502'] = 'ERR_USERSDONTMATCH',
  ['670'] = 'RPL_STARTTLS',
  ['691'] = 'ERR_STARTTLS',
  ['723'] = 'ERR_NOPRIVS',
  ['900'] = 'RPL_LOGGEDIN',
  ['901'] = 'RPL_LOGGEDOUT',
  ['902'] = 'ERR_NICKLOCKED',
  ['903'] = 'RPL_SASLSUCCESS',
  ['904'] = 'ERR_SASLFAIL',
  ['905'] = 'ERR_SASLTOOLONG',
  ['906'] = 'ERR_SASLABORTED',
  ['907'] = 'ERR_SASLALREADY',
  ['908'] = 'RPL_SASLMECHS',

}

-- var to store partial commands
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
        local cmd = responce.cmd
        if pcall(tonumber(cmd)) and numerics[cmd] then
          cmd = numerics[cmd]
        end
        if handlers[cmd] then
          handlers[cmd](client, responce)
        else
          handlers.default_handler(client, responce)
        end
      end
    end
  end
end

-- Gets called for all events
function handlers.default_handler(client, responce)
  require'nirc.display'.show(responce)
end

-- Handle pings
function handlers.PING(client, responce)
  client:send_raw('PONG :%s', responce.args[#responce.args])
end

-- Handle Nick name already in use
function handlers.ERR_NICKNAMEINUSE(client, _)
  client.config.nick = '_'..client.config.nick
  client:send_cmd("nick", client.config.nick)
  if not client.handshake_done then
    client:send_cmd('user', client.config.username, client.config.username)
  end
end

-- Handlers wellcome
function handlers.RPL_WELCOME(client, _)
  client.handshake_done = true
end

function handlers.ERROR(client, responce)
  if responce.args[#responce.args]:upper():find('QUIT') then
    client:disconnect()
    require'nirc.display'.close_view()
  end
end

-- Makes initial contact with the server
function handlers.post_connect(client)
  if client.config.password then
    client:send_cmd('pass', client.config.password)
  end
  client:send_cmd('nick', client.config.nick)
  client:send_cmd('user', client.config.username, client.config.username)
end

return handlers
