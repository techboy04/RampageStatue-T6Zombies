#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;

main()
{
	replacefunc(maps\mp\zombies\_zm::round_over, ::new_round_over);
}

init()
{
	create_dvar("rampage_max_round", 20 );
    level thread onPlayerConnect();
	setRagelocation();
	level.rolledstaff = 0;
	level.finishedrampage = 0;
    level thread spawnInducer();
    level thread LoopStaffModels();
    level thread rampageHUD();
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("game_ended");
    for(;;)
    {
        self waittill("spawned_player");
		
		self iprintln("^4Rampage Statue ^7created by ^1techboy04gaming");
		if (level.ragestarted == 1)
		{
			self iprintln("Rampage Statue is activated! Be careful!");
		}
    }
}

create_dvar( dvar, set )
{
    if( getDvar( dvar ) == "" )
		setDvar( dvar, set );
}

startInducer()
{
	level thread show_big_message("Rampage Statue has been activated!", "zmb_laugh_child");
	thread nuke_flash();
	level.ragestarted = 1;
	level thread change_zombies_speed("sprint");
	playfx( level._effect[ "powerup_on" ], (level.effectlocation[0],level.effectlocation[1],level.effectlocation[2]+60) );
	level.zombie_vars[ "zombie_spawn_delay" ] = 0.1;
	
	level.zombie_round_start_delay = 0;
	
	level thread roundChecker();
	level waittill("end_rage");
	thread nuke_flash();
	level thread change_zombies_speed("walk");
	show_big_message("Rampage Statue is satisfied", "zmb_cha_ching");
	if (level.round_number < 20)
	{
		level.zombie_vars[ "zombie_spawn_delay" ] = 2;
	}
	else
	{
		level.zombie_vars[ "zombie_spawn_delay" ] = 1.8;
	}
	level.ragestarted = 0;
	level.finishedrampage = 1;
//	level thread maps/mp/zombies/_zm_powerups::specific_powerup_drop( "full_ammo", level.effectlocation );
}

roundChecker()
{
	while(1)
	{
		if (getDvarInt("rampage_max_round") < level.round_number)
		{
			level notify ("end_rage");
			level notify ("begin_staff_roll");
			break;
		}
		wait 0.5;
	}
}

spawnInducer()
{
	level.ragestarted = 0;
	rampageTrigger = spawn( "trigger_radius", (level.effectlocation), 1, 50, 50 );
	rampageTrigger setHintString("^7Press ^3&&1 ^7to activate Rampage Statuen\nAll zombies will run for a certain amount of rounds");
	rampageTrigger setcursorhint( "HINT_NOICON" );
	rageInducerModel = spawn( "script_model", (level.effectlocation));
	rageInducerModel setmodel ("defaultactor");
	rageInducerModel rotateTo(level.modelangle,.1);
	
	while(1)
	{
		rampageTrigger waittill( "trigger", i );
		if ((level.round_number < getDvarInt("rampage_max_round")) && (level.ragestarted == 0) && (level.finishedrampage == 0))
		{
			if ( i usebuttonpressed() )
			{
				if (level.rampagevoting == 0)
				{
					level.rampagevoting = 1;
					level.exfilplayervotes = 0;
					
					level.exfilplayervotes += 1;
					i.rampagevoted = 1;
					if (level.exfilplayervotes >= level.players.size)
					{
						level.votingsuccess = 1;
						level notify ("voting_finished");
					}
					
					level thread rampageVoteTimer();
					
					foreach ( player in get_players() )
					{
						player thread showrampagevoting(i);
						player thread checkRampageVotingInput();
					}

					if (level.votingsuccess != 1)
					{
						level waittill_any ("voting_finished","voting_expired");
					}
					if (level.votingsuccess == 1)
					{
						level.rampagevoting = 0;
						if (getDvarInt("rampage_max_round") <= 5)
						{
							setDvar("rampage_max_round", 20);
						}
						level thread startInducer();
						rampageTrigger setHintString("The statue is awaiting your worth");
//						break;
					}

				}
			}
		}
		else if ((level.round_number > getDvarInt("rampage_max_round")) && (level.ragestarted == 0) && (level.finishedrampage == 0))
		{
			rampageTrigger setHintString("^7You were too late!");
		}
		else if ((getDvarInt("rampage_max_round") < level.round_number) && (level.finishedrampage == 1))
		{
			rampageTrigger setHintString("^7Press ^3&&1 ^7to pickup a free " + setStaffHintString());
			if ( i usebuttonpressed() )
			{
				reward = getRewardWeapon();
				i maps\mp\zombies\_zm_weapons::weapon_give(reward);
			}
		}
	}
	wait 0.1;
}

rampageHUD()
{
	level endon("end_game");

	rampage_hud = newhudelem();
	rampage_hud.alignx = "left";
	rampage_hud.aligny = "bottom";
	rampage_hud.horzalign = "user_left";
	rampage_hud.vertalign = "user_bottom";
	rampage_hud.x += 10;
	rampage_hud.y -= 60;
	rampage_hud.fontscale = 1;
	rampage_hud.alpha = 1;
	rampage_hud.color = ( 1, 1, 1 );
	rampage_hud.hidewheninmenu = 1;
	rampage_hud.foreground = 1;
	rampage_hud.label = &"Rounds of Rampage Left: ^6";

	while(1)
	{
		if (level.ragestarted == 1)
		{
			rampage_hud.alpha = 1;
		}
		else
		{
			rampage_hud.alpha = 0;
		}
		
		rampage_hud setValue((getDvarInt("rampage_max_round")) - level.round_number );
		
		wait 0.05;
	}
}

checkAmountPlayersRage()
{
	if (level.players.size == 1)
	{
		return true;
	}
	else
	{
		count = 0;
		foreach ( player in level.players )
		{
		if( distance( level.effectlocation, player.origin ) <= 10 )
		    {
	   			count += 1;
	   		}
		}
		if (level.players.size <= count)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
}


showrampageVoting(activator)
{
	self endon( "disconnect" );
	
	level.rampagevoteexec = activator;
	
	hudy = -100;
	
	voting_bg = newClientHudElem(self);
	voting_bg.alignx = "left";
	voting_bg.aligny = "middle";
	voting_bg.horzalign = "user_left";
	voting_bg.vertalign = "user_center";
	voting_bg.x -= 0;
	voting_bg.y = hudy;
	voting_bg.fontscale = 2;
	voting_bg.alpha = 1;
	voting_bg.color = ( 1, 1, 1 );
	voting_bg.hidewheninmenu = 1;
	voting_bg.foreground = 1;
	voting_bg setShader("scorebar_zom_1", 124, 32);
	
	
	voting_text = newClientHudElem(self);
	voting_text.alignx = "left";
	voting_text.aligny = "middle";
	voting_text.horzalign = "user_left";
	voting_text.vertalign = "user_center";
	voting_text.x += 20;
	voting_text.y = hudy + 5;
	voting_text.fontscale = 1;
	voting_text.alpha = 1;
	voting_text.color = ( 1, 1, 1 );
	voting_text.hidewheninmenu = 1;
	voting_text.foreground = 1;
	voting_text.label = &"Timer: ";
	
	voting_target = newClientHudElem(self);
	voting_target.alignx = "left";
	voting_target.aligny = "middle";
	voting_target.horzalign = "user_left";
	voting_target.vertalign = "user_center";
	voting_target.x += 20;
	voting_target.y = hudy - 5;
	voting_target.fontscale = 1;
	voting_target.alpha = 1;
	voting_target.color = ( 1, 1, 1 );
	voting_target.hidewheninmenu = 1;
	voting_target.foreground = 1;
//	voting_target setText ("Press [{+actionslot 4}] to agree on Exfil");
	voting_target setText (activator.name + " wants to Activate the Rampage Statue - [{+actionslot 4}] to accept");
//[{+actionslot 4}]
	
	voting_votes = newClientHudElem(self);
	voting_votes.alignx = "left";
	voting_votes.aligny = "middle";
	voting_votes.horzalign = "user_left";
	voting_votes.vertalign = "user_center";
	voting_votes.x += 20;
	voting_votes.y = hudy + 15;
	voting_votes.fontscale = 1;
	voting_votes.alpha = 1;
	voting_votes.color = ( 1, 1, 1 );
	voting_votes.hidewheninmenu = 1;
	voting_votes.foreground = 1;
	voting_votes.label = &"Votes left: ";
	
	while(1)
	{
		voting_text setValue (level.votingtimer);
		votesLeft = level.players.size - level.exfilplayervotes;
//		votesLeft = getRequirement();
		voting_votes setValue (votesLeft);
		if (self.rampagevoted == 0)
		{
			voting_bg.color = ( 0, 0, 1 );
		}
		else if (self.rampagevoted == 1)
		{
			voting_bg.color = ( 0, 1, 0 );
		}
		
		if (level.rampagevoting == 0)
		{
			voting_target destroy();
			voting_bg destroy();
			voting_text destroy();
			voting_votes destroy();
		}
		wait 0.1;
	}
}

checkRampageVotingInput()
{
	level endon ("voting_finished");
	level endon ("voting_expired");
	
	while(level.rampagevoting == 1 && self.rampagevoted == 0)
	{
		if(self actionslotfourbuttonpressed() || (isDefined(self.bot)))
		{
			level.exfilplayervotes += 1;
			self.rampagevoted = 1;
			if (level.exfilplayervotes >= level.players.size)
			{
				level.votingsuccess = 1;
				level notify ("voting_finished");
			}
		}
		wait 0.1;
	}
}

rampageVoteTimer()
{
	level endon ("voting_finished");
	level endon ("voting_expired");
	level.votingtimer = 15;
	while(1)
	{
		level.votingtimer -= 1;
		if (level.votingtimer < 0)
		{
			level.votingrequirement = 0;
			level.rampageplayervotes = 0;
			foreach (player in get_players())
				player.rampagevoted = 0;
			level.rampagevoting = 0;
			level.votingsuccess = 0;
			level notify ("voting_expired");
		}
		wait 1;
	}
}

checkRampageIfPlayersVoted()
{
	level endon ("voting_finished");
	level endon ("voting_expired");
	level.votingrequirement = int(getRequirement());
	while(1)
	{
		if (level.rampageplayervotes >= level.votingrequirement)
		{
			level.votingsuccess = 1;
			level notify ("voting_finished");
		}
	}
	wait 0.1;
}

checkWeapon()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{
			weapon = "blundergat";
		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{
			weapon = "slowgun";
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			weapon = "raygun_mark2";
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			weapon = "jetgun";
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			weapon = "blundergat";
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			weapon = "slowgun";
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			weapon = "jetgun";
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			weapon = "staff";
		}
		else if(getDvar("mapname") == "zm_highrise") // Die Rise
		{
			weapon = "slipgun";
		}
	}
	
	if (issubstr(self getcurrentweapon(),weapon))
	{
		return false;
	}
	else
	{
		return true;
	}
}

LoopStaffModels()
{
	level waittill ("begin_staff_roll");
	level.staffmodel = spawn( "script_model", (level.effectlocation + (20,0,50)));
	level.staffmodel rotateTo((90,90,180),.1);
	
	if(getDvar("mapname") == "zm_tomb")
	{
		while(1)
		{		
			level.rolledstaff = randomintrange(1, 5);
			if (level.rolledstaff == 1)
			{
				model = ("t6_wpn_zmb_staff_crystal_fire_part");
			}
			else if (level.rolledstaff == 2)
			{
				model = ("t6_wpn_zmb_staff_crystal_air_part");
			}
			else if (level.rolledstaff == 3)
			{
				model = ("t6_wpn_zmb_staff_crystal_bolt_part");
			}
			else if (level.rolledstaff >= 4)
			{
				model = ("t6_wpn_zmb_staff_crystal_water_part");
			}
		
			level.staffmodel setmodel (model);
		
			wait 8;
		}
	}
	else if(getDvar("mapname") == "zm_highrise")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_slipgun_world");
	}
	else if(getDvar("mapname") == "zm_transit")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_jet_gun_world");
	}
	else if(getDvar("mapname") == "zm_prison")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_blundergat_world");
	}
	else if(getDvar("mapname") == "zm_nuked")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_raygun2_world");
	}
	else if(getDvar("mapname") == "zm_buried")
	{
		level.staffmodel setmodel ("t6_wpn_zmb_slowgun_world");
	}
}

getRewardWeapon()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{
			weapon = "blundergat_zm";
		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{
			weapon = "slowgun_zm";
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			weapon = "raygun_mark2_zm";
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			weapon = "jetgun_zm";
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			weapon = "blundergat_zm";
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			weapon = "slowgun_zm";
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			weapon = "jetgun_zm";
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			if (level.rolledstaff == 1)
			{
				weapon = "staff_fire_zm";
			}
			else if (level.rolledstaff == 2)
			{
				weapon = "staff_air_zm";
			}
			else if (level.rolledstaff == 3)
			{
				weapon = "staff_lightning_zm";
			}
			else if (level.rolledstaff >= 4)
			{
				weapon = "staff_water_zm";
			}
		}
		else if(getDvar("mapname") == "zm_highrise")
		{
			weapon = "slipgun_zm";
		}
	}
	return weapon;
}

spawnRewardTrigger()
{
	trigger = spawn( "trigger_radius", (level.effectlocation), 1, 50, 50 );
	level.staffmodel = spawn( "script_model", (level.effectlocation));
	while(1)
	{
		trigger waittill( "trigger", i );
		if ( i GetStance() == "prone" )
		{
			i.score += getDvarInt("bonuspoints_points");
			i playsound( "zmb_cha_ching" );
		}
	}
}

setStaffHintString()
{
	if(getDvar("mapname") == "zm_tomb")
	{
		if (level.rolledstaff == 1)
		{
			return "^1Fire Staff";
		}
		else if (level.rolledstaff == 2)
		{
			return "^3Wind Staff";
		}
		else if (level.rolledstaff == 3)
		{
			return "^6Lighting Staff";
		}
		else if (level.rolledstaff >= 4)
		{
			return "^5Ice Staff";
		}
	}
	else if(getDvar("mapname") == "zm_highrise")
	{
		return "^6Sliquifier";
	}
	else if(getDvar("mapname") == "zm_transit")
	{
		return "^9Jetgun";
	}
	else if(getDvar("mapname") == "zm_prison")
	{
		return "^2Blundergat";
	}
	else if(getDvar("mapname") == "zm_nuked")
	{
		return "^1Raygun Mk 2";
	}
	else if(getDvar("mapname") == "zm_buried")
	{
		return "^5Paralyzer";
	}
}

change_zombies_speed(speedtoset){
	level endon("end_game");
	sprint = speedtoset;
	can_sprint = false;
 	while(true){
 		if (level.ragestarted == 1)
 		{
 			can_sprint = false;
    		zombies = getAiArray(level.zombie_team);
    		foreach(zombie in zombies)
    		if(!isDefined(zombie.cloned_distance))
    			zombie.cloned_distance = zombie.origin;
    		else if(distance(zombie.cloned_distance, zombie.origin) > 15){
    			can_sprint = true;
    			zombie.cloned_distance = zombie.origin;
    			if(zombie.zombie_move_speed == "run" || zombie.zombie_move_speed != sprint)
    				zombie maps\mp\zombies\_zm_utility::set_zombie_run_cycle(sprint);
    		}else if(distance(zombie.cloned_distance, zombie.origin) <= 15){
    			can_sprint = false;
    			zombie.cloned_distance = zombie.origin;
    			zombie maps\mp\zombies\_zm_utility::set_zombie_run_cycle("run");
    		}
    	}
    	wait 0.25;
    }
}

nuke_flash( team )
{
	if ( isDefined( team ) )
	{
		get_players()[ 0 ] playsoundtoteam( "evt_nuke_flash", team );
	}
	else
	{
		get_players()[ 0 ] playsound( "evt_nuke_flash" );
	}
	fadetowhite = newhudelem();
	fadetowhite.x = 0;
	fadetowhite.y = 0;
	fadetowhite.alpha = 0;
	fadetowhite.horzalign = "fullscreen";
	fadetowhite.vertalign = "fullscreen";
	fadetowhite.foreground = 1;
	fadetowhite setshader( "white", 640, 480 );
	fadetowhite fadeovertime( 0.2 );
	fadetowhite.alpha = 1;
	wait 1;
	fadetowhite fadeovertime( 1 );
	fadetowhite.alpha = 0;
	wait 1.1;
	fadetowhite destroy();
}

show_big_message(setmsg, sound)
{
    msg = setmsg;
    players = get_players();

    if ( isdefined( level.hostmigrationtimer ) )
    {
        while ( isdefined( level.hostmigrationtimer ) )
            wait 0.05;

        wait 4;
    }

    foreach ( player in players )
        player thread show_big_hud_msg( msg );
        player playsound(sound);

}

show_big_hud_msg( msg, msg_parm, offset, cleanup_end_game )
{
    self endon( "disconnect" );

    while ( isdefined( level.hostmigrationtimer ) )
        wait 0.05;

    large_hudmsg = newclienthudelem( self );
    large_hudmsg.alignx = "center";
    large_hudmsg.aligny = "middle";
    large_hudmsg.horzalign = "center";
    large_hudmsg.vertalign = "middle";
    large_hudmsg.y -= 130;

    if ( self issplitscreen() )
        large_hudmsg.y += 70;

    if ( isdefined( offset ) )
        large_hudmsg.y += offset;

    large_hudmsg.foreground = 1;
    large_hudmsg.fontscale = 5;
    large_hudmsg.alpha = 0;
    large_hudmsg.color = ( 1, 1, 1 );
    large_hudmsg.hidewheninmenu = 1;
    large_hudmsg.font = "default";

    if ( isdefined( cleanup_end_game ) && cleanup_end_game )
    {
        level endon( "end_game" );
        large_hudmsg thread show_big_hud_msg_cleanup();
    }

    if ( isdefined( msg_parm ) )
        large_hudmsg settext( msg, msg_parm );
    else
        large_hudmsg settext( msg );

    large_hudmsg changefontscaleovertime( 0.25 );
    large_hudmsg fadeovertime( 0.25 );
    large_hudmsg.alpha = 1;
    large_hudmsg.fontscale = 2;
    wait 3.25;
    large_hudmsg changefontscaleovertime( 1 );
    large_hudmsg fadeovertime( 1 );
    large_hudmsg.alpha = 0;
    large_hudmsg.fontscale = 5;
    wait 1;
    large_hudmsg notify( "death" );

    if ( isdefined( large_hudmsg ) )
        large_hudmsg destroy();
}

show_big_hud_msg_cleanup()
{
    self endon( "death" );

    level waittill( "end_game" );

    if ( isdefined( self ) )
        self destroy();
}

setRagelocation()
{
	if ( getDvar( "g_gametype" ) == "zgrief" || getDvar( "g_gametype" ) == "zstandard" )
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead grief
		{
			level.effectlocation = (1666,9044,1340);
			level.modelangle = (0,0,0);
		}
		else if(getDvar("mapname") == "zm_buried") //buried grief
		{
			level.effectlocation = (-884,296,-30);
			level.modelangle = (0,270,0);
		}
		else if(getDvar("mapname") == "zm_nuked") //nuketown
		{
			level.effectlocation = (-210,949,-70);
			level.modelangle = (0,290,0);
		}
		else if(getDvar("mapname") == "zm_transit") //transit grief and survival
		{
			if(getDvar("ui_zm_mapstartlocation") == "town")
			{
				level.effectlocation = (1685,432,-61); //town
				level.modelangle = (0,270,0);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "transit")
			{
				level.effectlocation = (-6689,5111,-55); //bus depot
				level.modelangle = (0,180,0);
			}
			else if (getDvar("ui_zm_mapstartlocation") == "farm")
			{
				level.effectlocation = (8760,-5635,55); //farm
				level.modelangle = (0,270,0);
			}
		}
	}
	else
	{
		if(getDvar("mapname") == "zm_prison") //mob of the dead
		{
			level.effectlocation = (1910,10332,1345);
			level.modelangle = (0,90,0);
		}
		else if(getDvar("mapname") == "zm_buried") //buried
		{
			level.effectlocation = (-1023,-430,295);
			level.modelangle = (0,90,0);
		}
		else if(getDvar("mapname") == "zm_transit") //transit
		{
			level.effectlocation = (-6689,5111,-55);
			level.modelangle = (0,180,0);
		}
		else if(getDvar("mapname") == "zm_tomb") //origins
		{
			level.effectlocation = (2488,5477,-375);
			level.modelangle = (0,0,0);
		}
		else if(getDvar("mapname") == "zm_highrise")
		{
			level.effectlocation = (1285,1071,3420); //die rise
			level.modelangle = (0,45,0);
		}
	}
}

getRequirement()
{
	if (level.players.size == 1)
	{
		return 1;
	}
	else if (level.players.size == 2)
	{
		return 2;
	}
	else if (level.players.size == 3)
	{
		return 2;
	}
	else if (level.players.size == 4)
	{
		return 3;
	}
	else if (level.players.size == 5)
	{
		return 3;
	}
	else if (level.players.size == 6)
	{
		return 4;
	}
	else if (level.players.size == 7)
	{
		return 5;
	}
	else if (level.players.size == 8)
	{
		return 6;
	}
}

new_round_over()
{
    if ( isdefined( level.noroundnumber ) && level.noroundnumber == 1 )
        return;

    time = level.zombie_vars["zombie_between_round_time"];
    players = getplayers();

    for ( player_index = 0; player_index < players.size; player_index++ )
    {
        if ( !isdefined( players[player_index].pers["previous_distance_traveled"] ) )
            players[player_index].pers["previous_distance_traveled"] = 0;

        distancethisround = int( players[player_index].pers["distance_traveled"] - players[player_index].pers["previous_distance_traveled"] );
        players[player_index].pers["previous_distance_traveled"] = players[player_index].pers["distance_traveled"];
        players[player_index] incrementplayerstat( "distance_traveled", distancethisround );

        if ( players[player_index].pers["team"] != "spectator" )
        {
            zonename = players[player_index] get_current_zone();

            if ( isdefined( zonename ) )
                players[player_index] recordzombiezone( "endingZone", zonename );
        }
    }

    recordzombieroundend();
    if (level.ragestarted == 1)
    {

    }
    else
    {
    	wait( time );
    }
}
