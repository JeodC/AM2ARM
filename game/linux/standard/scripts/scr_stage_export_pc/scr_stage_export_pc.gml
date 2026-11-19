/// @description  scr_stage_export_pc(filename) -> 1 staged PC-format, 0 missing, -1 failure
function scr_stage_export_pc(argument0) {
	// Backups go out in OFFICIAL PC format so a backup folder can be dropped
	// straight into the PC build's save directory. The PC build XORs saves
	// with a keystream seeded from ITS game_id (971912648), this build from
	// its own. Convert a staged copy -- never the live file -- and the Java
	// side exports only these validated "backupstage_<name>" files.
	// Restore auto-detects both formats (scr_stage_normalize), so
	// Android-to-Android round trips are unaffected.
	var fname = argument0;
	var stage = "backupstage_" + fname;
	var xorkey = "XOR_DFJykQ8xX3PuNnkLt6QviqALOLF8cxIDx1D63DAdph4KGQ4rOJ7";
	// Always clear the previous stage first: a stale copy of a since-deleted
	// save must never ride along in a new backup.
	if (file_exists(stage)) file_delete(stage);
	if (!file_exists(fname)) return 0;

	file_copy(fname, stage);
	if (!file_exists(stage)) return -1;
	crypt(stage, xorkey, 2);
	var fid = file_text_open_read(stage);
	var header = rc4(file_text_read_string(fid), "HEADER_KEY");
	file_text_close(fid);
	if (header != "[AM2R SaveData V7.0]" && header != "[AM2R UnlockData V7.0]") {
	    // Abort this backup; never claim that an unreadable file is portable.
	    file_delete(stage);
	    return -1;
	}
	// stage now holds plaintext -- transcode the ds_list payload to the PC
	// build's format (GMS1.4 reads only version 302; this runtime writes 303
	// with typed bool/ref entries), then re-encrypt with the PC keystream
	if (!scr_stage_transcode(stage, 302, fname)) {
	    file_delete(stage);
	    return -1;
	}
	crypt_gmid(stage, xorkey, 2, "971912648");
	return 1;
}
