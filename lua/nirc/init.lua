local display = require'nirc.display'
local irc = require'nirc.irc'
local utils = require'nirc.utils'

local nirc = {}
local configs = {}

package.loaded['nirc.data'] = {
  active_client = '',
  active_channel = '',
  clients = {},
  display = {},
  channels = {
    list = {},
    msgs = {},
  },
}

local nirc_data = require'nirc.data'

function nirc.connect(conf_name)
  if configs[conf_name] then
    nirc_data.clients[conf_name] = irc:new(configs[conf_name])
    nirc_data.active_client = conf_name
    display.open_view()
    local ok, reason = pcall(nirc_data.clients[conf_name].connect, nirc_data.clients[conf_name])
    if not ok then
      display.close_view()
      utils.error_msg('Error failed to connect to '..conf_name..' : '..reason)
    end
  else
    utils.error_msg('Error server '..conf_name..' not configured')
  end
end

function nirc.setup(conf)
  configs = conf
  vim.cmd([[
    command! NIRCChannelNext lua require('nirc.display').next_channel()
    command! NIRCChannelPrev lua require('nirc.display').prev_channel()
    command! -nargs=1 -complete=customlist,v:lua.require'nirc.display'.channels NIRCChannelSwitch lua require('nirc.display').switch_channel(<q-args>)
    command! -nargs=1 NIRCConnect lua require('nirc').connect(<q-args>)
  ]])
end

return nirc
