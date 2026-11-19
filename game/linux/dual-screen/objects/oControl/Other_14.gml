if (surface_exists(screen_surface)) {
    surface_free(screen_surface);
}
if (os_is_native) {
    // This event fires EVERY frame from oControl Step in nearly every room. The old
    // file_exists(working_directory + "/tempscr") here was the per-frame "Failed to find
    // asset:/tempscr" flood on Android (file_exists logs a failed-asset lookup on a miss).
    // Only touch the disk when we actually wrote a freeze-frame.
    if (tempscr_written) {
        if (os_type == os_linux) {
            if (buffer_exists(tempscr_buffer)) buffer_delete(tempscr_buffer);
            tempscr_buffer = -1;
        } else {
            file_delete("tempscr.buf");
        }
        tempscr_written = false;
    }
}

