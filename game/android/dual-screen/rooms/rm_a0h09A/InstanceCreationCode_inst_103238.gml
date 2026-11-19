// Use this location's assigned item for its pickup graphic and message.
itemid = 57;
itemidOriginal = itemid;
itemid = oControl.mod_57;
if (oControl.mod_57 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();