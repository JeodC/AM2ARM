/// @description  spawn_rnd_pickup_at(x, y, chance)
function spawn_rnd_pickup_at(argument0, argument1, argument2) {
	// Roll a pickup at the supplied point using current supplies and on-screen pickup limits.
	if (random(100) <= argument2) {
	    if(sprite_index != sQueenProjFrozen) xParasite = noone; // GM2026: was a joke-string sentinel; instance_exists() is strict-typed now and crashes on a string, so use the numeric no-instance constant (instance_exists(noone)==false)

	    pickup = irandom(3);

	    var spawnX = 0;
	    if((global.playerhealth == global.maxhealth) && (global.missiles == global.maxmissiles) && (global.smissiles == global.maxsmissiles)) {
	        spawnX = irandom(1); // 50% chance to Spawn an X even if health and missles are full.
	    }
    
    
	    if (pickup == 0) {
	        if ((global.playerhealth < global.maxhealth && instance_number(oHPickup) < 6) || (oControl.mod_fusion == 1 && spawnX == 1 && canbeX && instance_number(oHPickup) < 6)) {
	            if(oControl.mod_fusion == 1 && canbeX == 1) {
	                xParasite = instance_create(argument0, argument1, oHXPickup);
	            }
	            else instance_create(argument0, argument1, oHPickup);
	        } else pickup = 2;
	    }
	    if (pickup == 1) {
	        if ((global.playerhealth < global.maxhealth && instance_number(oHPickupBig) < 3) || (oControl.mod_fusion == 1 && spawnX == 1 && canbeX && instance_number(oHPickupBig) < 3)) {
	            if(oControl.mod_fusion == 1 && canbeX == 1) {
	                xParasite = instance_create(argument0, argument1, oHXPickupBig);
	            }
	            else instance_create(argument0, argument1, oHPickupBig);
	        } else pickup = 2;
	    }
	    if (pickup == 2) {
	        if ((global.missiles < global.maxmissiles && global.maxmissiles > 0 && instance_number(oMPickup) < 8) || (oControl.mod_fusion == 1 && spawnX == 1 && canbeX && instance_number(oMPickup) < 8)) {
	            if(oControl.mod_fusion == 1 && canbeX == 1) {
	                xParasite = instance_create(argument0, argument1, oMXPickup);
	            }
	            else instance_create(argument0, argument1, oMPickup);
	        } else pickup = 3;
	    }
	    if (pickup == 3) {
	        if (global.smissiles < global.maxsmissiles && global.maxsmissiles > 0 && instance_number(oSMPickup) < 2) {
	            if(oControl.mod_fusion == 1 && canbeX == 1) {
	                xParasite = instance_create(argument0, argument1, oSMXPickup);
	            }
	            else instance_create(argument0, argument1, oSMPickup);
	        } else if ((global.item[0] == 0 && global.maxpbombs > 0) || oControl.mod_insanitymode == 1) pickup = 4;
	    }
	    // Start a spawned X parasite in its release animation with reforming disabled.
	    if (sprite_index != sQueenProjFrozen && instance_exists(xParasite) && oControl.mod_fusion == 1) {
	        PlaySoundMono(sndXMorph2);
	        xParasite.reform = -1;
	        xParasite.sizeX = 5.8;
	        xParasite.sizeY = 4.2;
	        xParasite.state = 1;
	        xParasite.statetime = 40;
	        xParasite.counter = 0;
        
	        if (sprite_index == sHalzynBodyFrozen) {
	            xParasite.lastEnemyGlow = glow;
	        }
        
	        return xParasite;
	    }
	}



}
