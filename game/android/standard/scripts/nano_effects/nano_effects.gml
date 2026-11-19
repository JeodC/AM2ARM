// Nano changes cosmetic work only. Call after the original particle creation
// and initialization so its random draws remain in the gameplay RNG sequence.
function nano_serris_bubble(_bubble) {
    if (!global.nano_enabled || !instance_exists(_bubble)) return;
    global.nano_serris_counter = (global.nano_serris_counter + 1) mod 8;
    if (global.nano_serris_counter != 0) {
        instance_destroy(_bubble);
        return;
    }
    var _slot = global.nano_serris_cursor;
    var _previous = global.nano_serris_bubbles[_slot];
    if (instance_exists(_previous)) instance_destroy(_previous);
    global.nano_serris_bubbles[_slot] = _bubble;
    global.nano_serris_cursor = (_slot + 1) mod 12;
    _bubble.alarm[0] = min(_bubble.alarm[0], 45);
}

// Boost trails use the same quota as every other Serris bubble emitter.
// A discarded trail needs its original random draws, but no engine instance.
// Keep this sequence aligned with oLBubble Create and the two boost callers;
// native replay checks compare surviving particles and the next RNG values.
function nano_serris_trail_create(_x, _y) {
    if (!global.nano_enabled || global.nano_serris_counter == 7)
        return instance_create(_x, _y, oLBubble);
    var _frame = choose(0, 1);
    var _lifetime = 120 + random(500);
    if (_y >= global.waterlevel + global.wateroffset + 6) {
        var _angle = irandom_range(-35, 35);
        var _trail_lifetime = 10 + irandom_range(0, 20);
        global.nano_serris_counter = (global.nano_serris_counter + 1) mod 8;
    }
    return noone;
}

function nano_impact_spark(_spark) {
    if (!global.nano_enabled || !instance_exists(_spark)) return;
    global.nano_impact_counter = (global.nano_impact_counter + 1) mod 4;
    if (global.nano_impact_counter != 0) instance_destroy(_spark);
}

function nano_quality_policy() {
    return global.nano_enabled ? "nano-light-water-v1" : "full-no-nano";
}

function nano_option_text(_key, _fallback) {
    var _text = get_text("OptionsDisplay", _key);
    return _text == "[!]" ? _fallback : _text;
}
