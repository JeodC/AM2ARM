// Replace menu music with the ending track played once.
mus_stop(musTitle);
mus_stop(musCredits);
mus_play_once(musEnding);

// Enable the room view used by the widescreen renderer.
if (oControl.widescreen) {
    view_enabled = true;
    __view_set( e__VW.Visible, 0, true );   
}