// Match the original 60 Hz intro cues to the playing track, even on a late frame.
function title_sequence_step() {
    var _now = get_timer();
    var _clock = statetime + clamp((_now - sequence_last_us) * 60 / 1000000, 0, 15);
    sequence_last_us = _now;
    var _voice = oControl.title_music_voice;
    if (_voice >= 0 && (audio_is_playing(_voice) || audio_is_paused(_voice)))
        _clock = audio_sound_get_track_position(_voice) * 60;
    _clock = max(statetime, _clock);
    var _advance = _clock - statetime;
    canskip = _clock >= 60;
    if (!active) {
        var _skip = canskip && ((oControl.kMenu1 && oControl.kMenu1PushedSteps == 1)
            || (oControl.kMenu2 && oControl.kMenu2PushedSteps == 1)
            || (oControl.kStart && oControl.kStartPushedSteps == 1));
        if (_skip || _clock >= 1600) {
            active = 1;
            sequence_reveal = _skip ? _clock : 1600;
            if (instance_exists(oPressStart)) instance_find(oPressStart, 0).visible = true;
            if (instance_exists(oDrawTitleBG)) instance_find(oDrawTitleBG, 0).fadein = 1;
            if (instance_exists(oTitleText1)) instance_destroy(instance_find(oTitleText1, 0));
            if (instance_exists(oTitleText2)) instance_destroy(instance_find(oTitleText2, 0));
        } else {
            title_sequence_caption(oTitleText1, _clock - 300, 300);
            title_sequence_caption(oTitleText2, _clock - 900, 500);
        }
    }
    bgyoff = min(400, bgyoff + _advance * 0.25);
    if (active) {
        bgyoff = lerp(bgyoff, 400, 1 - power(0.98, _advance));
        if (instance_exists(oDrawTitleBG)) {
            var _title = instance_find(oDrawTitleBG, 0);
            if (!_title.fadeout && sequence_reveal >= 0)
                _title.image_alpha = clamp((_clock - sequence_reveal) * 0.05, 0, 1);
        }
    }
    statetime = _clock;
}

function title_sequence_caption(_object, _age, _hold) {
    if (_age < 0 || _age >= _hold + 50) {
        if (instance_exists(_object)) instance_destroy(instance_find(_object, 0));
        return;
    }
    if (!instance_exists(_object)) instance_create(160, 120, _object);
    var _caption = instance_find(_object, 0);
    _caption.statetime = _age;
    _caption.image_alpha = clamp(min(_age * 0.05, 1 - (_age - _hold) * 0.02), 0, 1);
}
