local display = require'irc.display'
local irc = require'irc.irc'
local utils = require'irc.utils'

local M = {}

package.loaded['irc.data'] = {
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

local irc_data = require'irc.data'

function M.connect(conf_name)
  if irc_data.configs.servers[conf_name] then
    local conf = vim.deepcopy(irc_data.configs.servers[conf_name])
    if not conf.password then conf.password = utils.get_password(conf_name) end
    irc_data.clients[conf_name] = irc:new(conf)
    irc_data.active_client = conf_name
    display.open_view()
    local ok, reason = pcall(irc_data.clients[conf_name].connect, irc_data.clients[conf_name])
    if not ok then
      display.close_view()
      utils.error_msg('Error failed to connect to '..conf_name..' : '..reason)
    end
  else
    utils.error_msg('Error server '..conf_name..' not configured')
  end
end

function M.setup(conf)
  irc_data.configs = conf
  vim.cmd [[
    augroup IRC
    autocmd!
    augroup END
    command! IRCChannelNext lua require('irc.display').next_channel()
    command! IRCChannelPrev lua require('irc.display').prev_channel()
    command! -nargs=1 -complete=customlist,v:lua.require'irc.display'.channels IRCChannelSwitch lua require('irc.display').switch_channel(<q-args>)
    command! -nargs=1 IRCConnect lua require('irc').connect(<q-args>)
    autocmd IRC ExitPre * lua require'irc.utils'.force_quit()
  ]]
  if irc_data.configs.statusline ~= false then
  vim.cmd [[
    autocmd FileType irc autocmd IRC BufEnter <buffer> setlocal statusline=%!v:lua.require'irc.utils'.statusline()
    autocmd FileType irc autocmd IRC BufLeave <buffer> setlocal statusline=%!v:lua.require'irc.utils'.statusline()
    ]]
  end
end

return M
