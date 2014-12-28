local url_count = 0
local tries = 0


read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end


wget.callbacks.httploop_result = function(url, err, http_stat)
  local status_code = http_stat["statcode"]

  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()
  
  if status_code == 0 or status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 5")

    tries = tries + 1

    if tries >= 20 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  local sleep_time = 0.1 * (math.random(750, 1250) / 1000.0)

  if string.match(url["host"], "media%.memories%.nokia%.com")then
    -- We should be able to go fast on images since that's what a web browser does
    sleep_time = 0
  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}

  if string.match(url, "//memories%.nokia%.com/") then
    local content = read_file(file)
      
      for extra_url in string.gmatch(content, 'poster="(https?://media.memories.nokia.com/media/[^"]+%.jpg)"') do
        table.insert(urls, { url=extra_url })
      end
      for extra_url in string.gmatch(content, 'source src="http://media.memories.nokia.com/media/[^"]+%.mp4"') do
        table.insert(urls, { url=extra_url })
      end
    end

  return urls
end