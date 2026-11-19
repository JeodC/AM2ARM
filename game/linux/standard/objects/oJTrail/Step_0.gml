if (oCharacter.state == 15) {
    // Leave a short history of positions behind the spinning jump, then fade it away.
    for (var _trail_index = 7; _trail_index > 0; --_trail_index) {
        sx[_trail_index] = sx[_trail_index - 1];
    }
    sx[0] = x;
    for (var _trail_index = 7; _trail_index > 0; --_trail_index) {
        sy[_trail_index] = sy[_trail_index - 1];
    }
    sy[0] = y;
    x = oCharacter.x;
    y = oCharacter.y;
    if (image_alpha > 0) {
        image_alpha -= 0.1;
    } else instance_destroy();
    if (images < 8) images += 1;
} else instance_destroy();

