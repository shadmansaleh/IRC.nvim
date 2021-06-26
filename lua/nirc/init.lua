local display = require'nirc.display'
local irc = require'nirc.irc'
local utils = require'nirc.utils'

local nirc = {}

package.loaded['nirc.data'] = {
  active_client = '',
  configs = {
    servers = {},
  },
  clients = {},
  display = {
    server_list = {}
  },
  channels = {},
  channel_list = {} -- Chan_name & buf_nr -> channel_id into channels table
}

local nirc_data = require'nirc.data'

function nirc.connect(conf_name)
  if nirc_data.configs.servers[conf_name] then
    local conf = vim.deepcopy(nirc_data.configs.servers[conf_name])
    if not conf.password then conf.password = utils.get_password(conf_name) end
    nirc_data.clients[conf_name] = irc:new(conf)
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
  nirc_data.configs = conf
  vim.cmd [[
    augroup NIRC
    autocmd!
    augroup END
    command! NIRCChannelNext lua require('nirc.display').next_channel()
    command! NIRCChannelPrev lua require('nirc.display').prev_channel()
    command! -nargs=1 -complete=customlist,v:lua.require'nirc.display'.channels NIRCChannelSwitch lua require('nirc.display').switch_channel(<q-args>)
    command! -nargs=1 NIRCConnect lua require('nirc').connect(<q-args>)
    autocmd NIRC ExitPre * lua require'nirc.utils'.force_quit()
  ]]
  if nirc_data.configs.statusline ~= false then
  vim.cmd [[
    autocmd FileType nirc autocmd NIRC BufEnter <buffer> setlocal statusline=%!v:lua.require'nirc.utils'.statusline()
    autocmd FileType nirc autocmd NIRC BufLeave <buffer> setlocal statusline=%!v:lua.require'nirc.utils'.statusline()
    ]]
  end
end

return nirc
