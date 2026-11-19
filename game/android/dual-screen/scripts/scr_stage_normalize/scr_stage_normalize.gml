/// Staged Android or official PC 1.5.5 save -> 1 valid native, 0 missing, -1 invalid.
function scr_stage_normalize(fname) {
    if (!file_exists(fname)) return 0;
    var probe = fname + "p";
    var key = "XOR_DFJykQ8xX3PuNnkLt6QviqALOLF8cxIDx1D63DAdph4KGQ4rOJ7";
    // Validate the whole file with either keystream. A matching header alone
    // cannot distinguish damaged or partially converted large saves.
    for (var source = 0; source < 2; source++) {
        file_delete(probe);
        file_copy(fname, probe);
        if (!file_exists(probe)) return -1;
        if (source == 0) crypt(probe, key, 2);
        else crypt_gmid(probe, key, 2, "971912648");
        if (scr_stage_transcode(probe, 303, fname)) {
            crypt(probe, key, 2);
            // Only the disposable stage is replaced; live saves are untouched.
            file_delete(fname);
            file_copy(probe, fname);
            file_delete(probe);
            return file_exists(fname) ? 1 : -1;
        }
    }
    file_delete(probe);
    return -1;
}
