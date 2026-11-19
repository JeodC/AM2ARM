/// @description  damage_player_knockdown(damage, facing, inv_frames, ignore_armor, knockback_x)
function damage_player_knockdown(argument0, argument1, argument2, argument3, argument4) {
	var damage_taken;
	// Scale the hit by difficulty and suit protection before changing the player.
	if (global.currentsuit == 0 || argument3 == 1) damage_taken = argument0 * oControl.mod_diffmult;
	if (argument3 == 0) {
	    if (global.currentsuit == 1) damage_taken = ceil(argument0 * 0.5) * oControl.mod_diffmult; //((global.difficulty == 2) + 1);
	    //if (global.currentsuit == 2) damage_taken = ceil(argument0 * 0.25) * oControl.mod_diffmult; //((global.difficulty == 2) + 1);
	    if (global.currentsuit == 2) {                                                     
	        if(global.item[5] == 0) 
	            damage_taken = ceil(argument0 * 0.5) * oControl.mod_diffmult;
	        else                   
	            damage_taken = ceil(argument0 * 0.25) * oControl.mod_diffmult;
	    } //added
	}
	if (global.godmode) damage_taken = 0;
	// These collision callers supply the player as other; switch to that instance to apply the hit.
	if (global.playerhealth > 0) with (other) {
	    if (state != 39 && walljumping == 0) {
	        if (canbehit) {
	            // A ball-shaped player uses the hurt bounce; an upright player enters the knockdown sequence.
	            if (state == BALL || state == AIRBALL || state == SPIDERBALL || (state == SUPERJUMP || state == SJSTART || state == SJEND) && sjball == 1) {
	                sjball = 1;
	                fixedx = 8;
	                sball = 0;
	                state = HURT;
	                canturn = 0;
	                if (other.x >= x) xVel = -argument4;
	                if (other.x < x) xVel = argument4;
	                yVel = -3;
	            } else {
	                sjball = 0;
	                state = 39;
	                if (argument1 == 1) {
	                    facing = LEFT;
	                    xVel = argument4;
	                }
	                if (argument1 == -1) {
	                    facing = RIGHT;
	                    xVel = -argument4;
	                }
	            }
	            image_index = 0;
	            statetime = 0;
	            sfx_play(sndHurt);
	            invincible = argument2;
	            ctrl_vibrate(1, 1, 15);
	            if (inwater) {
	                repeat (3 + floor(random(3))) {
	                    bubble = instance_create(x, y - 6 - random(20), oLBubble);
	                    if (instance_exists(bubble)) {
	                        bubble.hspeed = 1 - random(2);
	                        bubble.vspeed = -0.1 - random(1);
	                    }
	                }
	            }
	            global.playerhealth -= damage_taken;
	        } // if (canbehit)
	    } // if (state != 39 && walljumping == 0)
	    // Schedule the player death transition if this hit exhausts health.
	    if (global.playerhealth <= 0 && state != DEFEATED) {
	        alarm[0] = 6;
	        state = DEFEATED;
	    }
	} // if (global.playerhealth > 0)



}
