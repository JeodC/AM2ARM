/// @description  skorp_get_lure(sprite);
/// @param sprite
function skorp_get_lure(argument0) {
	var spr = argument0;
	// Choose the area-specific lure artwork from the room name, retaining the supplied sprite elsewhere.
	var area = string_char_at(room_get_name(room), 5) + string_char_at(room_get_name(room), 6);

	switch area {
	    case "6a": {
	        return asset_get_index(sprite_get_name(spr) + "A6");
	        break;
	    }
	    case "6b": {
	        return asset_get_index(sprite_get_name(spr) + "A6b");
	        break;
	    }
	    default: {
	        return spr;
	        break;
	    }
	}



}
