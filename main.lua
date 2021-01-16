--[[ 
  midi hardware sampler helper
  
  @dogsplusplus
]]

require"gui"

renoise.tool():add_menu_entry {
  name = "Sample Editor:Record Samples From MIDI Hardware",
  invoke = show_menu
}
