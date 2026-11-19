// Enable the room view used by the widescreen renderer.
if (oControl.widescreen) {
    view_enabled = true;
    __view_set( e__VW.Visible, 0, true );   
}
// Pause gameplay sound loops while the death screen is displayed.
Mute_Loops();