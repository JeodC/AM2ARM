// Remove this placed pickup; the room supplies the actual item separately.
instance_destroy();
itemid = 53;
itemidOriginal = itemid;
itemid = oControl.mod_53;
if (oControl.mod_53 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();