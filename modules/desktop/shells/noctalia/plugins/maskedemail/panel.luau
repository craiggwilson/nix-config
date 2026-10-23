local emails = {}
local desc = ""

local function trim(value)
  return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function column(line, start, finish)
  return trim(line:sub(start, finish - 1))
end

local function parseList(output)
  local header = output:match("[^\r\n]+")
  if not header then
    return {}
  end

  local starts = {
    1,
    header:find("For Domain", 1, true),
    header:find("Description", 1, true),
    header:find("State", 1, true),
  }
  if not starts[2] or not starts[3] or not starts[4] then
    return {}
  end

  local result = {}
  local lineNumber = 0
  for line in output:gmatch("[^\r\n]+") do
    lineNumber = lineNumber + 1
    if lineNumber > 1 then
      local email = column(line, starts[1], starts[2])
      if email ~= "" then
        table.insert(result, {
          email = email,
          domain = column(line, starts[2], starts[3]),
          desc = column(line, starts[3], starts[4]),
          state = trim(line:sub(starts[4])),
        })
      end
    end
  end
  return result
end

local function matchesFilter(email)
  local filter = desc:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if filter == "" then
    return true
  end

  return email.email:lower():find(filter, 1, true)
    or email.domain:lower():find(filter, 1, true)
    or email.desc:lower():find(filter, 1, true)
    or email.state:lower():find(filter, 1, true)
end

local function refresh()
  noctalia.runAsync({ "maskedemail-cli", "list" }, function(result)
    if result.exitCode == 0 then
      emails = parseList(result.stdout)
      render()
    else
      noctalia.notifyError("Failed to list masked emails", result.stderr)
    end
  end)
end

function render()
  local items = {
    ui.row({ gap = 8, align = "center" }, {
      ui.label({ text = "Masked Emails", fontSize = 16, fontWeight = "bold", flexGrow = 1 }),
      ui.button({ glyph = "refresh", onClick = "onRefresh" }),
      ui.button({ glyph = "plus", variant = "primary", onClick = "onCreate" }),
    }),
    ui.separator({}),
    ui.input({ value = desc, placeholder = "Description", flexGrow = 1, onChange = function(value) desc = value; render() end }),
    ui.separator({}),
  }

  local visibleEmails = {}
  for _, email in ipairs(emails) do
    if matchesFilter(email) then
      table.insert(visibleEmails, email)
    end
  end

  if #visibleEmails == 0 then
    table.insert(items, ui.label({
      text = #emails == 0 and "No masked emails" or "No matching masked emails",
      color = "on_surface_variant",
    }))
  else
    local list = {}
    for _, email in ipairs(visibleEmails) do
      table.insert(list, ui.row({ gap = 8, align = "center", padding = 4 }, {
        ui.column({ flexGrow = 1 }, {
          ui.label({ text = email.email, fontWeight = "medium" }),
          ui.label({ text = email.desc, fontSize = 12, color = "on_surface_variant" }),
          ui.label({ text = email.domain, fontSize = 12, color = "on_surface_variant" }),
        }),
        ui.label({ text = email.state, fontSize = 12 }),
        ui.button({ glyph = "copy", onClick = function() noctalia.copyToClipboard(email.email, "text/plain"); noctalia.notify("Copied", email.email) end }),
        email.state == "enabled"
          and ui.button({ glyph = "player-pause", onClick = function() onDisable(email.email) end })
          or ui.button({ glyph = "player-play", onClick = function() onEnable(email.email) end }),
        ui.button({ glyph = "trash", onClick = function() onDelete(email.email) end }),
      }))
      table.insert(list, ui.separator({}))
    end
    table.insert(items, ui.scroll({ height = 380 }, list))
  end

  panel.render(ui.column({ gap = 12, padding = 16 }, items))
end

function onOpen()
  render()
  refresh()
end

function onRefresh()
  refresh()
end

function onCreate()
  local args = { "maskedemail-cli", "create" }
  if desc ~= "" then
    table.insert(args, "-desc")
    table.insert(args, desc)
  end
  noctalia.runAsync(args, function(result)
    if result.exitCode == 0 then
      local email = trim(result.stdout)
      noctalia.copyToClipboard(email, "text/plain")
      noctalia.notify("Masked email created", email)
      desc = ""
      refresh()
    else
      noctalia.notifyError("Failed to create masked email", result.stderr)
    end
  end)
end

local function runAction(action, email)
  noctalia.runAsync({ "maskedemail-cli", action, email }, function(result)
    if result.exitCode == 0 then
      refresh()
    else
      noctalia.notifyError("Masked email action failed", result.stderr)
    end
  end)
end

function onEnable(email)
  runAction("enable", email)
end

function onDisable(email)
  runAction("disable", email)
end

function onDelete(email)
  runAction("delete", email)
end
