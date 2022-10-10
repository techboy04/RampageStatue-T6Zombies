#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;

init()
{
	create_dvar("rampage_max_round", 20 );
    level thread onPlayerConnect();
	setlocation();
    level thread spawnInducer();
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
		
		self thread rampageHUD();
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
	level.perk_purchase_limit = 9;
	level.ragestarted = 0;
//	level thread maps/mp/zombies/_zm_powerups::specific_powerup_drop( "full_ammo", level.effectlocation );
}

roundChecker()
{
	while(1)
	{
		if (getDvarInt("rampage_max_round") < level.round_number)
		{
			level notify ("end_rage");
		}
		wait 0.5;
	}
}

spawnInducer()
{
	level.ragestarted = 0;
	rampageTrigger = spawn( "trigger_radius", (level.effectlocation), 1, 50, 50 );
	rampageTrigger setHintString("^7Press ^3&&1 ^7to activate Rampage Statue (All players need to be nearby)\nAll zombies will run for a certain amount of rounds");
	rampageTrigger setcursorhint( "HINT_NOICON" );
	rageInducerModel = spawn( "script_model", (level.effectlocation));
	rageInducerModel setmodel ("defaultactor");
	rageInducerModel rotateTo(level.modelangle,.1);
	while(1)
	{
		rampageTrigger waittill( "trigger", i );
		if ( i usebuttonpressed() )
		{
			if (checkAmountPlayers())
			{
				if (level.round_number < 5 && level.ragestarted == 0)
				{
					if (getDvarInt("rampage_max_round") <= 5)
					{
						setDvar("rampage_max_round", 20);
					}
					level thread startInducer();
					rampageTrigger setHintString("The statue is awaiting your worth");
//					break;
				}
				else if (level.round_number >= 5 && level.ragestarted == 0)
				{
					rampageTrigger setHintString("^7You were too late! Try again later!");
				}
			}
		}
		else if (getDvarInt("rampage_max_round") < level.round_number)
		{
			rampageTrigger setHintString("^7The statue is satisfied");
		}
	}
}

change_zombies_speed(speedtoset){
	level endon("end_game");
	sprint = speedtoset;
	can_sprint = false;
 	while(true){
 		can_sprint = false; 
    	zombies = getAiArray(level.zombie_team);
    	foreach(zombie in zombies)
    	if(!isDefined(zombie.cloned_distance))
    		zombie.cloned_distance = zombie.origin;
    	else if(distance(zombie.cloned_distance, zombie.origin) > 15){
    		can_sprint = true;
    		zombie.cloned_distance = zombie.origin;
    		if(zombie.zombie_move_speed == "run" || zombie.zombie_move_speed != sprint)
    			zombie maps/mp/zombies/_zm_utility::set_zombie_run_cycle(sprint);
    	}else if(distance(zombie.cloned_distance, zombie.origin) <= 15){
    		can_sprint = false;
    		zombie.cloned_distance = zombie.origin;
    		zombie maps/mp/zombies/_zm_utility::set_zombie_run_cycle("run");
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

setlocation()
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

rampageHUD()
{
	level endon("end_game");
	self endon( "disconnect" );

	rampage_hud = newClientHudElem(self);
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

checkAmountPlayers()
{
	count = 0;
	foreach ( player in players )
	{
	    if( distance( level.effectlocation, player.origin ) <= 10 )
	    {
	    	count += 1;
	    }
	}
	if (level.players.size == count)
	{
		return true;
	}
	else
	{
		return false;
	}
}
