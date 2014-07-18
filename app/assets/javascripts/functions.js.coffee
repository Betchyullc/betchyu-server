@showMainBlock = (element) ->
  element.attr "style", ""
  element.show()
  element.addClass "off-right"
  element.animate { left : "33%"}, 500
