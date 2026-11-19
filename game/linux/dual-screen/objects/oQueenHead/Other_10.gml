if !(oCharacter.state == oCharacter.GRABBEDQUEENBELLY && instance_exists(oPBomb)) myhealth -= dmg;
flashing = flashtime;
// Turn a depleted health bar into the next arena phase, or the final death in the last phase.
if (myhealth <= 0 && state != 100 && state != 50) {
    if (oQueen.phase < 3) head_damage = 1;
    if (oQueen.phase == 3) head_damage = 2;
    if (oQueen.phase < 5) {
        state = 50;
        statetime = 0;
        myhealth = 999999;
        with (oQueen) {
            state = 6;
            statetime = 0;
        }
    }
    if (oQueen.phase == 5) {
        with (oQueen) {
            state = 100;
            statetime = 0;
        }
        state = 100;
    }
}

