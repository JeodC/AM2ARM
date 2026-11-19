// Reveal these hidden block types even when this blast does not break them.
with (other) if (sprite_index == sBlockStep || sprite_index == sBlockScrew || sprite_index == sBlockPBomb || sprite_index == sBlockMissile || sprite_index == sBlockSMissile || sprite_index == sBlockSpeed) {
    event_user(1);
    visible = true;
}

