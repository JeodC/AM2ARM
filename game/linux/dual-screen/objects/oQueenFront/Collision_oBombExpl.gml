// A bomb detonating while Samus is inside the Queen routes stomach damage to the head's health handler.
if (other.image_index == 1 && oCharacter.state == 55 && instance_number(oQueenFinalExplosion) == 0) with (oQueenHead) event_user(3);

