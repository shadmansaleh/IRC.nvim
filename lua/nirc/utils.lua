local utils = {}

function utils.get_prompt()
  local nirc_data = require'nirc.data'
  return string.format('<%s> ', nirc_data.clients[nirc_data.active_client].config.nick)
end

function utils.remove_prompt(line, prompt)
  local match_until = 1
  while match_until <= #prompt do
    if prompt:byte(match_until) ~= line:byte(match_until) then
      break
    end
    match_until = match_until + 1
  end
  return line:sub(match_until)
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
  local active_channel = nirc_data.active_channel
  local status = {}
  for _, chan_name in pairs(nirc_data.channels.list) do
    if chan_name == active_channel then
      table.insert(status, active_hl .. chan_name..inactive_hl)
    else
      table.insert(status, chan_name)
    end
  end
  return inactive_hl .. table.concat(status, ' | ')
end


return utils
