// Use this location's assigned item for its pickup graphic and message.
itemid = 204;
itemidOriginal = itemid;
itemid = oControl.mod_204;
if (oControl.mod_204 != itemidOriginal) { src_items_rando(itemid); }
scr_item_create_text();
