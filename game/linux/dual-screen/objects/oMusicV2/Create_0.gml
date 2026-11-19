currentbgm = musTitle;
previousbgm = 254;
bossbgm = sndJump;
sound_id = 0;

useMultistageMusic = 0;

if (audio_exists(musQueenBreak) and audio_exists(musQueen2) and audio_exists(musQueen3)) {
    useMultistageMusic = 1;
}

