/// @description  load_stats()
function load_stats2() {
	var header;
	filename = "extras.sav";
	// Decode a temporary copy of the extra unlock records.
	if (os_is_native) {
	    file_copy(filename, filename + "d");
	    crypt(filename + "d", "XOR_DFJykQ8xX3PuNnkLt6QviqALOLF8cxIDx1D63DAdph4KGQ4rOJ7", 2);
	    fid = file_text_open_read(filename + "d");
	} else fid = file_text_open_read(filename);
	header = rc4(file_text_read_string(fid), "HEADER_KEY");
	file_text_readln(fid);
	// Reject an unexpected records header; otherwise restore the extras section.
	if (header != "[AM2R UnlockData V7.0]") {
	    file_text_close(fid);
	    show_message_async("Save Data Corrupted");
	    file_delete(filename + "d");
	    file_delete(filename);
	    room_goto(titleroom);
	} else {
	    data_load_extras(fid);
	    file_text_readln(fid);
	    file_text_close(fid);
	    file_delete(filename + "d");
	}



}
