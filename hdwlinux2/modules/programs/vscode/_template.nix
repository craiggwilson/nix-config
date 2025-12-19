colors:
let
  c = colors.withHashtag or {
    base00 = "#1e1e2e";
    base01 = "#181825";
    base02 = "#313244";
    base03 = "#45475a";
    base04 = "#585b70";
    base05 = "#cdd6f4";
    base06 = "#f5e0dc";
    base07 = "#b4befe";
    base08 = "#f38ba8";
    base09 = "#fab387";
    base0A = "#f9e2af";
    base0B = "#a6e3a1";
    base0C = "#94e2d5";
    base0D = "#89b4fa";
    base0E = "#cba6f7";
    base0F = "#f2cdcd";
  };
in
with c; ''
  {
      "$schema": "vscode://schemas/color-theme",
      "name": "hdwlinux",
      "type": "dark",
      "colors": {
          "foreground": "${base05}",
          "disabledForeground": "${base04}",
          "widget.shadow": "${base00}",
          "selection.background": "${base0D}",
          "descriptionForeground": "${base03}",
          "errorForeground": "${base08}",
          "icon.foreground": "${base04}",
          "textBlockQuote.background": "${base01}",
          "textBlockQuote.border": "${base0D}",
          "textCodeBlock.background": "${base00}",
          "textLink.activeForeground": "${base0C}",
          "textLink.foreground": "${base0D}",
          "textPreformat.foreground": "${base0D}",
          "textSeparator.foreground": "${base05}",
          "toolbar.hoverBackground": "${base02}",
          "toolbar.activeBackground": "${base03}",
          "button.background": "${base0D}",
          "button.foreground": "${base07}",
          "button.hoverBackground": "${base04}",
          "button.secondaryForeground": "${base07}",
          "button.secondaryBackground": "${base0E}",
          "button.secondaryHoverBackground": "${base04}",
          "checkbox.background": "${base00}",
          "checkbox.foreground": "${base05}",
          "dropdown.background": "${base00}",
          "dropdown.listBackground": "${base00}",
          "dropdown.foreground": "${base05}",
          "input.background": "${base00}",
          "input.foreground": "${base05}",
          "input.placeholderForeground": "${base03}",
          "inputOption.activeBackground": "${base02}",
          "inputOption.activeBorder": "${base09}",
          "inputOption.activeForeground": "${base05}",
          "inputValidation.errorBackground": "${base08}",
          "inputValidation.errorForeground": "${base05}",
          "inputValidation.errorBorder": "${base08}",
          "inputValidation.infoBackground": "${base0D}",
          "inputValidation.infoForeground": "${base05}",
          "inputValidation.infoBorder": "${base0D}",
          "inputValidation.warningBackground": "${base0A}",
          "inputValidation.warningForeground": "${base05}",
          "inputValidation.warningBorder": "${base0A}",
          "scrollbar.shadow": "${base01}",
          "scrollbarSlider.activeBackground": "${base04}",
          "scrollbarSlider.background": "${base02}",
          "scrollbarSlider.hoverBackground": "${base03}",
          "badge.background": "${base00}",
          "badge.foreground": "${base05}",
          "progressBar.background": "${base03}",
          "list.activeSelectionBackground": "${base02}",
          "list.activeSelectionForeground": "${base05}",
          "list.dropBackground": "${base07}",
          "list.focusBackground": "${base02}",
          "list.focusForeground": "${base05}",
          "list.highlightForeground": "${base07}",
          "list.hoverBackground": "${base02}",
          "list.hoverForeground": "${base05}",
          "list.inactiveSelectionBackground": "${base02}",
          "list.inactiveSelectionForeground": "${base05}",
          "list.inactiveFocusBackground": "${base02}",
          "list.invalidItemForeground": "${base08}",
          "list.errorForeground": "${base08}",
          "list.warningForeground": "${base0A}",
          "listFilterWidget.background": "${base00}",
          "listFilterWidget.noMatchesOutline": "${base08}",
          "list.filterMatchBackground": "${base02}",
          "tree.indentGuidesStroke": "${base05}",
          "activityBar.background": "${base01}",
          "activityBar.dropBackground": "${base07}",
          "activityBar.foreground": "${base05}",
          "activityBar.inactiveForeground": "${base03}",
          "activityBarBadge.background": "${base0D}",
          "activityBarBadge.foreground": "${base07}",
          "activityBar.activeBackground": "${base02}",
          "sideBar.background": "${base01}",
          "sideBar.foreground": "${base05}",
          "sideBar.dropBackground": "${base02}",
          "sideBarTitle.foreground": "${base05}",
          "sideBarSectionHeader.background": "${base01}",
          "sideBarSectionHeader.foreground": "${base05}",
          "minimap.findMatchHighlight": "${base0A}",
          "minimap.selectionHighlight": "${base02}",
          "minimap.errorHighlight": "${base08}",
          "minimap.warningHighlight": "${base0A}",
          "minimap.background": "${base00}",
          "minimap.selectionOccurrenceHighlight": "${base03}",
          "minimapGutter.addedBackground": "${base0B}",
          "minimapGutter.modifiedBackground": "${base0E}",
          "minimapGutter.deletedBackground": "${base08}",
          "editorGroup.background": "${base00}",
          "editorGroup.dropBackground": "${base02}",
          "editorGroupHeader.noTabsBackground": "${base01}",
          "editorGroupHeader.tabsBackground": "${base01}",
          "editorGroup.emptyBackground": "${base00}",
          "editorGroup.dropIntoPromptForeground": "${base06}",
          "editorGroup.dropIntoPromptBackground": "${base00}",
          "tab.activeBackground": "${base02}",
          "tab.unfocusedActiveBackground": "${base02}",
          "tab.activeForeground": "${base05}",
          "tab.inactiveBackground": "${base01}",
          "tab.inactiveForeground": "${base05}",
          "tab.unfocusedActiveForeground": "${base04}",
          "tab.unfocusedInactiveForeground": "${base04}",
          "tab.hoverBackground": "${base02}",
          "tab.unfocusedHoverBackground": "${base02}",
          "tab.activeModifiedBorder": "${base0D}",
          "tab.inactiveModifiedBorder": "${base0D}",
          "tab.unfocusedActiveModifiedBorder": "${base0D}",
          "tab.unfocusedInactiveModifiedBorder": "${base0D}",
          "editorPane.background": "${base00}",
          "editor.background": "${base00}",
          "editor.foreground": "${base05}",
          "editorLineNumber.foreground": "${base03}",
          "editorLineNumber.activeForeground": "${base04}",
          "editorCursor.foreground": "${base05}",
          "editor.selectionBackground": "${base02}",
          "editor.inactiveSelectionBackground": "${base02}",
          "editor.selectionHighlightBackground": "${base01}",
          "editor.wordHighlightBackground": "${base02}",
          "editor.wordHighlightStrongBackground": "${base03}",
          "editor.findMatchBackground": "${base0A}",
          "editor.findMatchHighlightBackground": "${base09}",
          "editor.findRangeHighlightBackground": "${base01}",
          "searchEditor.findMatchBackground": "${base0A}",
          "editor.hoverHighlightBackground": "${base02}",
          "editor.lineHighlightBackground": "${base01}",
          "editorLink.activeForeground": "${base0D}",
          "editor.rangeHighlightBackground": "${base01}",
          "editorWhitespace.foreground": "${base03}",
          "editorIndentGuide.background": "${base03}",
          "editorIndentGuide.activeBackground": "${base04}",
          "editorInlayHint.background": "${base01}",
          "editorInlayHint.foreground": "${base05}",
          "editorInlayHint.typeBackground": "${base01}",
          "editorInlayHint.typeForeground": "${base05}",
          "editorInlayHint.parameterBackground": "${base01}",
          "editorInlayHint.parameterForeground": "${base05}",
          "editorRuler.foreground": "${base03}",
          "editorCodeLens.foreground": "${base02}",
          "editorLightBulb.foreground": "${base0A}",
          "editorLightBulbAutoFix.foreground": "${base0D}",
          "editorBracketMatch.background": "${base02}",
          "editorBracketHighlight.foreground1": "${base08}",
          "editorBracketHighlight.foreground2": "${base09}",
          "editorBracketHighlight.foreground3": "${base0A}",
          "editorBracketHighlight.foreground4": "${base0B}",
          "editorBracketHighlight.foreground5": "${base0D}",
          "editorBracketHighlight.foreground6": "${base0E}",
          "editorBracketHighlight.unexpectedBracket.foreground": "${base0F}",
          "editorOverviewRuler.findMatchForeground": "${base0A}",
          "editorOverviewRuler.rangeHighlightForeground": "${base03}",
          "editorOverviewRuler.selectionHighlightForeground": "${base02}",
          "editorOverviewRuler.wordHighlightForeground": "${base07}",
          "editorOverviewRuler.wordHighlightStrongForeground": "${base0D}",
          "editorOverviewRuler.modifiedForeground": "${base0E}",
          "editorOverviewRuler.addedForeground": "${base0B}",
          "editorOverviewRuler.deletedForeground": "${base08}",
          "editorOverviewRuler.errorForeground": "${base08}",
          "editorOverviewRuler.warningForeground": "${base0A}",
          "editorOverviewRuler.infoForeground": "${base0C}",
          "editorOverviewRuler.bracketMatchForeground": "${base06}",
          "editorError.foreground": "${base08}",
          "editorWarning.foreground": "${base0A}",
          "editorInfo.foreground": "${base0C}",
          "editorHint.foreground": "${base0D}",
          "problemsErrorIcon.foreground": "${base08}",
          "problemsWarningIcon.foreground": "${base0A}",
          "problemsInfoIcon.foreground": "${base0C}",
          "editorGutter.background": "${base00}",
          "editorGutter.modifiedBackground": "${base0E}",
          "editorGutter.addedBackground": "${base0B}",
          "editorGutter.deletedBackground": "${base08}",
          "editorGutter.commentRangeForeground": "${base04}",
          "editorGutter.foldingControlForeground": "${base05}",
          "diffEditor.insertedTextBackground": "${base0B}20",
          "diffEditor.removedTextBackground": "${base08}20",
          "diffEditor.diagonalFill": "${base02}",
          "editorWidget.foreground": "${base05}",
          "editorWidget.background": "${base00}",
          "editorSuggestWidget.background": "${base01}",
          "editorSuggestWidget.foreground": "${base05}",
          "editorSuggestWidget.focusHighlightForeground": "${base07}",
          "editorSuggestWidget.highlightForeground": "${base0D}",
          "editorSuggestWidget.selectedBackground": "${base02}",
          "editorSuggestWidget.selectedForeground": "${base06}",
          "editorHoverWidget.foreground": "${base05}",
          "editorHoverWidget.background": "${base00}",
          "debugExceptionWidget.background": "${base01}",
          "editorMarkerNavigation.background": "${base01}",
          "editorMarkerNavigationError.background": "${base08}",
          "editorMarkerNavigationWarning.background": "${base0A}",
          "editorMarkerNavigationInfo.background": "${base0D}",
          "editorMarkerNavigationError.headerBackground": "${base08}20",
          "editorMarkerNavigationWarning.headerBackground": "${base0A}20",
          "editorMarkerNavigationInfo.headerBackground": "${base0C}20",
          "peekViewEditor.background": "${base01}",
          "peekViewEditorGutter.background": "${base01}",
          "peekViewEditor.matchHighlightBackground": "${base09}",
          "peekViewResult.background": "${base00}",
          "peekViewResult.fileForeground": "${base05}",
          "peekViewResult.lineForeground": "${base03}",
          "peekViewResult.matchHighlightBackground": "${base09}",
          "peekViewResult.selectionBackground": "${base02}",
          "peekViewResult.selectionForeground": "${base05}",
          "peekViewTitle.background": "${base02}",
          "peekViewTitleDescription.foreground": "${base03}",
          "peekViewTitleLabel.foreground": "${base05}",
          "merge.currentContentBackground": "${base0D}40",
          "merge.currentHeaderBackground": "${base0D}40",
          "merge.incomingContentBackground": "${base0B}60",
          "merge.incomingHeaderBackground": "${base0B}60",
          "editorOverviewRuler.currentContentForeground": "${base0D}",
          "editorOverviewRuler.incomingContentForeground": "${base0B}",
          "editorOverviewRuler.commonContentForeground": "${base0F}",
          "panel.background": "${base00}",
          "panel.dropBackground": "${base01}",
          "panel.dropBorder": "${base01}",
          "panelTitle.activeForeground": "${base05}",
          "panelTitle.inactiveForeground": "${base03}",
          "statusBar.background": "${base0D}",
          "statusBar.foreground": "${base07}",
          "statusBar.debuggingBackground": "${base09}",
          "statusBar.debuggingForeground": "${base07}",
          "statusBar.noFolderBackground": "${base0E}",
          "statusBar.noFolderForeground": "${base07}",
          "statusBarItem.activeBackground": "${base03}",
          "statusBarItem.hoverBackground": "${base02}",
          "statusBarItem.prominentForeground": "${base07}",
          "statusBarItem.prominentBackground": "${base0E}",
          "statusBarItem.prominentHoverBackground": "${base08}",
          "statusBarItem.remoteBackground": "${base0B}",
          "statusBarItem.remoteForeground": "${base07}",
          "statusBarItem.errorBackground": "${base08}",
          "statusBarItem.errorForeground": "${base07}",
          "statusBarItem.warningBackground": "${base0A}",
          "statusBarItem.warningForeground": "${base07}",
          "titleBar.activeBackground": "${base00}",
          "titleBar.activeForeground": "${base05}",
          "titleBar.inactiveBackground": "${base01}",
          "titleBar.inactiveForeground": "${base03}",
          "menubar.selectionForeground": "${base05}",
          "menubar.selectionBackground": "${base01}",
          "menu.foreground": "${base05}",
          "menu.background": "${base01}",
          "menu.selectionForeground": "${base05}",
          "menu.selectionBackground": "${base02}",
          "menu.separatorBackground": "${base07}",
          "commandCenter.foreground": "${base05}",
          "commandCenter.activeForeground": "${base07}",
          "commandCenter.background": "${base00}",
          "commandCenter.activeBackground": "${base01}",
          "notificationCenterHeader.foreground": "${base05}",
          "notificationCenterHeader.background": "${base01}",
          "notifications.foreground": "${base05}",
          "notifications.background": "${base02}",
          "notificationLink.foreground": "${base0D}",
          "notificationsErrorIcon.foreground": "${base08}",
          "notificationsWarningIcon.foreground": "${base0A}",
          "notificationsInfoIcon.foreground": "${base0D}",
          "notification.background": "${base02}",
          "notification.foreground": "${base05}",
          "notification.buttonBackground": "${base0D}",
          "notification.buttonHoverBackground": "${base02}",
          "notification.buttonForeground": "${base07}",
          "notification.infoBackground": "${base0C}",
          "notification.infoForeground": "${base07}",
          "notification.warningBackground": "${base0A}",
          "notification.warningForeground": "${base07}",
          "notification.errorBackground": "${base08}",
          "notification.errorForeground": "${base07}",
          "banner.background": "${base02}",
          "banner.foreground": "${base05}",
          "banner.iconForeground": "${base0D}",
          "extensionButton.prominentBackground": "${base0B}",
          "extensionButton.prominentForeground": "${base07}",
          "extensionButton.prominentHoverBackground": "${base02}",
          "extensionBadge.remoteBackground": "${base09}",
          "extensionBadge.remoteForeground": "${base07}",
          "extensionIcon.starForeground": "${base0A}",
          "extensionIcon.verifiedForeground": "${base0D}",
          "extensionIcon.preReleaseForeground": "${base09}",
          "pickerGroup.foreground": "${base03}",
          "quickInput.background": "${base01}",
          "quickInput.foreground": "${base05}",
          "quickInputList.focusBackground": "${base03}",
          "quickInputList.focusForeground": "${base07}",
          "quickInputList.focusIconForeground": "${base07}",
          "keybindingLabel.background": "${base02}",
          "keybindingLabel.foreground": "${base05}",
          "keybindingTable.headerBackground": "${base02}",
          "keybindingTable.rowsBackground": "${base01}",
          "terminal.background": "${base00}",
          "terminal.foreground": "${base05}",
          "terminal.ansiBlack": "${base00}",
          "terminal.ansiRed": "${base08}",
          "terminal.ansiGreen": "${base0B}",
          "terminal.ansiYellow": "${base0A}",
          "terminal.ansiBlue": "${base0D}",
          "terminal.ansiMagenta": "${base0E}",
          "terminal.ansiCyan": "${base0C}",
          "terminal.ansiWhite": "${base05}",
          "terminal.ansiBrightBlack": "${base03}",
          "terminal.ansiBrightRed": "${base08}",
          "terminal.ansiBrightGreen": "${base0B}",
          "terminal.ansiBrightYellow": "${base0A}",
          "terminal.ansiBrightBlue": "${base0D}",
          "terminal.ansiBrightMagenta": "${base0E}",
          "terminal.ansiBrightCyan": "${base0C}",
          "terminal.ansiBrightWhite": "${base07}",
          "terminalCursor.foreground": "${base05}",
          "terminalOverviewRuler.cursorForeground": "#ff0000",
          "terminalOverviewRuler.findMatchForeground": "#ff0000",
          "debugToolBar.background": "${base01}",
          "debugView.stateLabelForeground": "${base07}",
          "debugView.stateLabelBackground": "${base0D}",
          "debugView.valueChangedHighlight": "${base0D}",
          "debugTokenExpression.name": "${base0E}",
          "debugTokenExpression.value": "${base05}",
          "debugTokenExpression.string": "${base0B}",
          "debugTokenExpression.boolean": "${base09}",
          "debugTokenExpression.number": "${base09}",
          "debugTokenExpression.error": "${base08}",
          "testing.iconFailed": "${base08}",
          "testing.iconErrored": "${base0F}",
          "testing.iconPassed": "${base0B}",
          "testing.runAction": "${base04}",
          "testing.iconQueued": "${base0A}",
          "testing.iconUnset": "${base04}",
          "testing.iconSkipped": "${base0E}",
          "testing.peekHeaderBackground": "${base01}",
          "testing.message.error.decorationForeground": "${base05}",
          "testing.message.error.lineBackground": "${base08}20",
          "testing.message.info.decorationForeground": "${base05}",
          "testing.message.info.lineBackground": "${base0D}20",
          "welcomePage.background": "${base00}",
          "welcomePage.buttonBackground": "${base01}",
          "welcomePage.buttonHoverBackground": "${base02}",
          "welcomePage.progress.background": "${base03}",
          "welcomePage.progress.foreground": "${base0D}",
          "welcomePage.tileBackground": "${base01}",
          "welcomePage.tileHoverBackground": "${base02}",
          "walkThrough.embeddedEditorBackground": "${base00}",
          "gitDecoration.addedResourceForeground": "${base0B}",
          "gitDecoration.modifiedResourceForeground": "${base0E}",
          "gitDecoration.deletedResourceForeground": "${base08}",
          "gitDecoration.renamedResourceForeground": "${base0C}",
          "gitDecoration.stageModifiedResourceForeground": "${base0E}",
          "gitDecoration.stageDeletedResourceForeground": "${base08}",
          "gitDecoration.untrackedResourceForeground": "${base09}",
          "gitDecoration.ignoredResourceForeground": "${base03}",
          "gitDecoration.conflictingResourceForeground": "${base0A}",
          "gitDecoration.submoduleResourceForeground": "${base0F}",
          "settings.headerForeground": "${base05}",
          "settings.modifiedItemIndicator": "${base0D}",
          "settings.modifiedItemForeground": "${base0B}",
          "settings.dropdownBackground": "${base01}",
          "settings.dropdownForeground": "${base05}",
          "settings.checkboxBackground": "${base01}",
          "settings.checkboxForeground": "${base05}",
          "settings.rowHoverBackground": "${base02}",
          "settings.textInputBackground": "${base01}",
          "settings.textInputForeground": "${base05}",
          "settings.numberInputBackground": "${base01}",
          "settings.numberInputForeground": "${base05}",
          "settings.focusedRowBackground": "${base02}",
          "settings.headerBorder": "${base05}",
          "settings.sashBorder": "${base05}",
          "breadcrumb.foreground": "${base05}",
          "breadcrumb.background": "${base01}",
          "breadcrumb.focusForeground": "${base06}",
          "breadcrumb.activeSelectionForeground": "${base07}",
          "breadcrumbPicker.background": "${base01}",
          "editor.snippetTabstopHighlightBackground": "${base02}",
          "editor.snippetFinalTabstopHighlightBackground": "${base03}",
          "symbolIcon.arrayForeground": "${base05}",
          "symbolIcon.booleanForeground": "${base09}",
          "symbolIcon.classForeground": "${base0A}",
          "symbolIcon.colorForeground": "${base05}",
          "symbolIcon.constantForeground": "${base09}",
          "symbolIcon.constructorForeground": "${base0D}",
          "symbolIcon.enumeratorForeground": "${base09}",
          "symbolIcon.enumeratorMemberForeground": "${base0D}",
          "symbolIcon.eventForeground": "${base0A}",
          "symbolIcon.fieldForeground": "${base08}",
          "symbolIcon.fileForeground": "${base05}",
          "symbolIcon.folderForeground": "${base05}",
          "symbolIcon.functionForeground": "${base0D}",
          "symbolIcon.interfaceForeground": "${base0D}",
          "symbolIcon.keyForeground": "${base05}",
          "symbolIcon.keywordForeground": "${base0E}",
          "symbolIcon.methodForeground": "${base0D}",
          "symbolIcon.moduleForeground": "${base05}",
          "symbolIcon.namespaceForeground": "${base05}",
          "symbolIcon.nullForeground": "${base0F}",
          "symbolIcon.numberForeground": "${base09}",
          "symbolIcon.objectForeground": "${base05}",
          "symbolIcon.operatorForeground": "${base05}",
          "symbolIcon.packageForeground": "${base05}",
          "symbolIcon.propertyForeground": "${base05}",
          "symbolIcon.referenceForeground": "${base05}",
          "symbolIcon.snippetForeground": "${base05}",
          "symbolIcon.stringForeground": "${base0B}",
          "symbolIcon.structForeground": "${base0A}",
          "symbolIcon.textForeground": "${base05}",
          "symbolIcon.typeParameterForeground": "${base05}",
          "symbolIcon.unitForeground": "${base05}",
          "symbolIcon.variableForeground": "${base08}",
          "debugIcon.breakpointForeground": "${base08}",
          "debugIcon.breakpointDisabledForeground": "${base04}",
          "debugIcon.breakpointUnverifiedForeground": "${base02}",
          "debugIcon.breakpointCurrentStackframeForeground": "${base0A}",
          "debugIcon.breakpointStackframeForeground": "${base0F}",
          "debugIcon.startForeground": "${base0B}",
          "debugIcon.pauseForeground": "${base0D}",
          "debugIcon.stopForeground": "${base08}",
          "debugIcon.disconnectForeground": "${base08}",
          "debugIcon.restartForeground": "${base0B}",
          "debugIcon.stepOverForeground": "${base0D}",
          "debugIcon.stepIntoForeground": "${base0C}",
          "debugIcon.stepOutForeground": "${base0E}",
          "debugIcon.continueForeground": "${base0B}",
          "debugIcon.stepBackForeground": "${base0F}",
          "debugConsole.infoForeground": "${base05}",
          "debugConsole.warningForeground": "${base0A}",
          "debugConsole.errorForeground": "${base08}",
          "debugConsole.sourceForeground": "${base05}",
          "debugConsoleInputIcon.foreground": "${base05}",
          "notebook.editorBackground": "${base00}",
          "notebook.cellBorderColor": "${base03}",
          "notebook.cellHoverBackground": "${base01}",
          "notebook.cellToolbarSeparator": "${base02}",
          "notebook.cellEditorBackground": "${base00}",
          "notebook.focusedCellBackground": "${base02}",
          "notebook.focusedCellBorder": "${base0D}",
          "notebook.focusedEditorBorder": "${base0D}",
          "notebook.inactiveFocusedCellBorder": "${base03}",
          "notebook.selectedCellBackground": "${base02}",
          "notebookStatusErrorIcon.foreground": "${base08}",
          "notebookStatusRunningIcon.foreground": "${base0C}",
          "notebookStatusSuccessIcon.foreground": "${base0B}",
          "charts.foreground": "${base05}",
          "charts.lines": "${base05}",
          "charts.red": "${base08}",
          "charts.blue": "${base0D}",
          "charts.yellow": "${base0A}",
          "charts.orange": "${base09}",
          "charts.green": "${base0B}",
          "charts.purple": "${base0E}",
          "ports.iconRunningProcessForeground": "${base09}"
      },
      "tokenColors": [
          {
              "name": "Comment",
              "scope": [
                  "comment",
                  "punctuation.definition.comment"
              ],
              "settings": {
                  "fontStyle": "italic",
                  "foreground": "${base03}"
              }
          },
          {
              "name": "Variables, Parameters",
              "scope": [
                  "variable",
                  "string constant.other.placeholder",
                  "entity.name.variable.parameter",
                  "entity.name.variable.local",
                  "variable.parameter"
              ],
              "settings": {
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Properties",
              "scope": [
                  "variable.other.object.property"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "Colors",
              "scope": [
                  "constant.other.color"
              ],
              "settings": {
                  "foreground": "${base0B}"
              }
          },
          {
              "name": "Invalid",
              "scope": [
                  "invalid",
                  "invalid.illegal"
              ],
              "settings": {
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Invalid - Deprecated",
              "scope": [
                  "invalid.deprecated"
              ],
              "settings": {
                  "foreground": "${base0F}"
              }
          },
          {
              "name": "Keyword, Storage",
              "scope": [
                  "keyword",
                  "keyword.other",
                  "keyword.other.using",
                  "keyword.other.namespace",
                  "keyword.other.class",
                  "keyword.other.new",
                  "keyword.other.event",
                  "keyword.other.this",
                  "keyword.other.await",
                  "keyword.other.var",
                  "keyword.other.package",
                  "keyword.other.import",
                  "variable.language.this",
                  "storage.type.ts",
                  "storage.modifier"
              ],
              "settings": {
                  "foreground": "${base0E}"
              }
          },
          {
              "name": "Keyword Control",
              "scope": [
                  "keyword.control",
                  "keyword.control.flow",
                  "keyword.control.from",
                  "keyword.control.import",
                  "keyword.control.as"
              ],
              "settings": {
                  "foreground": "${base0E}"
              }
          },
          {
              "name": "Types, Primitives",
              "scope": [
                  "keyword.type",
                  "storage.type.primitive"
              ],
              "settings": {
                  "foreground": "${base0C}"
              }
          },
          {
              "name": "Function",
              "scope": [
                  "storage.type.function"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "Operator, Misc",
              "scope": [
                  "constant.other.color",
                  "punctuation",
                  "punctuation.section.class.end",
                  "meta.tag",
                  "punctuation.definition.tag",
                  "punctuation.separator.inheritance.php",
                  "punctuation.definition.tag.html",
                  "punctuation.definition.tag.begin.html",
                  "punctuation.definition.tag.end.html",
                  "keyword.other.template",
                  "keyword.other.substitution"
              ],
              "settings": {
                  "foreground": "${base05}"
              }
          },
          {
              "name": "Embedded",
              "scope": [
                  "punctuation.section.embedded",
                  "variable.interpolation"
              ],
              "settings": {
                  "foreground": "${base0F}"
              }
          },
          {
              "name": "Tag",
              "scope": [
                  "entity.name.tag",
                  "meta.tag.sgml",
                  "markup.deleted.git_gutter"
              ],
              "settings": {
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Function, Special Method",
              "scope": [
                  "entity.name.function",
                  "meta.function-call",
                  "variable.function",
                  "support.function",
                  "keyword.other.special-method"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "Block Level Variables",
              "scope": [
                  "meta.block variable.other"
              ],
              "settings": {
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Other Variable, String Link",
              "scope": [
                  "support.other.variable",
                  "string.other.link"
              ],
              "settings": {
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Number, Constant, Function Argument, Tag Attribute, Embedded",
              "scope": [
                  "constant.numeric",
                  "constant.language",
                  "support.constant",
                  "constant.character",
                  "constant.escape",
                  "keyword.other.unit"
              ],
              "settings": {
                  "foreground": "${base09}"
              }
          },
          {
              "name": "String, Symbols, Inherited Class, Markup Heading",
              "scope": [
                  "string",
                  "constant.other.symbol",
                  "constant.other.key",
                  "entity.other.inherited-class",
                  "markup.heading",
                  "markup.inserted.git_gutter",
                  "meta.group.braces.curly constant.other.object.key.js string.unquoted.label.js"
              ],
              "settings": {
                  "fontStyle": "",
                  "foreground": "${base0B}"
              }
          },
          {
              "name": "Class, Support",
              "scope": [
                  "entity.name",
                  "support.type",
                  "support.class",
                  "support.other.namespace.use.php",
                  "meta.use.php",
                  "support.other.namespace.php",
                  "markup.changed.git_gutter",
                  "support.type.sys-types"
              ],
              "settings": {
                  "foreground": "${base0A}"
              }
          },
          {
              "name": "Storage Type, Import Class",
              "scope": [
                  "storage.type",
                  "storage.modifier.package",
                  "storage.modifier.import"
              ],
              "settings": {
                  "foreground": "${base0A}"
              }
          },
          {
              "name": "Fields",
              "scope": [
                  "entity.name.variable.field"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "Entity Types",
              "scope": [
                  "support.type"
              ],
              "settings": {
                  "foreground": "${base0C}"
              }
          },
          {
              "name": "CSS Class and Support",
              "scope": [
                  "source.css support.type.property-name",
                  "source.sass support.type.property-name",
                  "source.scss support.type.property-name",
                  "source.less support.type.property-name",
                  "source.stylus support.type.property-name",
                  "source.postcss support.type.property-name"
              ],
              "settings": {
                  "foreground": "${base0C}"
              }
          },
          {
              "name": "Sub-methods",
              "scope": [
                  "entity.name.module.js",
                  "variable.import.parameter.js",
                  "variable.other.class.js"
              ],
              "settings": {
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Language methods",
              "scope": [
                  "variable.language"
              ],
              "settings": {
                  "fontStyle": "italic",
                  "foreground": "${base08}"
              }
          },
          {
              "name": "entity.name.method.js",
              "scope": [
                  "entity.name.method.js"
              ],
              "settings": {
                  "fontStyle": "italic",
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "meta.method.js",
              "scope": [
                  "meta.class-method.js entity.name.function.js",
                  "variable.function.constructor"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "Attributes",
              "scope": [
                  "entity.other.attribute-name"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "HTML Attributes",
              "scope": [
                  "text.html.basic entity.other.attribute-name.html",
                  "text.html.basic entity.other.attribute-name"
              ],
              "settings": {
                  "fontStyle": "italic",
                  "foreground": "${base0A}"
              }
          },
          {
              "name": "CSS Classes",
              "scope": [
                  "entity.other.attribute-name.class"
              ],
              "settings": {
                  "foreground": "${base0A}"
              }
          },
          {
              "name": "CSS ID's",
              "scope": [
                  "source.sass keyword.control"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "Inserted",
              "scope": [
                  "markup.inserted"
              ],
              "settings": {
                  "foreground": "${base0B}"
              }
          },
          {
              "name": "Deleted",
              "scope": [
                  "markup.deleted"
              ],
              "settings": {
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Changed",
              "scope": [
                  "markup.changed"
              ],
              "settings": {
                  "foreground": "${base0E}"
              }
          },
          {
              "name": "Regular Expressions",
              "scope": [
                  "string.regexp"
              ],
              "settings": {
                  "foreground": "${base0C}"
              }
          },
          {
              "name": "Escape Characters",
              "scope": [
                  "constant.character.escape"
              ],
              "settings": {
                  "foreground": "${base0C}"
              }
          },
          {
              "name": "URL",
              "scope": [
                  "*url*",
                  "*link*",
                  "*uri*"
              ],
              "settings": {
                  "fontStyle": "underline"
              }
          },
          {
              "name": "Decorators",
              "scope": [
                  "tag.decorator.js entity.name.tag.js",
                  "tag.decorator.js punctuation.definition.tag.js"
              ],
              "settings": {
                  "fontStyle": "italic",
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "ES7 Bind Operator",
              "scope": [
                  "source.js constant.other.object.key.js string.unquoted.label.js"
              ],
              "settings": {
                  "fontStyle": "italic",
                  "foreground": "${base0E}"
              }
          },
          {
              "name": "JSON Key - Level 0",
              "scope": [
                  "source.json meta.structure.dictionary.json support.type.property-name.json"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "JSON Key - Level 1",
              "scope": [
                  "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "JSON Key - Level 2",
              "scope": [
                  "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "JSON Key - Level 3",
              "scope": [
                  "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "JSON Key - Level 4",
              "scope": [
                  "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "JSON Key - Level 5",
              "scope": [
                  "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "JSON Key - Level 6",
              "scope": [
                  "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "JSON Key - Level 7",
              "scope": [
                  "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "JSON Key - Level 8",
              "scope": [
                  "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "Markdown - Plain",
              "scope": [
                  "text.html.markdown",
                  "punctuation.definition.list_item.markdown"
              ],
              "settings": {
                  "foreground": "${base05}"
              }
          },
          {
              "name": "Markdown - Markup Raw Inline",
              "scope": [
                  "text.html.markdown markup.inline.raw.markdown"
              ],
              "settings": {
                  "foreground": "${base0E}"
              }
          },
          {
              "name": "Markdown - Markup Raw Inline Punctuation",
              "scope": [
                  "text.html.markdown markup.inline.raw.markdown punctuation.definition.raw.markdown"
              ],
              "settings": {
                  "foreground": "${base0C}"
              }
          },
          {
              "name": "Markdown - Line Break",
              "scope": [
                  "text.html.markdown meta.dummy.line-break"
              ],
              "settings": {
                  "foreground": "${base03}"
              }
          },
          {
              "name": "Markdown - Heading",
              "scope": [
                  "markdown.heading",
                  "markup.heading | markup.heading entity.name",
                  "markup.heading.markdown punctuation.definition.heading.markdown"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "Markup - Italic",
              "scope": [
                  "markup.italic"
              ],
              "settings": {
                  "fontStyle": "italic",
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Markup - Bold",
              "scope": [
                  "markup.bold",
                  "markup.bold string"
              ],
              "settings": {
                  "fontStyle": "bold",
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Markup - Bold-Italic",
              "scope": [
                  "markup.bold markup.italic",
                  "markup.italic markup.bold",
                  "markup.quote markup.bold",
                  "markup.bold markup.italic string",
                  "markup.italic markup.bold string",
                  "markup.quote markup.bold string"
              ],
              "settings": {
                  "fontStyle": "bold",
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Markup - Underline",
              "scope": [
                  "markup.underline"
              ],
              "settings": {
                  "fontStyle": "underline",
                  "foreground": "${base09}"
              }
          },
          {
              "name": "Markdown - Blockquote",
              "scope": [
                  "markup.quote punctuation.definition.blockquote.markdown"
              ],
              "settings": {
                  "foreground": "${base0C}"
              }
          },
          {
              "name": "Markup - Quote",
              "scope": [
                  "markup.quote"
              ],
              "settings": {
                  "fontStyle": "italic"
              }
          },
          {
              "name": "Markdown - Link",
              "scope": [
                  "string.other.link.title.markdown"
              ],
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "name": "Markdown - Link Description",
              "scope": [
                  "string.other.link.description.title.markdown"
              ],
              "settings": {
                  "foreground": "${base0E}"
              }
          },
          {
              "name": "Markdown - Link Anchor",
              "scope": [
                  "constant.other.reference.link.markdown"
              ],
              "settings": {
                  "foreground": "${base0A}"
              }
          },
          {
              "name": "Markup - Raw Block",
              "scope": [
                  "markup.raw.block"
              ],
              "settings": {
                  "foreground": "${base0E}"
              }
          },
          {
              "name": "Markdown - Raw Block Fenced",
              "scope": [
                  "markup.raw.block.fenced.markdown"
              ],
              "settings": {
                  "foreground": "#00000050"
              }
          },
          {
              "name": "Markdown - Fenced Bode Block",
              "scope": [
                  "punctuation.definition.fenced.markdown"
              ],
              "settings": {
                  "foreground": "#00000050"
              }
          },
          {
              "name": "Markdown - Fenced Code Block Variable",
              "scope": [
                  "markup.raw.block.fenced.markdown",
                  "variable.language.fenced.markdown"
              ],
              "settings": {
                  "foreground": "${base0E}"
              }
          },
          {
              "name": "Markdown - Fenced Language",
              "scope": [
                  "variable.language.fenced.markdown"
              ],
              "settings": {
                  "foreground": "${base08}"
              }
          },
          {
              "name": "Markdown - Separator",
              "scope": [
                  "meta.separator"
              ],
              "settings": {
                  "fontStyle": "bold",
                  "foreground": "${base0C}"
              }
          },
          {
              "name": "Markup - Table",
              "scope": [
                  "markup.table"
              ],
              "settings": {
                  "foreground": "${base0E}"
              }
          },
          {
              "scope": "token.info-token",
              "settings": {
                  "foreground": "${base0D}"
              }
          },
          {
              "scope": "token.warn-token",
              "settings": {
                  "foreground": "${base0A}"
              }
          },
          {
              "scope": "token.error-token",
              "settings": {
                  "foreground": "${base08}"
              }
          },
          {
              "scope": "token.debug-token",
              "settings": {
                  "foreground": "${base0E}"
              }
          }
      ]
  }
''
