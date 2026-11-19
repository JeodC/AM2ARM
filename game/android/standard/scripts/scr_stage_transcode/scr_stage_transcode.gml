/// Validate a complete plaintext V7 save, then transcode its numeric lists.
function scr_stage_transcode(fname, targetver, save_name) {
    // Choose the required sections from the staged slot or records filename.
    var counts, header, is_slot = false;
    var suffix = string_copy(save_name, string_length(save_name) - 4, 5);
    if (suffix == "save1" || suffix == "save2" || suffix == "save3") {
        counts = [50, 350, 350, 100, 20, 100, 50, 6400, 120, 8];
        header = "[AM2R SaveData V7.0]";
        is_slot = true;
    } else if (string_copy(save_name, string_length(save_name) - 7, 8) == "data.sav") {
        counts = [50, 50, 100, 100];
        header = "[AM2R UnlockData V7.0]";
    } else if (string_copy(save_name, string_length(save_name) - 9, 10) == "extras.sav") {
        counts = [20];
        header = "[AM2R UnlockData V7.0]";
    } else return 0;

    // Read exactly the expected lines and validate the header before converting any section.
    var expected_lines = 1 + array_length(counts) + real(is_slot);
    var lines = [], fd = file_text_open_read(fname);
    if (fd < 0) return 0;
    while (!file_text_eof(fd) && array_length(lines) <= expected_lines) {
        array_push(lines, file_text_read_string(fd));
        file_text_readln(fd);
    }
    file_text_close(fd);
    if (array_length(lines) != expected_lines) return 0;
    if (rc4(lines[0], "HEADER_KEY") != header) return 0;
    for (var n = 0; n < array_length(counts); n++) {
        var converted = scr_dslist_transcode(lines[n + 1], targetver, counts[n]);
        if (!is_string(converted)) return 0;
        lines[n + 1] = converted;
    }
    // The optional randomizer seed is the only non-list line. Empty is normal.
    if (is_slot) {
        var seed_line = lines[expected_lines - 1];
        var seed_text = base64_decode(seed_line);
        if (base64_encode(seed_text) != seed_line || string_length(seed_text) > 32) return 0;
        if (seed_text != "") {
            try {
                var seed_value = real(seed_text);
                if (is_nan(seed_value) || is_infinity(seed_value)) return 0;
            } catch (error) { return 0; }
        }
    }
    // Rewrite the stage only after every list and the optional seed pass validation.
    fd = file_text_open_write(fname);
    if (fd < 0) return 0;
    for (var n = 0; n < array_length(lines); n++) {
        file_text_write_string(fd, lines[n]);
        file_text_writeln(fd);
    }
    file_text_close(fd);
    return 1;
}
