// Return the credits to the default palette instead of carrying the gameplay palette swap.
if (oControl.shader_on) {
    oControl.palette_number = 0;
    oControl.shader_on = false;
}