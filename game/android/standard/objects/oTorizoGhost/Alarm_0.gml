// Refresh the chase target periodically, so the ghost steers toward a recently sampled position.
if (state == 1) {
    targetx = oCharacter.x - 20 + random(20);
    targety = oCharacter.y - random(40);
}
alarm[0] = 50;

