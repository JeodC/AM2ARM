// Remove this placed pickup; the room supplies the actual item separately.
instance_destroy();
itemid = 52;
itemidOriginal = itemid;
itemid = oControl.mod_52;
if (oControl.mod_52 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();