local utils = {}

function utils.get_prompt(client)
  return string.format('( %s ) > ', client.config.nick)
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
return utils
