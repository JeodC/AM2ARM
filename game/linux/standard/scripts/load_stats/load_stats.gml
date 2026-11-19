/// @description  load_stats()
function load_stats() {
	var header;
	// Reset player and map defaults before reading the shared records file.
	load_character_vars();
	reset_map();
	init_map();
	filename = "data.sav";
	if (os_is_native) {
	    file_copy(filename, filename + "d");
	    crypt(filename + "d", "XOR_DFJykQ8xX3PuNnkLt6QviqALOLF8cxIDx1D63DAdph4KGQ4rOJ7", 2);
	    fid = file_text_open_read(filename + "d");
	} else fid = file_text_open_read(filename);
	header = rc4(file_text_read_string(fid), "HEADER_KEY");
	file_text_readln(fid);
	// Use the existing corruption path if the records header is unexpected.
	if (header != "[AM2R UnlockData V7.0]") {
	    file_text_close(fid);
	    show_message_async("Save Data Corrupted");
	    file_delete(filename + "d");
	    file_delete(filename);
	    room_goto(titleroom);
	} else {
	    // Restore the shared record sections in their saved order.
	    sv_get_unlocks(fid);
	    file_text_readln(fid);
	    sv_get_gallery(fid);
	    file_text_readln(fid);
	    sv_get_stats(fid);
	    file_text_readln(fid);
	    sv_get_achievements(fid);
	    file_text_readln(fid);
	    //data_load_extras(fid);
	    //file_text_readln(fid);
	    file_text_close(fid);
	    file_delete(filename + "d");
	}



}
