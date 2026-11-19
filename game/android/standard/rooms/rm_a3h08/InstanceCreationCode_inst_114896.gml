// Use this location's assigned item for its pickup graphic and message.
itemid = 214;
itemidOriginal = itemid;
itemid = oControl.mod_214;
if (oControl.mod_214 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();