local utils = {}

local api = vim.api

function utils.get_prompt()
  local nirc_data = require'nirc.data'
  return string.format('%s > ', nirc_data.clients[nirc_data.active_client].config.nick)
end

function utils.str_split_len(str, len)
  local length = #str
  local splited_str = {}
  local begin = 1
  while (begin + len) < length do
    local word_end = begin + len
    while word_end > begin do
      if str:byte(word_end) == string.byte(' ') or
        str:byte(word_end) == string.byte('\n') or
        str:byte(word_end) == string.byte('\t') then
        break
      end
      word_end = word_end - 1
    end
    table.insert(splited_str, str:sub(begin, (word_end ~= begin) and word_end or begin + len))
    begin = (word_end ~= begin) and word_end + 1 or begin + len
  end
  table.insert(splited_str, str:sub(begin, length))
  return splited_str
end

function utils.error_msg(msg)
  vim.api.nvim_echo({{msg, 'ErrorMsg'}}, true, {})
end

function utils.warn_msg(msg)
  vim.api.nvim_echo({{msg, 'WaringMsg'}}, true, {})
end

function utils.statusline()
  local active_hl = '%#visual#'
  local inactive_hl = '%#StatusLine#'
  local ok, nirc_data = pcall(require, 'nirc.data')
  if not ok then return '' end
  local active_channel = vim.b.NIRC_channel_name
  local status = {}
  for _, channel in pairs(nirc_data.channels) do
    local chan_name = ' ' .. channel.name .. ' '
    if channel.name == active_channel then
      table.insert(status, active_hl .. chan_name ..inactive_hl)
    else
      table.insert(status, chan_name)
    end
  end
  return inactive_hl .. table.concat(status, '|')
end

function utils.buf_get_var(buf_id, key)
  local ok, result = pcall(api.nvim_buf_get_var, buf_id, key)
  if not ok then return nil end
  return result
end

function utils.force_quit()
  local ok, nirc_data = pcall(require, 'nirc.data')
  if not ok then return end
  if not nirc_data.active_client or nirc_data.active_client == '' then return end
  local client = nirc_data.clients[nirc_data.active_client]
  if not client then return end
  require'nirc.display'.close_view()
  client:disconnect()
end

function utils.get_password(conf_name)
  local pass = os.getenv("NIRC_"..conf_name)
  if pass then return pass end
  pass = vim.fn.inputsecret('Password: ' )
  vim.cmd [[echo ""]]
  return pass ~= "" and pass or nil
end

return utils
