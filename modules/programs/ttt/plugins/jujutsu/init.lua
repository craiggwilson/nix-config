local ttt = require("ttt")
local sys = require("ttt.system")

local state = {
  commits = {},
  commit_files = {},
  error = nil,
  files = {},
  loading = false,
  root = nil,
}

local panel_ref = nil

local function split_lines(text)
  local result = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(result, line)
  end
  if #result > 0 and result[#result] == "" then
    table.remove(result)
  end
  return result
end

local function parse_summary(text, prefix)
  local result = {}
  for _, line in ipairs(split_lines(text)) do
    local status, path = line:match("^(%S+)%s+(.+)$")
    if status and path then
      table.insert(result, {
        badge = status,
        id = prefix .. path,
        label = path,
        status = status,
      })
    end
  end
  return result
end

local function status_style(status)
  local styles = {
    A = "success",
    D = "danger",
    M = "warning",
    R = "info",
  }
  return styles[status] or "muted"
end

local function parse_commits(text)
  local result = {}
  for _, line in ipairs(split_lines(text)) do
    local revision, commit, author, date, description = line:match("^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t(.*)$")
    if revision then
      table.insert(result, {
        commit = commit,
        date = date,
        description = description ~= "" and description or "(no description set)",
        revision = revision,
        author = author,
      })
    end
  end
  return result
end

local function redraw()
  if panel_ref then
    panel_ref:redraw()
  end
end

local function open_diff(revision, path, title)
  local args = { "diff" }
  if revision then
    table.insert(args, "-r")
    table.insert(args, revision)
  end
  table.insert(args, "--git")
  table.insert(args, "--")
  table.insert(args, path)

  sys.exec_async("jj", args, function(result)
    if result.exit_code ~= 0 then
      ttt.notify("Could not load diff for " .. path, "error")
      return
    end
    if result.stdout == "" then
      ttt.notify("No diff for " .. path, "warn")
      return
    end
    local id = (revision or "working-copy") .. ":" .. path
    ttt.open_changes({
      description = revision and ("Jujutsu change " .. revision) or "Jujutsu working copy",
      diff = result.stdout,
      id = id,
      title = title,
    })
  end)
end

local function select_node(node)
  local revision, path = node.id:match("^commit:([^|]+)|(.+)$")
  if revision and path then
    open_diff(revision, path, path .. " @ " .. revision)
    return
  end

  path = node.id:match("^working:(.+)$")
  if path then
    open_diff(nil, path, path .. " (working copy)")
  end
end

local function load_commit_files(node)
  local revision = node.id:match("^commit:([^|]+)$")
  if not revision or state.commit_files[revision] then
    return
  end

  sys.exec_async("jj", { "diff", "-r", revision, "--summary" }, function(result)
    if result.exit_code == 0 then
      state.commit_files[revision] = parse_summary(result.stdout, "commit:" .. revision .. "|")
    else
      state.commit_files[revision] = {
        {
          id = "commit:" .. revision .. "|error",
          label = result.stderr,
          muted = true,
        },
      }
    end
    redraw()
  end)
end

local function commit_nodes()
  local result = {}
  for _, commit in ipairs(state.commits) do
    local id = "commit:" .. commit.revision
    table.insert(result, {
      children = state.commit_files[commit.revision],
      expanded = state.commit_files[commit.revision] ~= nil,
      expandable = true,
      id = id,
      label = commit.revision .. " " .. commit.date .. " " .. commit.description,
      muted = commit.revision == state.commits[1].revision,
    })
  end
  return result
end

local function refresh()
  if state.loading then
    return
  end

  state.commits = {}
  state.commit_files = {}
  state.error = nil
  state.files = {}
  state.loading = true
  state.root = nil
  redraw()

  sys.exec_async("jj", { "root" }, function(root_result)
    if root_result.exit_code ~= 0 then
      state.error = "Not a Jujutsu repository"
      state.loading = false
      redraw()
      return
    end

    state.root = root_result.stdout:gsub("%s+$", "")
    sys.exec_async("jj", { "diff", "--summary" }, function(diff_result)
      if diff_result.exit_code == 0 then
        state.files = parse_summary(diff_result.stdout, "working:")
      end
      sys.exec_async("jj", {
        "log",
        "-r",
        "present(@) | ancestors(@, 8)",
        "--no-graph",
        "-n",
        "8",
        "-T",
        'change_id.shortest(8) ++ "\\t" ++ commit_id.short(8) ++ "\\t" ++ author.email() ++ "\\t" ++ committer.timestamp().format("%Y-%m-%d") ++ "\\t" ++ description.first_line() ++ "\\n"',
      }, function(log_result)
        if log_result.exit_code == 0 then
          state.commits = parse_commits(log_result.stdout)
        end
        state.loading = false
        redraw()
      end)
    end)
  end)
end

ttt.register({
  sidebar = {
    title = "Jujutsu",
    actions = {
      { label = "Refresh", command = "refresh" },
    },
    on_action = function(command)
      if command == "refresh" then
        refresh()
      end
    end,
    render = function(panel)
      panel_ref = panel

      if state.loading then
        panel:label({ text = "Loading...", style = "muted", padding_left = 1 })
        return
      end

      if state.error then
        panel:label({ text = state.error, style = "muted", padding_left = 1 })
        return
      end

      if not state.root then
        refresh()
        panel:label({ text = "Loading...", style = "muted", padding_left = 1 })
        return
      end

      panel:label({ text = state.root, style = "muted", padding_left = 1 })
      panel:label({ text = "Changes (" .. #state.files .. ")", style = "bold", padding_left = 1 })
      if #state.files > 0 then
        local rows = {}
        local row_styles = {}
        for _, file in ipairs(state.files) do
          table.insert(rows, { file.status, file.label })
          table.insert(row_styles, status_style(file.status))
        end
        panel:table({
          columns = {
            { label = "", width = 3 },
            { label = "File", min_width = 12 },
          },
          on_select = function(row)
            select_node(state.files[row])
          end,
          row_styles = row_styles,
          rows = rows,
        })
      else
        panel:label({ text = "Working copy clean", style = "muted", padding_left = 2 })
      end

      panel:label({ text = "Commit History", style = "bold", padding_left = 1, margin_top = 1 })
      panel:tree({
        badge_right = true,
        indent = 2,
        items = commit_nodes(),
        on_expand = load_commit_files,
        on_select = select_node,
      })
    end,
  },
})
