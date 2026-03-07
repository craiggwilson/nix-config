# VSCode theme template.
#
# Receives the withHashtag color attrset (which carries mix/lighten/darken).
# Derives five intermediate neutral shades between base04 (dark foreground) and
# base05 (default foreground) via linear interpolation. The base24 spec has no
# slots for these mid-range neutrals, so they are computed at even 1/6 intervals
# to fill the gap between the two foreground anchors.
colors:
let
  # Intermediate neutrals: evenly spaced between base04 and base05.
  neutral1 = colors.mix colors.base04 colors.base05 1 6;
  neutral2 = colors.mix colors.base04 colors.base05 2 6;
  neutral3 = colors.mix colors.base04 colors.base05 3 6;
  neutral4 = colors.mix colors.base04 colors.base05 4 6;
  neutral5 = colors.mix colors.base04 colors.base05 5 6;
in
with colors;
''
  {
    "name": "hdwlinux",
    "type": "dark",
    "semanticHighlighting": true,
    "semanticTokenColors": {
      "enumMember": { "foreground": "${base0C}" },
      "selfKeyword": { "foreground": "${base08}", "fontStyle": "italic" },
      "boolean": { "foreground": "${base09}" },
      "number": { "foreground": "${base09}" },
      "variable.defaultLibrary": { "foreground": "${base12}" },
      "class:python": { "foreground": "${base0A}", "fontStyle": "italic" },
      "class.builtin:python": { "foreground": "${base0E}", "fontStyle": "italic" },
      "variable.typeHint:python": { "foreground": "${base0A}", "fontStyle": "italic" },
      "function.decorator:python": { "foreground": "${base09}", "fontStyle": "italic" },
      "variable.readonly:javascript": { "foreground": "${base05}" },
      "variable.readonly:typescript": { "foreground": "${base05}" },
      "variable.readonly:javascriptreact": { "foreground": "${base05}" },
      "variable.readonly:typescriptreact": { "foreground": "${base05}" },
      "type.defaultLibrary:go": { "foreground": "${base0E}", "fontStyle": "italic" },
      "variable.readonly.defaultLibrary:go": { "foreground": "${base0E}", "fontStyle": "italic" },
      "tomlArrayKey": { "foreground": "${base0D}", "fontStyle": "" },
      "tomlTableKey": { "foreground": "${base0D}", "fontStyle": "" },
      "builtinAttribute.attribute.library:rust": { "foreground": "${base0D}" },
      "generic.attribute:rust": { "foreground": "${base05}" },
      "constant.builtin.readonly:nix": { "foreground": "${base0E}" },
      "heading.1": { "foreground": "${base08}" },
      "heading.2": { "foreground": "${base09}" },
      "heading.3": { "foreground": "${base0A}" },
      "heading.4": { "foreground": "${base0B}" },
      "heading.5": { "foreground": "${base16}" },
      "heading.6": { "foreground": "${base07}" },
      "text.emph": { "foreground": "${base08}", "fontStyle": "italic" },
      "text.strong": { "foreground": "${base08}", "fontStyle": "bold" },
      "text.math": { "foreground": "${base0F}" }
    },
    "colors": {
      "focusBorder": "${base0E}",
      "foreground": "${base05}",
      "disabledForeground": "${neutral3}",
      "widget.shadow": "${base11}",
      "selection.background": "${base0E}40",
      "descriptionForeground": "${base05}",
      "errorForeground": "${base08}",
      "icon.foreground": "${base0E}",
      "sash.hoverBorder": "${base0E}",

      "window.activeBorder": "${base11}",
      "window.inactiveBorder": "${base11}",

      "textBlockQuote.background": "${base01}",
      "textBlockQuote.border": "${base0E}",
      "textCodeBlock.background": "${base02}",
      "textLink.activeForeground": "${base0D}",
      "textLink.foreground": "${base0D}",
      "textPreformat.foreground": "${base05}",
      "textSeparator.foreground": "${base0E}",

      "activityBar.background": "${base11}",
      "activityBar.foreground": "${base0E}",
      "activityBar.inactiveForeground": "${neutral1}",
      "activityBar.border": "${base11}",
      "activityBar.activeBorder": "${base0E}",
      "activityBar.activeBackground": "#00000000",
      "activityBarBadge.background": "${base0E}",
      "activityBarBadge.foreground": "${base11}",

      "badge.background": "${base03}",
      "badge.foreground": "${base05}",

      "breadcrumb.foreground": "${base05}cc",
      "breadcrumb.background": "${base00}",
      "breadcrumb.focusForeground": "${base0E}",
      "breadcrumb.activeSelectionForeground": "${base0E}",
      "breadcrumbPicker.background": "${base01}",

      "button.background": "${base0E}",
      "button.foreground": "${base11}",
      "button.border": "#00000000",
      "button.separator": "${base11}40",
      "button.hoverBackground": "${base07}",
      "button.secondaryBackground": "${base04}",
      "button.secondaryForeground": "${base05}",
      "button.secondaryHoverBackground": "${base03}",

      "checkbox.background": "${base03}",
      "checkbox.foreground": "${base0E}",
      "checkbox.border": "${base11}",

      "commandCenter.foreground": "${base05}",
      "commandCenter.activeForeground": "${base0E}",
      "commandCenter.background": "${base01}",
      "commandCenter.activeBackground": "${base02}",
      "commandCenter.border": "${base0E}",
      "commandCenter.inactiveForeground": "${neutral3}",
      "commandCenter.inactiveBorder": "${neutral3}",
      "commandCenter.activeBorder": "${base0E}",

      "debugToolBar.background": "${base01}",
      "debugToolBar.border": "${base02}",
      "editor.focusedStackFrameHighlightBackground": "${base0A}33",
      "editor.stackFrameHighlightBackground": "${base0A}26",
      "debugView.exceptionLabelBackground": "${base08}",
      "debugView.exceptionLabelForeground": "${base05}",
      "debugView.stateLabelBackground": "${base0B}",
      "debugView.stateLabelForeground": "${base11}",
      "debugView.valueChangedHighlight": "${base0D}",
      "debugTokenExpression.name": "${base07}",
      "debugTokenExpression.value": "${base0B}",
      "debugTokenExpression.string": "${base0B}",
      "debugTokenExpression.boolean": "${base09}",
      "debugTokenExpression.number": "${base09}",
      "debugTokenExpression.error": "${base08}",

      "diffEditor.insertedTextBackground": "${base0B}33",
      "diffEditor.removedTextBackground": "${base08}33",
      "diffEditor.insertedLineBackground": "${base0B}1a",
      "diffEditor.removedLineBackground": "${base08}1a",
      "diffEditor.diagonalFill": "${base04}99",
      "diffEditorOverview.insertedForeground": "${base0B}99",
      "diffEditorOverview.removedForeground": "${base08}99",

      "dropdown.background": "${base01}",
      "dropdown.listBackground": "${base04}",
      "dropdown.border": "${base0E}",
      "dropdown.foreground": "${base05}",

      "editor.background": "${base00}",
      "editor.foreground": "${base05}",
      "editor.lineHighlightBackground": "${base05}12",
      "editor.lineHighlightBorder": "#00000000",
      "editor.selectionBackground": "${neutral3}40",
      "editor.selectionHighlightBackground": "${neutral3}33",
      "editor.selectionHighlightBorder": "${neutral3}",
      "editor.inactiveSelectionBackground": "${neutral3}26",
      "editor.wordHighlightBackground": "${neutral3}33",
      "editor.wordHighlightBorder": "${neutral3}",
      "editor.wordHighlightStrongBackground": "${base0D}33",
      "editor.wordHighlightStrongBorder": "${base0D}",
      "editor.findMatchBackground": "#5e3f53",
      "editor.findMatchBorder": "${base12}",
      "editor.findMatchHighlightBackground": "#3e5767",
      "editor.findMatchHighlightBorder": "${base16}",
      "editor.findRangeHighlightBackground": "${base02}40",
      "editor.findRangeHighlightBorder": "#00000000",
      "editor.rangeHighlightBackground": "${base0D}1a",
      "editor.rangeHighlightBorder": "#00000000",
      "editor.hoverHighlightBackground": "${base0D}33",
      "editor.snippetTabstopHighlightBackground": "${base04}",
      "editor.snippetFinalTabstopHighlightBackground": "${base0B}33",
      "editorBracketMatch.background": "${base04}40",
      "editorBracketMatch.border": "${base04}",
      "editorBracketHighlight.foreground1": "${base0E}",
      "editorBracketHighlight.foreground2": "${base0D}",
      "editorBracketHighlight.foreground3": "${base0C}",
      "editorBracketHighlight.foreground4": "${base0A}",
      "editorBracketHighlight.foreground5": "${base09}",
      "editorBracketHighlight.foreground6": "${base08}",
      "editorBracketHighlight.unexpectedBracket.foreground": "${base08}",
      "editorBracketPairGuide.activeBackground1": "${base0E}",
      "editorBracketPairGuide.activeBackground2": "${base0D}",
      "editorBracketPairGuide.activeBackground3": "${base0C}",
      "editorBracketPairGuide.activeBackground4": "${base0A}",
      "editorBracketPairGuide.activeBackground5": "${base09}",
      "editorBracketPairGuide.activeBackground6": "${base08}",
      "editorCursor.foreground": "${base06}",
      "editorCursor.background": "${base00}",

      "editorCodeLens.foreground": "${neutral2}",

      "editorError.foreground": "${base08}",
      "editorError.border": "#00000000",
      "editorWarning.foreground": "${base0A}",
      "editorWarning.border": "#00000000",
      "editorInfo.foreground": "${base0D}",
      "editorInfo.border": "#00000000",
      "editorHint.foreground": "${base0B}",

      "editorGhostText.foreground": "${neutral2}",

      "editorGroup.border": "${base04}",
      "editorGroup.dropBackground": "${base0E}33",
      "editorGroupHeader.noTabsBackground": "${base00}",
      "editorGroupHeader.tabsBackground": "${base11}",
      "editorGroupHeader.tabsBorder": "${base11}",

      "editorGutter.background": "${base00}",
      "editorGutter.modifiedBackground": "${base0A}",
      "editorGutter.addedBackground": "${base0B}",
      "editorGutter.deletedBackground": "${base08}",
      "editorGutter.commentRangeForeground": "${base02}",
      "editorGutter.foldingControlForeground": "${neutral3}",

      "editorHoverWidget.background": "${base01}",
      "editorHoverWidget.border": "${base04}",
      "editorHoverWidget.foreground": "${base05}",
      "editorHoverWidget.highlightForeground": "${base0D}",
      "editorHoverWidget.statusBarBackground": "${base02}",

      "editorIndentGuide.background1": "${base03}",
      "editorIndentGuide.activeBackground1": "${base04}",

      "editorInlayHint.foreground": "${base04}",
      "editorInlayHint.background": "${base01}bf",
      "editorInlayHint.typeForeground": "${neutral5}",
      "editorInlayHint.typeBackground": "${base01}bf",
      "editorInlayHint.parameterForeground": "${neutral4}",
      "editorInlayHint.parameterBackground": "${base01}bf",

      "editorLightBulb.foreground": "${base0A}",
      "editorLightBulbAutoFix.foreground": "${base0A}",

      "editorLineNumber.foreground": "${neutral2}",
      "editorLineNumber.activeForeground": "${base0E}",

      "editorLink.activeForeground": "${base0D}",

      "editorMarkerNavigation.background": "${base01}",
      "editorMarkerNavigationError.background": "${base08}",
      "editorMarkerNavigationWarning.background": "${base0A}",
      "editorMarkerNavigationInfo.background": "${base0D}",

      "editorOverviewRuler.border": "${base11}",
      "editorOverviewRuler.findMatchForeground": "${base0A}",
      "editorOverviewRuler.rangeHighlightForeground": "${base0D}",
      "editorOverviewRuler.selectionHighlightForeground": "${neutral3}",
      "editorOverviewRuler.wordHighlightForeground": "${neutral3}",
      "editorOverviewRuler.wordHighlightStrongForeground": "${base0D}",
      "editorOverviewRuler.modifiedForeground": "${base0A}",
      "editorOverviewRuler.addedForeground": "${base0B}",
      "editorOverviewRuler.deletedForeground": "${base08}",
      "editorOverviewRuler.errorForeground": "${base08}",
      "editorOverviewRuler.warningForeground": "${base0A}",
      "editorOverviewRuler.infoForeground": "${base0D}",
      "editorOverviewRuler.bracketMatchForeground": "${base04}",

      "editorRuler.foreground": "${base03}",

      "editorStickyScroll.background": "${base00}",
      "editorStickyScrollHover.background": "${base02}",

      "editorSuggestWidget.background": "${base01}",
      "editorSuggestWidget.border": "${base04}",
      "editorSuggestWidget.foreground": "${base05}",
      "editorSuggestWidget.highlightForeground": "${base0E}",
      "editorSuggestWidget.selectedBackground": "${base02}",
      "editorSuggestWidget.selectedForeground": "${base05}",
      "editorSuggestWidget.selectedIconForeground": "${base0E}",
      "editorSuggestWidgetStatus.foreground": "${neutral3}",

      "editorUnnecessaryCode.opacity": "#000000aa",

      "editorWidget.background": "${base01}",
      "editorWidget.border": "${base04}",
      "editorWidget.foreground": "${base05}",
      "editorWidget.resizeBorder": "${base0E}",

      "extensionBadge.remoteBackground": "${base0D}",
      "extensionBadge.remoteForeground": "${base11}",
      "extensionButton.prominentBackground": "${base0E}",
      "extensionButton.prominentForeground": "${base11}",
      "extensionButton.prominentHoverBackground": "${base07}",

      "gitDecoration.addedResourceForeground": "${base0B}",
      "gitDecoration.conflictingResourceForeground": "${base09}",
      "gitDecoration.deletedResourceForeground": "${base08}",
      "gitDecoration.ignoredResourceForeground": "${neutral2}",
      "gitDecoration.modifiedResourceForeground": "${base0A}",
      "gitDecoration.renamedResourceForeground": "${base0B}",
      "gitDecoration.stageDeletedResourceForeground": "${base08}",
      "gitDecoration.stageModifiedResourceForeground": "${base0A}",
      "gitDecoration.submoduleResourceForeground": "${base0D}",
      "gitDecoration.untrackedResourceForeground": "${base0B}",

      "input.background": "${base02}",
      "input.border": "${base04}",
      "input.foreground": "${base05}",
      "input.placeholderForeground": "${base05}73",
      "inputOption.activeBackground": "${base0E}33",
      "inputOption.activeBorder": "${base0E}",
      "inputOption.activeForeground": "${base05}",
      "inputValidation.errorBackground": "${base08}",
      "inputValidation.errorBorder": "${base08}",
      "inputValidation.errorForeground": "${base11}",
      "inputValidation.infoBackground": "${base0D}",
      "inputValidation.infoBorder": "${base0D}",
      "inputValidation.infoForeground": "${base11}",
      "inputValidation.warningBackground": "${base0A}",
      "inputValidation.warningBorder": "${base0A}",
      "inputValidation.warningForeground": "${base11}",

      "keybindingLabel.background": "${base02}",
      "keybindingLabel.border": "${base04}",
      "keybindingLabel.bottomBorder": "${base04}",
      "keybindingLabel.foreground": "${base05}",

      "list.activeSelectionBackground": "${base02}",
      "list.activeSelectionForeground": "${base05}",
      "list.activeSelectionIconForeground": "${base0E}",
      "list.dropBackground": "${base0E}33",
      "list.errorForeground": "${base08}",
      "list.filterMatchBackground": "${base0A}33",
      "list.filterMatchBorder": "${base0A}",
      "list.focusBackground": "${base02}",
      "list.focusForeground": "${base05}",
      "list.focusHighlightForeground": "${base0E}",
      "list.focusOutline": "${base0E}",
      "list.highlightForeground": "${base0E}",
      "list.hoverBackground": "${base02}80",
      "list.hoverForeground": "${base05}",
      "list.inactiveFocusBackground": "${base02}",
      "list.inactiveFocusOutline": "${base04}",
      "list.inactiveSelectionBackground": "${base02}",
      "list.inactiveSelectionForeground": "${base05}",
      "list.inactiveSelectionIconForeground": "${base0E}",
      "list.warningForeground": "${base0A}",
      "listFilterWidget.background": "${base02}",
      "listFilterWidget.noMatchesOutline": "${base08}",
      "listFilterWidget.outline": "${base0E}",
      "listFilterWidget.shadow": "${base11}",

      "menu.background": "${base01}",
      "menu.border": "${base04}",
      "menu.foreground": "${base05}",
      "menu.selectionBackground": "${base02}",
      "menu.selectionBorder": "${base04}",
      "menu.selectionForeground": "${base05}",
      "menu.separatorBackground": "${base04}",
      "menubar.selectionBackground": "${base02}",
      "menubar.selectionBorder": "${base04}",
      "menubar.selectionForeground": "${base05}",

      "merge.currentContentBackground": "${base0B}33",
      "merge.currentHeaderBackground": "${base0B}66",
      "merge.incomingContentBackground": "${base0D}33",
      "merge.incomingHeaderBackground": "${base0D}66",
      "merge.commonContentBackground": "${base04}33",
      "merge.commonHeaderBackground": "${base04}66",
      "mergeEditor.change.background": "${base0B}1a",
      "mergeEditor.change.word.background": "${base0B}33",
      "mergeEditor.conflict.handled.minimapOverViewRuler": "${base0B}",
      "mergeEditor.conflict.unhandled.minimapOverViewRuler": "${base08}",

      "minimap.background": "${base01}80",
      "minimap.errorHighlight": "${base08}",
      "minimap.findMatchHighlight": "${base0A}",
      "minimap.selectionHighlight": "${base04}bf",
      "minimap.warningHighlight": "${base0A}",
      "minimapGutter.addedBackground": "${base0B}bf",
      "minimapGutter.deletedBackground": "${base08}bf",
      "minimapGutter.modifiedBackground": "${base0A}bf",
      "minimapSlider.activeBackground": "${base04}80",
      "minimapSlider.background": "${base04}40",
      "minimapSlider.hoverBackground": "${base04}60",

      "notebook.cellBorderColor": "${base04}",
      "notebook.cellEditorBackground": "${base01}",
      "notebook.cellInsertionIndicator": "${base0E}",
      "notebook.cellStatusBarItemHoverBackground": "${base02}",
      "notebook.cellToolbarSeparator": "${base04}",
      "notebook.editorBackground": "${base00}",
      "notebook.focusedCellBackground": "${base02}",
      "notebook.focusedCellBorder": "${base0E}",
      "notebook.focusedEditorBorder": "${base0E}",
      "notebook.inactiveFocusedCellBorder": "${base04}",
      "notebook.outputContainerBackgroundColor": "${base01}",
      "notebook.selectedCellBackground": "${base02}",
      "notebook.selectedCellBorder": "${base04}",
      "notebook.symbolHighlightBackground": "${base0D}33",
      "notebookScrollbarSlider.activeBackground": "${base04}80",
      "notebookScrollbarSlider.background": "${base04}40",
      "notebookScrollbarSlider.hoverBackground": "${base04}60",
      "notebookStatusErrorIcon.foreground": "${base08}",
      "notebookStatusRunningIcon.foreground": "${base09}",
      "notebookStatusSuccessIcon.foreground": "${base0B}",

      "panel.background": "${base00}",
      "panel.border": "${base04}",
      "panel.dropBorder": "${base0E}",
      "panelInput.border": "${base04}",
      "panelSection.border": "${base04}",
      "panelSection.dropBackground": "${base0E}33",
      "panelSectionHeader.background": "${base02}",
      "panelSectionHeader.foreground": "${base05}",
      "panelTitle.activeBorder": "${base0E}",
      "panelTitle.activeForeground": "${base05}",
      "panelTitle.inactiveForeground": "${neutral4}",

      "peekView.border": "${base0E}",
      "peekViewEditor.background": "${base01}",
      "peekViewEditor.matchHighlightBackground": "${base0A}33",
      "peekViewEditor.matchHighlightBorder": "${base0A}",
      "peekViewEditorGutter.background": "${base01}",
      "peekViewResult.background": "${base01}",
      "peekViewResult.fileForeground": "${base05}",
      "peekViewResult.lineForeground": "${neutral3}",
      "peekViewResult.matchHighlightBackground": "${base0A}33",
      "peekViewResult.selectionBackground": "${base02}",
      "peekViewResult.selectionForeground": "${base05}",
      "peekViewTitle.background": "${base02}",
      "peekViewTitleDescription.foreground": "${neutral3}",
      "peekViewTitleLabel.foreground": "${base05}",

      "pickerGroup.border": "${base04}",
      "pickerGroup.foreground": "${base0E}",

      "ports.iconRunningProcessForeground": "${base0B}",

      "problemsErrorIcon.foreground": "${base08}",
      "problemsInfoIcon.foreground": "${base0D}",
      "problemsWarningIcon.foreground": "${base0A}",

      "progressBar.background": "${base0E}",

      "quickInput.background": "${base01}",
      "quickInput.foreground": "${base05}",
      "quickInputList.focusBackground": "${base02}",
      "quickInputList.focusForeground": "${base05}",
      "quickInputList.focusIconForeground": "${base0E}",
      "quickInputTitle.background": "${base02}",

      "scrollbar.shadow": "${base11}",
      "scrollbarSlider.activeBackground": "${base04}80",
      "scrollbarSlider.background": "${base04}40",
      "scrollbarSlider.hoverBackground": "${base04}60",

      "search.resultsInfoForeground": "${neutral3}",
      "searchEditor.findMatchBackground": "${base0A}33",
      "searchEditor.findMatchBorder": "${base0A}",
      "searchEditor.textInputBorder": "${base04}",

      "settings.checkboxBackground": "${base03}",
      "settings.checkboxBorder": "${base11}",
      "settings.checkboxForeground": "${base0E}",
      "settings.dropdownBackground": "${base03}",
      "settings.dropdownBorder": "${base11}",
      "settings.dropdownForeground": "${base05}",
      "settings.dropdownListBorder": "${base04}",
      "settings.focusedRowBackground": "${base04}33",
      "settings.focusedRowBorder": "${base0E}",
      "settings.headerForeground": "${base05}",
      "settings.modifiedItemIndicator": "${base0E}",
      "settings.numberInputBackground": "${base03}",
      "settings.numberInputBorder": "${base11}",
      "settings.numberInputForeground": "${base05}",
      "settings.rowHoverBackground": "${base04}1a",
      "settings.textInputBackground": "${base03}",
      "settings.textInputBorder": "${base11}",
      "settings.textInputForeground": "${base05}",

      "sideBar.background": "${base01}",
      "sideBar.border": "${base11}",
      "sideBar.dropBackground": "${base0E}33",
      "sideBar.foreground": "${base05}",
      "sideBarSectionHeader.background": "${base01}",
      "sideBarSectionHeader.border": "${base11}",
      "sideBarSectionHeader.foreground": "${base05}",
      "sideBarTitle.foreground": "${base0E}",

      "statusBar.background": "${base11}",
      "statusBar.border": "${base11}",
      "statusBar.debuggingBackground": "${base09}",
      "statusBar.debuggingBorder": "${base11}",
      "statusBar.debuggingForeground": "${base11}",
      "statusBar.focusBorder": "${base0E}",
      "statusBar.foreground": "${base05}",
      "statusBar.noFolderBackground": "${base11}",
      "statusBar.noFolderBorder": "${base11}",
      "statusBar.noFolderForeground": "${base05}",
      "statusBarItem.activeBackground": "${base04}",
      "statusBarItem.compactHoverBackground": "${base04}",
      "statusBarItem.errorBackground": "#00000000",
      "statusBarItem.errorForeground": "${base08}",
      "statusBarItem.focusBorder": "${base0E}",
      "statusBarItem.hoverBackground": "${base04}",
      "statusBarItem.prominentBackground": "#00000000",
      "statusBarItem.prominentForeground": "${base0E}",
      "statusBarItem.prominentHoverBackground": "${base04}",
      "statusBarItem.remoteBackground": "${base0D}",
      "statusBarItem.remoteForeground": "${base11}",
      "statusBarItem.warningBackground": "#00000000",
      "statusBarItem.warningForeground": "${base09}",

      "symbolIcon.arrayForeground": "${base09}",
      "symbolIcon.booleanForeground": "${base09}",
      "symbolIcon.classForeground": "${base0A}",
      "symbolIcon.colorForeground": "${base17}",
      "symbolIcon.constantForeground": "${base09}",
      "symbolIcon.constructorForeground": "${base0E}",
      "symbolIcon.enumeratorForeground": "${base0A}",
      "symbolIcon.enumeratorMemberForeground": "${base0C}",
      "symbolIcon.eventForeground": "${base08}",
      "symbolIcon.fieldForeground": "${base05}",
      "symbolIcon.fileForeground": "${base0E}",
      "symbolIcon.folderForeground": "${base0E}",
      "symbolIcon.functionForeground": "${base0D}",
      "symbolIcon.interfaceForeground": "${base0A}",
      "symbolIcon.keyForeground": "${base0E}",
      "symbolIcon.keywordForeground": "${base0E}",
      "symbolIcon.methodForeground": "${base0D}",
      "symbolIcon.moduleForeground": "${base05}",
      "symbolIcon.namespaceForeground": "${base0A}",
      "symbolIcon.nullForeground": "${base08}",
      "symbolIcon.numberForeground": "${base09}",
      "symbolIcon.objectForeground": "${base0A}",
      "symbolIcon.operatorForeground": "${base0C}",
      "symbolIcon.packageForeground": "${base09}",
      "symbolIcon.propertyForeground": "${base05}",
      "symbolIcon.referenceForeground": "${base0A}",
      "symbolIcon.snippetForeground": "${base0B}",
      "symbolIcon.stringForeground": "${base0B}",
      "symbolIcon.structForeground": "${base0A}",
      "symbolIcon.textForeground": "${base05}",
      "symbolIcon.typeParameterForeground": "${base0C}",
      "symbolIcon.unitForeground": "${base09}",
      "symbolIcon.variableForeground": "${base05}",

      "tab.activeBackground": "${base00}",
      "tab.activeBorder": "#00000000",
      "tab.activeBorderTop": "${base0E}",
      "tab.activeForeground": "${base0E}",
      "tab.activeModifiedBorder": "${base0A}",
      "tab.border": "${base11}",
      "tab.hoverBackground": "#28283d",
      "tab.hoverBorder": "#00000000",
      "tab.hoverForeground": "${base0E}",
      "tab.inactiveBackground": "${base01}",
      "tab.inactiveForeground": "${neutral1}",
      "tab.inactiveModifiedBorder": "${base04}",
      "tab.lastPinnedBorder": "${base04}",
      "tab.unfocusedActiveBackground": "${base01}",
      "tab.unfocusedActiveBorder": "#00000000",
      "tab.unfocusedActiveBorderTop": "${base0E}4d",
      "tab.unfocusedActiveForeground": "${neutral3}",
      "tab.unfocusedHoverBackground": "#28283d80",
      "tab.unfocusedHoverForeground": "${neutral3}",
      "tab.unfocusedInactiveBackground": "${base01}",
      "tab.unfocusedInactiveForeground": "${neutral1}80",
      "tab.unfocusedInactiveModifiedBorder": "${base04}80",

      "terminal.ansiBlack": "${base03}",
      "terminal.ansiBlue": "${base0D}",
      "terminal.ansiBrightBlack": "${base04}",
      "terminal.ansiBrightBlue": "${base16}",
      "terminal.ansiBrightCyan": "${base15}",
      "terminal.ansiBrightGreen": "${base0B}",
      "terminal.ansiBrightMagenta": "${base17}",
      "terminal.ansiBrightRed": "${base08}",
      "terminal.ansiBrightWhite": "${neutral5}",
      "terminal.ansiBrightYellow": "${base0A}",
      "terminal.ansiCyan": "${base0C}",
      "terminal.ansiGreen": "${base0B}",
      "terminal.ansiMagenta": "${base0E}",
      "terminal.ansiRed": "${base08}",
      "terminal.ansiWhite": "${neutral4}",
      "terminal.ansiYellow": "${base0A}",
      "terminal.background": "${base00}",
      "terminal.border": "${base04}",
      "terminal.foreground": "${base05}",
      "terminal.selectionBackground": "${neutral3}40",
      "terminal.tab.activeBorder": "${base0E}",
      "terminalCommandDecoration.defaultBackground": "${neutral3}",
      "terminalCommandDecoration.errorBackground": "${base08}",
      "terminalCommandDecoration.successBackground": "${base0B}",
      "terminalCursor.background": "${base00}",
      "terminalCursor.foreground": "${base06}",
      "terminalOverviewRuler.cursorForeground": "${base04}",
      "terminalOverviewRuler.findMatchForeground": "${base15}4d",

      "testing.iconErrored": "${base08}",
      "testing.iconFailed": "${base08}",
      "testing.iconPassed": "${base0B}",
      "testing.iconQueued": "${base09}",
      "testing.iconSkipped": "${neutral3}",
      "testing.iconUnset": "${neutral3}",
      "testing.message.error.decorationForeground": "${base08}",
      "testing.message.error.lineBackground": "${base08}1a",
      "testing.message.info.decorationForeground": "${neutral3}",
      "testing.peekBorder": "${base08}",
      "testing.peekHeaderBackground": "${base08}1a",
      "testing.runAction": "${base0B}",

      "titleBar.activeBackground": "${base11}",
      "titleBar.activeForeground": "${base05}",
      "titleBar.border": "${base11}",
      "titleBar.inactiveBackground": "${base11}",
      "titleBar.inactiveForeground": "${base05}80",

      "toolbar.activeBackground": "${base04}",
      "toolbar.hoverBackground": "${base03}",

      "tree.indentGuidesStroke": "${base03}",
      "tree.inactiveIndentGuidesStroke": "${base02}",

      "walkThrough.embeddedEditorBackground": "${base01}",
      "welcomePage.buttonBackground": "${base02}",
      "welcomePage.buttonHoverBackground": "${base03}",
      "welcomePage.progress.background": "${base02}",
      "welcomePage.progress.foreground": "${base0E}",
      "welcomePage.tileBackground": "${base01}",
      "welcomePage.tileHoverBackground": "${base02}",
      "welcomePage.tileShadow": "${base11}"
    },
    "tokenColors": [
      {
        "name": "Basic text / default",
        "scope": [
          "source",
          "text"
        ],
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "Comments",
        "scope": [
          "comment",
          "punctuation.definition.comment"
        ],
        "settings": {
          "foreground": "${neutral3}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Strings",
        "scope": "string",
        "settings": {
          "foreground": "${base0B}"
        }
      },
      {
        "name": "String escape sequences",
        "scope": [
          "constant.character.escape",
          "constant.character.string.escape",
          "constant.regexp"
        ],
        "settings": {
          "foreground": "${base17}"
        }
      },
      {
        "name": "Numbers",
        "scope": [
          "constant.numeric",
          "number"
        ],
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Boolean / language constants",
        "scope": [
          "constant.language",
          "constant.language.boolean"
        ],
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Other constants",
        "scope": "constant.other",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Keywords",
        "scope": [
          "keyword",
          "keyword.control",
          "keyword.operator.new",
          "keyword.operator.expression",
          "keyword.operator.cast",
          "keyword.operator.sizeof",
          "keyword.operator.alignof",
          "keyword.operator.typeid",
          "keyword.operator.alignas",
          "keyword.operator.instanceof",
          "keyword.operator.logical.python",
          "keyword.operator.wordlike"
        ],
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Operators",
        "scope": "keyword.operator",
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "Storage types (fn, let, var, class, etc.)",
        "scope": [
          "storage.type",
          "storage.modifier"
        ],
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Function definitions",
        "scope": [
          "entity.name.function",
          "meta.function entity.name.function"
        ],
        "settings": {
          "foreground": "${base0D}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Function calls",
        "scope": [
          "meta.function-call entity.name.function",
          "meta.function-call.generic entity.name.function",
          "support.function"
        ],
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "Types / classes",
        "scope": [
          "entity.name.type",
          "entity.name.class",
          "support.class",
          "support.type"
        ],
        "settings": {
          "foreground": "${base0A}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Type parameters / generics",
        "scope": "variable.parameter.generic",
        "settings": {
          "foreground": "${base0A}"
        }
      },
      {
        "name": "Namespaces / modules",
        "scope": [
          "entity.name.namespace",
          "entity.name.module",
          "entity.name.package"
        ],
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Enum members",
        "scope": "constant.other.enum",
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "Variables",
        "scope": [
          "variable",
          "variable.other"
        ],
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "Function parameters",
        "scope": [
          "variable.parameter",
          "meta.function.parameters variable"
        ],
        "settings": {
          "foreground": "${base12}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Object properties",
        "scope": [
          "variable.other.property",
          "support.variable.property"
        ],
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "Punctuation",
        "scope": [
          "punctuation",
          "meta.brace",
          "punctuation.definition.block",
          "punctuation.definition.parameters",
          "punctuation.section"
        ],
        "settings": {
          "foreground": "${neutral3}"
        }
      },
      {
        "name": "Punctuation — string delimiters",
        "scope": [
          "punctuation.definition.string.begin",
          "punctuation.definition.string.end"
        ],
        "settings": {
          "foreground": "${base0B}"
        }
      },
      {
        "name": "Punctuation — template expression",
        "scope": [
          "punctuation.definition.template-expression.begin",
          "punctuation.definition.template-expression.end",
          "punctuation.section.embedded"
        ],
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Imports / includes",
        "scope": [
          "keyword.control.import",
          "keyword.control.from",
          "keyword.other.import",
          "keyword.other.package"
        ],
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "CSS property names",
        "scope": [
          "support.type.property-name.css",
          "support.type.property-name.scss",
          "support.type.property-name.less"
        ],
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "CSS property values",
        "scope": [
          "support.constant.property-value.css",
          "support.constant.property-value.scss"
        ],
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "CSS selectors",
        "scope": [
          "entity.other.attribute-name.class.css",
          "entity.other.attribute-name.id.css",
          "entity.other.attribute-name.pseudo-class.css",
          "entity.other.attribute-name.pseudo-element.css"
        ],
        "settings": {
          "foreground": "${base0A}"
        }
      },
      {
        "name": "CSS at-rules",
        "scope": "keyword.control.at-rule",
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "CSS units",
        "scope": "keyword.other.unit",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "CSS colors",
        "scope": "constant.other.color.rgb-value",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "HTML/XML tags",
        "scope": "entity.name.tag",
        "settings": {
          "foreground": "${base0D}",
          "fontStyle": ""
        }
      },
      {
        "name": "HTML/XML DOCTYPE",
        "scope": [
          "keyword.other.doctype",
          "meta.tag.sgml.doctype punctuation.definition.tag",
          "meta.tag.metadata.doctype entity.name.tag",
          "meta.tag.metadata.doctype punctuation.definition.tag"
        ],
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "HTML/XML tag attributes",
        "scope": "entity.other.attribute-name",
        "settings": {
          "foreground": "${base0A}"
        }
      },
      {
        "name": "HTML/XML special characters",
        "scope": [
          "text.html constant.character.entity",
          "text.html constant.character.entity punctuation",
          "constant.character.entity.xml",
          "constant.character.entity.xml punctuation",
          "constant.character.entity.js.jsx",
          "constant.character.entity.tsx"
        ],
        "settings": {
          "foreground": "${base08}"
        }
      },
      {
        "name": "Components (JSX/TSX/Vue)",
        "scope": [
          "support.class.component",
          "support.class.component.jsx",
          "support.class.component.tsx",
          "support.class.component.vue"
        ],
        "settings": {
          "foreground": "${base17}",
          "fontStyle": ""
        }
      },
      {
        "name": "JSON keys",
        "scope": [
          "source.json support.type.property-name",
          "source.json meta.structure.dictionary.json string.quoted.double.json"
        ],
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "YAML keys",
        "scope": "entity.name.tag.yaml",
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "TOML keys",
        "scope": [
          "support.type.property-name.toml",
          "entity.other.attribute-name.toml"
        ],
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "TOML table headers",
        "scope": "entity.name.section.toml",
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "Annotations / decorators",
        "scope": [
          "punctuation.definition.annotation",
          "storage.type.annotation"
        ],
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Go annotation comments (go:embed, go:build, etc.)",
        "scope": "comment meta.annotation.go",
        "settings": {
          "foreground": "${base12}"
        }
      },
      {
        "name": "Go annotation parameters",
        "scope": "comment meta.annotation.parameters.go",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Go constants (nil, true, false)",
        "scope": "constant.language.go",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "GraphQL variables",
        "scope": "variable.graphql",
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "GraphQL aliases",
        "scope": "string.unquoted.alias.graphql",
        "settings": {
          "foreground": "${base0F}"
        }
      },
      {
        "name": "GraphQL enum members",
        "scope": "constant.character.enum.graphql",
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "GraphQL field in types",
        "scope": "meta.objectvalues.graphql constant.object.key.graphql string.unquoted.graphql",
        "settings": {
          "foreground": "${base0F}"
        }
      },
      {
        "name": "Java enums",
        "scope": "constant.other.enum.java",
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "Java imports",
        "scope": "storage.modifier.import.java",
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "Javadoc keywords",
        "scope": "comment.block.javadoc.java keyword.other.documentation.javadoc.java",
        "settings": {
          "fontStyle": ""
        }
      },
      {
        "name": "JS/TS exported variable",
        "scope": "meta.export variable.other.readwrite.js",
        "settings": {
          "foreground": "${base12}"
        }
      },
      {
        "name": "JS/TS constants and properties",
        "scope": [
          "variable.other.constant.js",
          "variable.other.constant.ts",
          "variable.other.property.js",
          "variable.other.property.ts"
        ],
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "JSDoc params",
        "scope": [
          "variable.other.jsdoc",
          "comment.block.documentation variable.other"
        ],
        "settings": {
          "foreground": "${base12}",
          "fontStyle": ""
        }
      },
      {
        "name": "JSDoc keywords",
        "scope": "storage.type.class.jsdoc",
        "settings": {
          "fontStyle": ""
        }
      },
      {
        "scope": "support.type.object.console.js",
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "Node constants as keywords",
        "scope": [
          "support.constant.node",
          "support.type.object.module.js"
        ],
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "implements as keyword",
        "scope": "storage.modifier.implements",
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Builtin types (null, undefined, etc.)",
        "scope": [
          "constant.language.null.js",
          "constant.language.null.ts",
          "constant.language.undefined.js",
          "constant.language.undefined.ts",
          "support.type.builtin.ts"
        ],
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Arrow functions",
        "scope": [
          "keyword.declaration.function.arrow.js",
          "storage.type.function.arrow.ts"
        ],
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "TS decorator punctuation",
        "scope": "punctuation.decorator.ts",
        "settings": {
          "foreground": "${base0D}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Extra JS/TS keywords (in, instanceof, typeof, keyof, etc.)",
        "scope": [
          "keyword.operator.expression.in.js",
          "keyword.operator.expression.in.ts",
          "keyword.operator.expression.infer.ts",
          "keyword.operator.expression.instanceof.js",
          "keyword.operator.expression.instanceof.ts",
          "keyword.operator.expression.is",
          "keyword.operator.expression.keyof.ts",
          "keyword.operator.expression.of.js",
          "keyword.operator.expression.of.ts",
          "keyword.operator.expression.typeof.ts"
        ],
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Julia macros",
        "scope": "support.function.macro.julia",
        "settings": {
          "foreground": "${base0C}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Julia language constants",
        "scope": "constant.language.julia",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Julia other constants",
        "scope": "constant.other.symbol.julia",
        "settings": {
          "foreground": "${base12}"
        }
      },
      {
        "name": "LaTeX preamble",
        "scope": "text.tex keyword.control.preamble",
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "LaTeX be functions",
        "scope": "text.tex support.function.be",
        "settings": {
          "foreground": "${base15}"
        }
      },
      {
        "name": "LaTeX math",
        "scope": "constant.other.general.math.tex",
        "settings": {
          "foreground": "${base0F}"
        }
      },
      {
        "name": "Liquid builtin objects and user variables",
        "scope": "variable.language.liquid",
        "settings": {
          "foreground": "${base17}"
        }
      },
      {
        "name": "Lua docstring keywords",
        "scope": "comment.line.double-dash.documentation.lua storage.type.annotation.lua",
        "settings": {
          "foreground": "${base0E}",
          "fontStyle": ""
        }
      },
      {
        "name": "Lua docstring variables",
        "scope": [
          "comment.line.double-dash.documentation.lua entity.name.variable.lua",
          "comment.line.double-dash.documentation.lua variable.lua"
        ],
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "scope": [
          "heading.1.markdown punctuation.definition.heading.markdown",
          "heading.1.markdown",
          "markup.heading.atx.1.mdx",
          "markup.heading.atx.1.mdx punctuation.definition.heading.mdx",
          "markup.heading.setext.1.markdown",
          "markup.heading.heading-0.asciidoc"
        ],
        "settings": {
          "foreground": "${base08}"
        }
      },
      {
        "scope": [
          "heading.2.markdown punctuation.definition.heading.markdown",
          "heading.2.markdown",
          "markup.heading.atx.2.mdx",
          "markup.heading.atx.2.mdx punctuation.definition.heading.mdx",
          "markup.heading.setext.2.markdown",
          "markup.heading.heading-1.asciidoc"
        ],
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "scope": [
          "heading.3.markdown punctuation.definition.heading.markdown",
          "heading.3.markdown",
          "markup.heading.atx.3.mdx",
          "markup.heading.atx.3.mdx punctuation.definition.heading.mdx",
          "markup.heading.heading-2.asciidoc"
        ],
        "settings": {
          "foreground": "${base0A}"
        }
      },
      {
        "scope": [
          "heading.4.markdown punctuation.definition.heading.markdown",
          "heading.4.markdown",
          "markup.heading.atx.4.mdx",
          "markup.heading.atx.4.mdx punctuation.definition.heading.mdx",
          "markup.heading.heading-3.asciidoc"
        ],
        "settings": {
          "foreground": "${base0B}"
        }
      },
      {
        "scope": [
          "heading.5.markdown punctuation.definition.heading.markdown",
          "heading.5.markdown",
          "markup.heading.atx.5.mdx",
          "markup.heading.atx.5.mdx punctuation.definition.heading.mdx",
          "markup.heading.heading-4.asciidoc"
        ],
        "settings": {
          "foreground": "${base16}"
        }
      },
      {
        "scope": [
          "heading.6.markdown punctuation.definition.heading.markdown",
          "heading.6.markdown",
          "markup.heading.atx.6.mdx",
          "markup.heading.atx.6.mdx punctuation.definition.heading.mdx",
          "markup.heading.heading-5.asciidoc"
        ],
        "settings": {
          "foreground": "${base07}"
        }
      },
      {
        "scope": "markup.bold",
        "settings": {
          "foreground": "${base08}",
          "fontStyle": "bold"
        }
      },
      {
        "scope": "markup.italic",
        "settings": {
          "foreground": "${base08}",
          "fontStyle": "italic"
        }
      },
      {
        "scope": "markup.strikethrough",
        "settings": {
          "foreground": "${neutral4}",
          "fontStyle": "strikethrough"
        }
      },
      {
        "name": "Markdown auto links",
        "scope": [
          "punctuation.definition.link",
          "markup.underline.link"
        ],
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "Markdown links",
        "scope": [
          "text.html.markdown punctuation.definition.link.title",
          "string.other.link.title.markdown",
          "markup.link",
          "punctuation.definition.constant.markdown",
          "constant.other.reference.link.markdown",
          "markup.substitution.attribute-reference"
        ],
        "settings": {
          "foreground": "${base07}"
        }
      },
      {
        "name": "Markdown code spans",
        "scope": [
          "punctuation.definition.raw.markdown",
          "markup.inline.raw.string.markdown",
          "markup.raw.block.markdown"
        ],
        "settings": {
          "foreground": "${base0B}"
        }
      },
      {
        "name": "Markdown fenced code language identifier",
        "scope": "fenced_code.block.language",
        "settings": {
          "foreground": "${base15}"
        }
      },
      {
        "name": "Markdown fenced code backticks",
        "scope": [
          "markup.fenced_code.block punctuation.definition",
          "markup.raw support.asciidoc"
        ],
        "settings": {
          "foreground": "${neutral3}"
        }
      },
      {
        "name": "Markdown quotes",
        "scope": [
          "markup.quote",
          "punctuation.definition.quote.begin"
        ],
        "settings": {
          "foreground": "${base17}"
        }
      },
      {
        "name": "Markdown separators",
        "scope": "meta.separator.markdown",
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "Markdown list bullets",
        "scope": [
          "punctuation.definition.list.begin.markdown",
          "markup.list.bullet"
        ],
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "Nix attribute names",
        "scope": [
          "entity.other.attribute-name.multipart.nix",
          "entity.other.attribute-name.single.nix"
        ],
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "Nix parameter names",
        "scope": "variable.parameter.name.nix",
        "settings": {
          "foreground": "${base05}",
          "fontStyle": ""
        }
      },
      {
        "name": "Nix interpolated parameter names",
        "scope": "meta.embedded variable.parameter.name.nix",
        "settings": {
          "foreground": "${base07}",
          "fontStyle": ""
        }
      },
      {
        "name": "Nix paths",
        "scope": "string.unquoted.path.nix",
        "settings": {
          "foreground": "${base17}",
          "fontStyle": ""
        }
      },
      {
        "name": "PHP attributes",
        "scope": [
          "support.attribute.builtin",
          "meta.attribute.php"
        ],
        "settings": {
          "foreground": "${base0A}"
        }
      },
      {
        "name": "PHP parameters (leading dollar sign)",
        "scope": "meta.function.parameters.php punctuation.definition.variable.php",
        "settings": {
          "foreground": "${base12}"
        }
      },
      {
        "name": "PHP constants (null, __FILE__, etc.)",
        "scope": "constant.language.php",
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "PHP functions",
        "scope": "text.html.php support.function",
        "settings": {
          "foreground": "${base15}"
        }
      },
      {
        "name": "PHPdoc keywords",
        "scope": "keyword.other.phpdoc.php",
        "settings": {
          "fontStyle": ""
        }
      },
      {
        "name": "Python arguments reset to text",
        "scope": [
          "support.variable.magic.python",
          "meta.function-call.arguments.python"
        ],
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "Python dunder functions",
        "scope": "support.function.magic.python",
        "settings": {
          "foreground": "${base15}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Python self keyword",
        "scope": [
          "variable.parameter.function.language.special.self.python",
          "variable.language.special.self.python"
        ],
        "settings": {
          "foreground": "${base08}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Python flow/logical keywords (for ... in)",
        "scope": [
          "keyword.control.flow.python",
          "keyword.operator.logical.python"
        ],
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Python storage type",
        "scope": "storage.type.function.python",
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Python function support",
        "scope": [
          "support.token.decorator.python",
          "meta.function.decorator.identifier.python"
        ],
        "settings": {
          "foreground": "${base15}"
        }
      },
      {
        "name": "Python function calls",
        "scope": "meta.function-call.python",
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "Python function decorators",
        "scope": [
          "entity.name.function.decorator.python",
          "punctuation.definition.decorator.python"
        ],
        "settings": {
          "foreground": "${base09}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Python placeholder reset to normal string",
        "scope": "constant.character.format.placeholder.other.python",
        "settings": {
          "foreground": "${base17}"
        }
      },
      {
        "name": "Python exceptions and builtins",
        "scope": [
          "support.type.exception.python",
          "support.function.builtin.python"
        ],
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Python support types",
        "scope": "support.type.python",
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Python constants (True/False)",
        "scope": "constant.language.python",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Python indexed/item-access arguments",
        "scope": [
          "meta.indexed-name.python",
          "meta.item-access.python"
        ],
        "settings": {
          "foreground": "${base12}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Python f-string/binary/unicode storage types",
        "scope": "storage.type.string.python",
        "settings": {
          "foreground": "${base0B}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Python type hints reset",
        "scope": "meta.function.parameters.python",
        "settings": {
          "fontStyle": ""
        }
      },
      {
        "name": "Regex string delimiters",
        "scope": [
          "string.regexp punctuation.definition.string.begin",
          "string.regexp punctuation.definition.string.end"
        ],
        "settings": {
          "foreground": "${base17}"
        }
      },
      {
        "name": "Regex anchors (^, $)",
        "scope": "keyword.control.anchor.regexp",
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Regex regular string match",
        "scope": "string.regexp.ts",
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "Regex group parenthesis and backreferences",
        "scope": [
          "punctuation.definition.group.regexp",
          "keyword.other.back-reference.regexp"
        ],
        "settings": {
          "foreground": "${base0B}"
        }
      },
      {
        "name": "Regex character class []",
        "scope": "punctuation.definition.character-class.regexp",
        "settings": {
          "foreground": "${base0A}"
        }
      },
      {
        "name": "Regex character classes (\\d, \\w, \\s)",
        "scope": "constant.other.character-class.regexp",
        "settings": {
          "foreground": "${base17}"
        }
      },
      {
        "name": "Regex range",
        "scope": "constant.other.character-class.range.regexp",
        "settings": {
          "foreground": "${base06}"
        }
      },
      {
        "name": "Regex quantifier",
        "scope": "keyword.operator.quantifier.regexp",
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "Regex constant/numeric",
        "scope": "constant.character.numeric.regexp",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Regex lookaheads and lookbehinds",
        "scope": [
          "punctuation.definition.group.no-capture.regexp",
          "meta.assertion.look-ahead.regexp",
          "meta.assertion.negative-look-ahead.regexp"
        ],
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "Rust attributes",
        "scope": [
          "meta.annotation.rust",
          "meta.annotation.rust punctuation",
          "meta.attribute.rust",
          "punctuation.definition.attribute.rust"
        ],
        "settings": {
          "foreground": "${base0A}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Rust attribute strings",
        "scope": [
          "meta.attribute.rust string.quoted.double.rust",
          "meta.attribute.rust string.quoted.single.char.rust"
        ],
        "settings": {
          "fontStyle": ""
        }
      },
      {
        "name": "Rust keywords",
        "scope": [
          "entity.name.function.macro.rules.rust",
          "storage.type.module.rust",
          "storage.modifier.rust",
          "storage.type.struct.rust",
          "storage.type.enum.rust",
          "storage.type.trait.rust",
          "storage.type.union.rust",
          "storage.type.impl.rust",
          "storage.type.rust",
          "storage.type.function.rust",
          "storage.type.type.rust"
        ],
        "settings": {
          "foreground": "${base0E}",
          "fontStyle": ""
        }
      },
      {
        "name": "Rust numeric types (u32, i64, etc.)",
        "scope": "entity.name.type.numeric.rust",
        "settings": {
          "foreground": "${base0E}",
          "fontStyle": ""
        }
      },
      {
        "name": "Rust generics",
        "scope": "meta.generic.rust",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Rust impl",
        "scope": "entity.name.impl.rust",
        "settings": {
          "foreground": "${base0A}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Rust module",
        "scope": "entity.name.module.rust",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Rust trait",
        "scope": "entity.name.trait.rust",
        "settings": {
          "foreground": "${base0A}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Rust struct",
        "scope": "storage.type.source.rust",
        "settings": {
          "foreground": "${base0A}"
        }
      },
      {
        "name": "Rust union",
        "scope": "entity.name.union.rust",
        "settings": {
          "foreground": "${base0A}"
        }
      },
      {
        "name": "Rust enum member",
        "scope": "meta.enum.rust storage.type.source.rust",
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "Rust macros",
        "scope": [
          "support.macro.rust",
          "meta.macro.rust support.function.rust",
          "entity.name.function.macro.rust"
        ],
        "settings": {
          "foreground": "${base0D}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Rust lifetimes",
        "scope": [
          "storage.modifier.lifetime.rust",
          "entity.name.type.lifetime"
        ],
        "settings": {
          "foreground": "${base0D}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Rust string formatting",
        "scope": "string.quoted.double.rust constant.other.placeholder.rust",
        "settings": {
          "foreground": "${base17}"
        }
      },
      {
        "name": "Rust return type generic",
        "scope": "meta.function.return-type.rust meta.generic.rust storage.type.rust",
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "Rust function calls",
        "scope": "meta.function.call.rust",
        "settings": {
          "foreground": "${base0D}"
        }
      },
      {
        "name": "Rust angle brackets",
        "scope": "punctuation.brackets.angle.rust",
        "settings": {
          "foreground": "${base15}"
        }
      },
      {
        "name": "Rust constants (ALL_CAPS)",
        "scope": "constant.other.caps.rust",
        "settings": {
          "foreground": "${base09}"
        }
      },
      {
        "name": "Rust function parameters",
        "scope": "meta.function.definition.rust variable.other.rust",
        "settings": {
          "foreground": "${base12}"
        }
      },
      {
        "name": "Rust closure variables",
        "scope": "meta.function.call.rust variable.other.rust",
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "name": "Rust self",
        "scope": "variable.language.self.rust",
        "settings": {
          "foreground": "${base08}"
        }
      },
      {
        "name": "Rust metavariable names",
        "scope": [
          "variable.other.metavariable.name.rust",
          "meta.macro.metavariable.rust keyword.operator.macro.dollar.rust"
        ],
        "settings": {
          "foreground": "${base17}"
        }
      },
      {
        "name": "Shell shebang",
        "scope": [
          "comment.line.shebang",
          "comment.line.shebang punctuation.definition.comment",
          "punctuation.definition.comment.shebang.shell",
          "meta.shebang.shell"
        ],
        "settings": {
          "foreground": "${base17}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Shell shebang command",
        "scope": "comment.line.shebang constant.language",
        "settings": {
          "foreground": "${base0C}",
          "fontStyle": "italic"
        }
      },
      {
        "name": "Shell interpolated command punctuation",
        "scope": [
          "meta.function-call.arguments.shell punctuation.definition.variable.shell",
          "meta.function-call.arguments.shell punctuation.section.interpolation"
        ],
        "settings": {
          "foreground": "${base08}"
        }
      },
      {
        "name": "Shell interpolated command variable",
        "scope": "meta.string meta.interpolation.parameter.shell variable.other.readwrite",
        "settings": {
          "foreground": "${base09}",
          "fontStyle": "italic"
        }
      },
      {
        "scope": [
          "source.shell punctuation.section.interpolation",
          "punctuation.definition.evaluation.backticks.shell"
        ],
        "settings": {
          "foreground": "${base0C}"
        }
      },
      {
        "name": "Shell heredoc EOF",
        "scope": "entity.name.tag.heredoc.shell",
        "settings": {
          "foreground": "${base0E}"
        }
      },
      {
        "name": "Shell quoted variable",
        "scope": "string.quoted.double.shell variable.other.normal.shell",
        "settings": {
          "foreground": "${base05}"
        }
      },
      {
        "scope": "markup.heading.typst",
        "settings": {
          "foreground": "${base08}"
        }
      }
    ]
  }
''
