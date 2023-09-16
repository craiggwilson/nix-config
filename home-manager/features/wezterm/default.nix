{ pkgs, ... }: {
    programs.wezterm = {
        enable = true;
        enableBashIntegration = true;

        extraConfig = ''
            local wezterm = require 'wezterm'
            local mux = wezterm.mux
            local act = wezterm.action

            local hyperlink_rules = wezterm.default_hyperlink_rules()

            table.insert(hyperlink_rules, {
                regex = [[(MHOUSE-\d+)]],
                format = 'https://jira.mongodb.org/browse/$1',
                highlight = 1
            })

            table.insert(hyperlink_rules, {
                regex = [[mhouse(\d+)]],
                format = 'https://jira.mongodb.org/browse/MHOUSE-$1'
            })

            table.insert(hyperlink_rules, {
                regex = [[(\S+):(\d+)(:(\d+))?]],
                format = 'editor:$1?line=$2&col=$3'
            })

            wezterm.on('open-uri', function(window, pane, uri)
                local start, match_end = uri:find 'editor:'
                if start == 1 then
                    local qstart, qend = uri:find '?'
                    local path = uri:sub(match_end + 1, qstart-1)
                    local line = "0"
                    local col = "0"
                    for key, value in uri:sub(qstart):gmatch "(%w+)=(%d+)" do
                        if (key == "line") then 
                            line = value
                        elseif (key == "col" and value ~= "") then
                            col = value
                        end
                    end

                    window:perform_action(
                        wezterm.action.SpawnCommandInNewWindow {
                            args = { 'flatpak', 'run', 'com.jetbrains.GoLand', "--line", line, "--column", col, path },
                        },
                        pane
                    )
                    return false
                end
            end)

            return {
                adjust_window_size_when_changing_font_size = false,
                color_scheme = "Catppuccin Mocha",
                disable_default_key_bindings = true,
                font_size = 14,
                hide_tab_bar_if_only_one_tab = true,
                hyperlink_rules = hyperlink_rules,
                window_background_opacity = .85,
                keys = {
                    {
                        key = 'a',
                        mods = 'SHIFT|CTRL',
                        action = wezterm.action.QuickSelectArgs {
                        label = 'open url',
                        patterns = {
                            'https?://\\S+',
                        },
                        action = wezterm.action_callback(function(window, pane)
                            local url = window:get_selection_text_for_pane(pane)
                            wezterm.open_with(url, 'goland')
                        end),
                        },
                    },

                    -- TERMINAL
                    { key = '0', mods = 'SHIFT|CTRL', action = act.ResetFontSize },
                    { key = '=', mods = 'SHIFT|CTRL', action = act.IncreaseFontSize },
                    { key = '-', mods = 'SHIFT|CTRL', action = act.DecreaseFontSize },
                    { key = 'N', mods = 'SHIFT|CTRL', action = act.SpawnWindow },
                    { key = 'P', mods = 'SHIFT|CTRL', action = act.ActivateCommandPalette },
                        
                    -- CONTENT
                    { key = 'c', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
                        local has_selection = (
                        window:get_selection_text_for_pane(pane) ~= ""
                        )
                        if (has_selection) then
                            window:perform_action(
                                wezterm.action({
                                    CopyTo="ClipboardAndPrimarySelection"
                                }),
                                pane
                            )
                        else
                            window:perform_action(
                                wezterm.action({
                                    SendKey = { key = "c", mods = "CTRL"}
                                }),
                                pane
                            )
                        end
                    end)},
                    { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },

                    -- TABS	
                    { key = 'T', mods = 'SHIFT|CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
                    { key = 'PageUp', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(-1) },
                    { key = 'PageDown', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(1) },
                    
                    -- PANES
                    { key = '_', mods = 'SHIFT|CTRL', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
                    { key = '|', mods = 'SHIFT|CTRL', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
                    { key = 'LeftArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Left' },
                    { key = 'RightArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Right' },
                    { key = 'UpArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Up' },
                    { key = 'DownArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Down' },
                    { key = 'Enter', mods = 'SHIFT|CTRL', action = act.TogglePaneZoomState },
                    { key = 'W', mods = 'SHIFT|CTRL', action = act.CloseCurrentPane{ confirm = false } },
                
                },
            }
        '';
    };
}
