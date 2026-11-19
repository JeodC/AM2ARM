// Use this location's assigned item for its pickup graphic and message.
itemid = 58;
itemidOriginal = itemid;
itemid = oControl.mod_58;
if (oControl.mod_58 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();