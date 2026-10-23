function update()
  noctalia.setUpdateInterval(60000)
  barWidget.setGlyph("mail")
  barWidget.setTooltip("Manage Fastmail masked emails")
end

function onClick()
  noctalia.togglePanel("craig/maskedemail:manager")
end

function onRightClick()
  onClick()
end
