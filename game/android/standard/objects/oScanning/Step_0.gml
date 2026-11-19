if (!fadeout) {
    if(!instance_exists(oNotification) && moreThanOne == false) {
        if (image_alpha < 1) image_alpha += 0.1;
    }
    // Wait behind the current notification or earlier scan without consuming the scan delay.
    else {
        alarm[0] += 1;
        if (instance_number(object_index) == 1) moreThanOne = false;
    }
} else if (image_alpha > 0) {
    image_alpha -= 0.1;
} else event_user(0);

