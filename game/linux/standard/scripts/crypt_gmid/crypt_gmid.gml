/// @description  crypt_gmid(file, encryption_key, rate, gmid_string)
function crypt_gmid(argument0, argument1, argument2, argument3) {
	// crypt() with the game_id string as a parameter instead of the builtin.
	// The XOR keystream is seeded from game_id, so files written by a build
	// with a different id (the official PC release: "971912648") need that
	// build's id to decrypt. Body is otherwise a verbatim copy of crypt() --
	// every quirk (index-0 clamps, wrap-to-1) is part of the on-disk format.
	if (!file_exists(argument0)) return -1;
	var keypos = 0;
	var gmid = argument3;
	var key = "";
	var read = 0;
	var file = 0;
	var epos = 0;
	var rate = min(argument2, 10);
	rate = max(rate, 0);
	repeat (5) gmid += gmid;
	epos = 0;
	var keys;
	repeat (floor(string_length(argument3) * 5)) {
	    keys[epos] = ord(string_copy(gmid, epos, 2)) ^ ord(string_char_at(argument1, keypos)) - floor(epos / 3);
	    keypos += 1;
	    if (keypos > string_length(argument1)) keypos = 1;
	    epos += 1;
	}
	epos -= 1;
	keypos = 0;
	file = file_bin_open(argument0, 2);
	file_bin_seek(file, 0);
	var filesize = file_bin_size(file);
	rate *= filesize / 10000;
	rate = round(rate);
	do {
	    read = file_bin_read_byte(file);
	    file_bin_seek(file, file_bin_position(file) - 1);
	    file_bin_write_byte(file, read ^ keys[keypos]);
	    keypos += 1;
	    if (keypos > epos) keypos = 1;
	    if (rate) file_bin_seek(file, file_bin_position(file) + rate);
	} until (file_bin_position(file) >= filesize);
	file_bin_close(file);
	return 1;
}
