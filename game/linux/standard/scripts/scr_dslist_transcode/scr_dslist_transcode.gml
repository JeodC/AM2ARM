/// @description  scr_dslist_transcode(b64line, targetver, expected_count) -> converted string or -1 invalid
function scr_dslist_transcode(_b64line, _target_version, expected_count) {
	// Rewrites one save-file line (base64 of an UPPERCASE-hex ds_list dump)
	// to the target ds_list version. The two runtimes serialize the same
	// container, but GM2026 writes version 303 and leaks its richer RValue
	// typing into entries, which the official PC build (GMS1.4, version 302,
	// entry types 0/1 only) cannot read:
	//   type 13 = bool, payload is already the f64 image of the value
	//   type 15 = asset ref (save_room), payload lo u32 = asset index
	// Both coerce losslessly to type 0 reals; everything else is
	// byte-identical between the builds.
	// V7 save lists contain only finite numbers. Expected list lengths come
	// from the slot/records schema; malformed or unsupported blobs fail closed.
	var hexs = base64_decode(_b64line);
	var hlen = string_length(hexs);
	if (base64_encode(hexs) != _b64line || hlen < 16 || (hlen & 1)) return -1;

	// hex text -> raw bytes
	var n = hlen >> 1;
	var src = buffer_create(n, buffer_fixed, 1);
	var i = 1;
	repeat (n) {
	    var h = string_byte_at(hexs, i);
	    var l = string_byte_at(hexs, i + 1);
	    if (h >= 48 && h <= 57) h -= 48;
	    else if (h >= 65 && h <= 70) h -= 55;
	    else { buffer_delete(src); return -1; }
	    if (l >= 48 && l <= 57) l -= 48;
	    else if (l >= 65 && l <= 70) l -= 55;
	    else { buffer_delete(src); return -1; }
	    buffer_write(src, buffer_u8, (h << 4) | l);
	    i += 2;
	}

	// Require a supported list format and the exact number of entries for this save section.
	buffer_seek(src, buffer_seek_start, 0);
	var ver = buffer_read(src, buffer_u32);
	if (ver != 302 && ver != 303) {
	    buffer_delete(src);
	    return -1;
	}
	var cnt = buffer_read(src, buffer_u32);
	if (cnt != expected_count) { buffer_delete(src); return -1; }
	var dst = buffer_create(n, buffer_fixed, 1);
	buffer_write(dst, buffer_u32, _target_version);
	buffer_write(dst, buffer_u32, cnt);
	var fail = 0;
	// Convert supported numeric entries while rejecting truncated or non-finite values.
	repeat (cnt) {
	    if (buffer_tell(src) + 4 > n) { fail = 1; break; }
	    var t = buffer_read(src, buffer_u32);
	    if (t == 0 || t == 13 || t == 15) {
	        if (buffer_tell(src) + 8 > n) { fail = 1; break; }
	        if (t == 15) {
	            var lo = buffer_read(src, buffer_u32);
	            buffer_read(src, buffer_u32);
	            buffer_write(dst, buffer_u32, 0);
	            buffer_write(dst, buffer_f64, lo);
	        } else {
	            var value_pos = buffer_tell(src);
	            var value = buffer_read(src, buffer_f64);
	            if (is_nan(value) || is_infinity(value)) { fail = 1; break; }
	            buffer_seek(src, buffer_seek_start, value_pos);
	            buffer_write(dst, buffer_u32, 0);
	            buffer_write(dst, buffer_u64, buffer_read(src, buffer_u64));
	        }
	    } else {
	        fail = 1;
	        break;
	    }
	}
	// Reject trailing data and release both buffers before reporting a failed conversion.
	if (!fail && buffer_tell(src) != n) fail = 1;
	if (fail) {
	    buffer_delete(src);
	    buffer_delete(dst);
	    return -1;
	}

	// raw bytes -> hex text (uppercase, matching ds_list_write)
	var txt = buffer_create(hlen + 1, buffer_fixed, 1);
	buffer_seek(dst, buffer_seek_start, 0);
	repeat (n) {
	    var b = buffer_read(dst, buffer_u8);
	    var nh = b >> 4;
	    var nl = b & 15;
	    buffer_write(txt, buffer_u8, nh + ((nh < 10) ? 48 : 55));
	    buffer_write(txt, buffer_u8, nl + ((nl < 10) ? 48 : 55));
	}
	buffer_write(txt, buffer_u8, 0);
	buffer_seek(txt, buffer_seek_start, 0);
	var outhex = buffer_read(txt, buffer_string);
	buffer_delete(src);
	buffer_delete(dst);
	buffer_delete(txt);
	return base64_encode(outhex);



}
