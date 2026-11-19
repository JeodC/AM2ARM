// Use this location's assigned item for its pickup graphic and message.
itemid = 151;
itemidOriginal = itemid;
itemid = oControl.mod_151;
if (oControl.mod_151 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();