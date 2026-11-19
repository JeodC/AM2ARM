// Use this location's assigned item for its pickup graphic and message.
itemid = 205;
itemidOriginal = itemid;
itemid = oControl.mod_205;
if (oControl.mod_205 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();
