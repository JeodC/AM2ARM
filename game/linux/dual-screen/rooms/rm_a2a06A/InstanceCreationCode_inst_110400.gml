// Use this location's assigned item for its pickup graphic and message.
itemid = 159;
itemidOriginal = itemid;
itemid = oControl.mod_159;
if (oControl.mod_159 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();
