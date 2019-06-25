#include <a_samp>
#include <fixes>
#include <sscanf>
#include <zcmdfs>
#include <DiniSarp>

// Detects the following (these also apply to the arrays within settings).
#define SPEEDHACKS 0 // Speed Hacks, vehicle and player (player collision, fly hacks etc).
#define VEHICLERELATED 1 // Car related hacks, like remote control, car warping, etc.
#define VEHICLEMODS 2 // Car Modification Hacking.
#define VEHICLESPAM 3 // Car Particle Spamming.
#define FAKEKILL 4 // Fake Killing.
#define HACKS 5 // s0beit installed.
// Need to add stuff like remote control car, fix the /anticheat menu (commands only?)
// and test everything with multiple people.

// Punishments
#define NOTHING 0
#define BAN 1
#define KICK 2
#define WARN 3

// Limits
#define DETECTIONS 6


// Data structures.
enum a_Settings // Anticheat settings
{
	// Whether or not they're loaded already.
	bool:loaded,
	
	// Punishment for specific hacks.
	// 0 - Nothing, 1 - Ban, 2 - Kick, 3 - Admin Warning.
	punishment[DETECTIONS],
	
	// Whether or not to detect certain things.
	bool:detection[DETECTIONS],
	
	// Not really a setting, but can rest here.
	detected, // Amount of detected, maybe make this an array for each hack too?
	
	// Debugging mode, dumps info like "PInfo" in certain places.
	debugging
};
new Settings[a_Settings];

enum a_Timings // Why not?
{
	// Will consist of arrays with at least 2 elements.
	// Element 1 - Tick when started.
	// Element 2 - Tick when ended.
	settingstime[2],
};
new Timings[a_Timings];

enum p_Info // Player info for holding various info on login.
{
	bool:loaded,
	bool:checked,
	alevel,
	LastPunishment, // Save last punishment tick to avoid spamming of punishments.
	CurrentVeh, // Used for detecting hacks like car warping, remote control, etc.
	CurrentState, // ^
	LastState, // ^
	SCTime, // ^
	Deaths // How many times they've died, used for detecting fake kills.
};
new PInfo[MAX_PLAYERS][p_Info];

enum v_Info // Vehicle info, for holding info like damage to detect car particle spamming.
{
	LastDamageInfo[4], // Holds last info for panels, doors, lights and tires.
	LastDamage // How many times it's state has changed.
};
new VInfo[MAX_VEHICLES][v_Info];

// Some arrays.
new a_string[512];

// Various definitions
#define DIALOG_ID_ANTICHEAT 4246 // I hope this isn't used anywhere else.

// Functions
stock ToNumber(character)
{
	if(character >= '0' && character <= '9') return character - '0';
	return 0;
}

bool:ToggleBool(&bool:toggle)
{
	if(toggle) 
	{
		toggle = false;
	}
	else
	{
	    toggle = true;
	}
	return toggle;
}

stock ShowAntiCheatDialog(playerid)
{
	format(a_string, sizeof(a_string), "iNFORMACIJA\nBausmes\nAptikimai\nDebug: %s", Nustatymai[debugging] ? ("{00FF00}ON") : ("{FF0000}OFF"));
	ShowPlayerDialog(	playerid, DIALOG_ID_ANTICHEAT, DIALOG_STYLE_LIST,
						"Anticheat Meniu", a_string,
						"Select", "Cancel");
	return 1;
}

stock GetHackNameFromType(type)
{
	new hackname[32];
	if(type == SPEEDHACKS)
	{
		format(hackname, sizeof(hackname), "Speed Hacks");
	}
	else if(type == VEHICLERELATED)
	{
		format(hackname, sizeof(hackname), "Vehicle Related Hacks");
	}
	else if(type == VEHICLEMODS)
	{
		format(hackname, sizeof(hackname), "Vehicle Mod Hacks");
	}
	else if(type == VEHICLESPAM)
	{
		format(hackname, sizeof(hackname), "Particle Spamming");
	}
	else if(type == FAKEKILL)
	{
		format(hackname, sizeof(hackname), "Fake Killing");
	}
	else if(type == HACKS)
	{
		format(hackname, sizeof(hackname), "Hacks Installed");
	}
	return hackname;
}

stock PunishForType(playerid, type)
{
   	if(GetTickCount() - PInfo[playerid][LastPunishment] > 1000) // Avoid spam!!!
   	{
		PInfo[playerid][LastPunishment] = GetTickCount();
		if(Settings[punishment][type] == BAN)
		{
		    HackBan(playerid, type);
		}
		else if(Settings[punishment][type] == KICK)
		{
		    HackKick(playerid, type);
		}
		else if(Settings[punishment][type] == WARN)
		{
		    HackWarning(playerid, type);
		}
		GetPlayerName(playerid, a_string, MAX_PLAYER_NAME);
		printf("[Anticheat]: %s is being punished for \"%s\".", a_string, GetHackNameFromType(type));
		printf("[Anticheat]: loaded = %d, checked = %d, alevel = %d, LastPunishment = %d.", PInfo[playerid][loaded], PInfo[playerid][checked], PInfo[playerid][alevel], PInfo[playerid][LastPunishment]);
		printf("[Anticheat]: CurrentVeh = %d, CurrentState = %d, LastState = %d, SCTime = %d.", PInfo[playerid][CurrentVeh], PInfo[playerid][CurrentState], PInfo[playerid][LastState], PInfo[playerid][SCTime]);
		printf("[Anticheat]: Deaths = %d.", PInfo[playerid][Deaths]);
	}
}

stock HackBan(playerid, type)
{
	if(PInfo[playerid][alevel] > 1) return 1; // admin exception
	Settings[detected]++;
	GetPlayerName(playerid, a_string, MAX_PLAYER_NAME);
	format(a_string, sizeof(a_string), "SERVERIS: %s buvo uþblokuotas, prieþastis: %s (%d CHEAT)", a_string, GetHackNameFromType(type), Settings[detected]);
	SendClientMessageToAll(0xFF6347FF, a_string);
    SetTimerEx("HackBanFinish", GetPlayerPing(playerid) * 2, 0, "ii", playerid, type);
    return 1;
}

forward HackBanFinish(playerid, type);
public HackBanFinish(playerid, type)
{
    GetPlayerName(playerid, a_string, MAX_PLAYER_NAME);
	BanEx(playerid, GetHackNameFromType(type));
	SendRconCommand("reloadbans");
	format(a_string, sizeof(a_string), "%s.ini", a_string);
	dini_IntSet(a_string, "Band", 3);
	dini_IntSet(a_string, "PermBand", 1);
	dini_Set(a_string, "BanReason", GetHackNameFromType(type));
	return 1;
}

stock HackKick(playerid, type)
{
    if(PInfo[playerid][alevel] > 1) return 1; // admin exception
	Settings[detected]++;
	GetPlayerName(playerid, a_string, MAX_PLAYER_NAME);
	format(a_string, sizeof(a_string), "SERVERIS: %s buvo iðmestas ið serverio uþ: %s (%d CHEAT)", a_string, GetHackNameFromType(type), Settings[detected]);
	SendClientMessageToAll(0xFF6347FF, a_string);
    SetTimerEx("HackKickFinish", GetPlayerPing(playerid) * 2, 0, "i", playerid);
    return 1;
}

forward HackKickFinish(playerid);
public HackKickFinish(playerid)
{
	Kick(playerid);
	return 1;
}

stock HackWarning(playerid, type)
{
    if(PInfo[playerid][alevel] > 1) return 1; // admin exception
    Settings[detected]++;
	GetPlayerName(playerid, a_string, MAX_PLAYER_NAME);
	format(a_string, sizeof(a_string), "INFORMACIJA{FFFFFF}: %s galimai naudoja èytus: %s", a_string, GetHackNameFromType(type));
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
	    if(!IsPlayerConnected(i)) continue;
		if(PInfo[i][alevel] > 0)
		{
		    SendClientMessage(i, 0xFF0000FF, a_string);
		}
	}
    return 1;
}

stock LoadSettings()
{
	if(Settings[loaded])
	{
		print("[Anticheat]: Unloading settings for reload");
		// Zero em out.
		for(new i = 0; i < DETECTIONS; i++)
		{
			Settings[punishment][i] = 0;
			Settings[detection][i] = false;
		}
		
		Settings[detected] = 0;
		Settings[debugging] = 0;

		Settings[loaded] = false;
		print("[Anticheat]: Unloaded settings, reloading.");
	}
	else print("[Anticheat]: Loading settings.");

	// Let's take down our time.
	Timings[settingstime][0] = GetTickCount();

	// Now, let's load em.
	if(!dini_Exists("a_settings.ini") || !fexist("a_settings.ini")) // WAT?
	    dini_Create("a_settings.ini"); // okay.

	format(a_string, sizeof(a_string), "%s", dini_Get("a_settings.ini", "Punishments"));
	for(new i = 0; i < DETECTIONS; i++)
	{
		Settings[punishment][i] = ToNumber(a_string[i]);
	}

	format(a_string, sizeof(a_string), "%s", dini_Get("a_settings.ini", "Detections"));
	for(new i = 0; i < DETECTIONS; i++)
	{
		if(a_string[i] > '0')
		{
			Settings[detection][i] = true;
		}
		else
		{
		    Settings[detection][i] = false;
		}
	}

	Settings[detected] = dini_Int("a_settings.ini", "Detected");
	Settings[debugging] = dini_Int("a_settings.ini", "Debug");

	Settings[loaded] = true;
	Timings[settingstime][1] = GetTickCount();
	printf("[Anticheat]: Loaded settings, took %dms.", Timings[settingstime][1] - Timings[settingstime][0]);
	return 1;
}

stock UnloadSettings()
{
	print("[Anticheat]: Unloading settings, saving first...");
    SaveSettings();
	
	// Zero em out.
	for(new i = 0; i < DETECTIONS; i++)
	{
		Settings[punishment][i] = 0;
		Settings[detection][i] = false;
	}

    Settings[debugging] = 0;
	Settings[detected] = 0;

	Settings[loaded] = false;
	print("[Anticheat]: Unloaded settings.");
	return 1;
}

stock SaveSettings()
{
	if(!Settings[loaded]) return print("[Anticheat]: Settings weren't loaded in the first place, canceling save.");
						 
	print("[Anticheat]: Saving settings.");

	// Let's take down our time, again.
	Timings[settingstime][0] = GetTickCount();
	
	if(!dini_Exists("a_settings.ini") || !fexist("a_settings.ini")) // WAT? something's up
	    dini_Create("a_settings.ini"); // pls?

	format(a_string, sizeof(a_string), "");
	for(new i = 0; i < DETECTIONS; i++)
	{
	    format(a_string, sizeof(a_string), "%s%d", a_string, Settings[punishment][i]);
	}
	dini_Set("a_settings.ini", "Punishments", a_string);
	                                                    
	format(a_string, sizeof(a_string), "");
	for(new i = 0; i < DETECTIONS; i++)
	{
	    format(a_string, sizeof(a_string), "%s%d", a_string, Settings[detection][i]);
	}
	dini_Set("a_settings.ini", "Detections", a_string);
	
	dini_IntSet("a_settings.ini", "Detected", Settings[detected]);
	dini_IntSet("a_settings.ini", "Debug", Settings[debugging]);
	
	Timings[settingstime][1] = GetTickCount();
	printf("[Anticheat]: Saved settings, took %dms.", Timings[settingstime][1] - Timings[settingstime][0]);
	return 1;
}

// Commmands

// Anticheat settings or information dialog for admins, and maybe players too.
// If we include players, it will be restricted to info for them, I also think
// /anticheat is a command in the gamemode already and this will override that.
CMD:anticheat(playerid, params[])
{
	if(PInfo[playerid][alevel] < 2) return 0; // Pass them on to the gamemode.
	ShowAntiCheatDialog(playerid);
	return 1;
}

// To invoke the s0beit check.
CMD:checks0b(playerid, params[])
{
    if(PInfo[playerid][alevel] < 2) return 1;
	new pid;
	if(sscanf(params, "u", pid)) return SendClientMessage(playerid, -1, "USAGE: /checks0b [playerid]");
	if(!IsPlayerConnected(pid)) return SendClientMessage(playerid, -1, "Player is not connected.");
	if(!PInfo[playerid][loaded]) return SendClientMessage(playerid, -1, "Player is not loaded.");
	Starts0bCheck(pid, 0);
	SendClientMessage(playerid, -1, "Invoking a s0beit check.");
	return 1;
}

// Generic callbacks.
new MainTimer = -1;

public OnFilterScriptInit()
{
	LoadSettings();
	for(new p = 0; p < MAX_PLAYERS; p++)
	{
		for(new i; p_Info:i < p_Info; i++)
		{
			PInfo[p][p_Info:i] = 0;
		}
		if(IsPlayerConnected(p)) PInfo[p][CurrentVeh] = GetPlayerVehicleID(p);
	}
	MainTimer = SetTimer("MainTiming", 1000, 1);
	return 1;
}

public OnFilterScriptExit()
{
	UnloadSettings();
	KillTimer(MainTimer);
	return 1;
}

// The hack detections.

// Detecting if s0beit is installed.
// As you can see below, the way we detect s0beit is simple, and it uses a flaw
// in s0beit to our advantage. Basically with s0beit, when you get frozen, the
// camera goes upwards, but without s0beit it doesn't. This flaw is a great
// advantage for us.
// Also, maybe make this use GetPlayerCameraFrontVector instead?
public OnPlayerSpawn(playerid)
{
	if(Settings[detection][HACKS] && !PInfo[playerid][checked] && PInfo[playerid][alevel] < 2)
	{
	    PInfo[playerid][checked] = true;
		SetTimerEx("Starts0bCheck", 1000 + (GetPlayerPing(playerid) * 2), 0, "ii", playerid, 1);
	}
	return 1;
}

forward Starts0bCheck(playerid, type);
public Starts0bCheck(playerid, type)
{
	if(IsPlayerConnected(playerid) && PInfo[playerid][loaded])
	{
		// Don't check people in tutorial or hospital.
		if(	IsPlayerInRangeOfPoint(playerid, 1.0, 1192.256836, -1304.637939, 7.0000) || 		// All Saints
		    IsPlayerInRangeOfPoint(playerid, 1.0, 2012.323608, -1436.354370, 5.0000) || 		// County General
		    IsPlayerInRangeOfPoint(playerid, 1.0, 764.4561160, -1761.971436, 0.0000) || 		// Tutorial First Position.
		    IsPlayerInRangeOfPoint(playerid, 1.0, 2324.685303, -2340.955078, 0.0000)) return 1; // Tutorial Second Position.
		    
	    if(type == 1) SendClientMessage(playerid, -1, "Please wait while we process your character.");
	    if(IsPlayerInAnyVehicle(playerid))
	    {
	        new Float:pos[3];
	        GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
	        SetPlayerPos(playerid, pos[0], pos[1], pos[2]);
		}
		SetCameraBehindPlayer(playerid);
		TogglePlayerControllable(playerid, 0);
		SetTimerEx("Finishs0bCheck", 3000, 0, "ii", playerid, type);
	}
	return 1;
}

forward Finishs0bCheck(playerid, type);
public Finishs0bCheck(playerid, type)
{
	if(IsPlayerConnected(playerid) && PInfo[playerid][loaded])
	{
		new Float:testpos[6];
		GetPlayerCameraPos(playerid, testpos[0], testpos[1], testpos[2]);
		GetPlayerPos(playerid, testpos[3], testpos[4], testpos[5]);
		TogglePlayerControllable(playerid, 1);

		if(floatabs(testpos[2] - testpos[5]) > 1.5)
		{
			PunishForType(playerid, HACKS);
			if(Settings[punishment][HACKS] == WARN && type == 1)
			{
                SendClientMessage(playerid, -1, "Thank you, enjoy your stay.");
			}
			
			GetPlayerName(playerid, a_string, MAX_PLAYER_NAME);
			printf("[Anticheat]: %s has s0beit installed.", a_string);
			printf("[Anticheat]: Camera Position: %f, %f, %f.", testpos[0], testpos[1], testpos[2]);
			printf("[Anticheat]: Player Position: %f, %f, %f.", testpos[3], testpos[4], testpos[5]);
			printf("[Anticheat]: Absolute Difference: %f, %f, %f.", floatabs(testpos[0] - testpos[3]),
			                                                        floatabs(testpos[1] - testpos[4]),
			                                                        floatabs(testpos[2] - testpos[5]));
		}
		else
		{
		    SendClientMessage(playerid, -1, "Thank you, enjoy your stay.");
		}
	}
}

// Car particle spamming.
// This hack right here actually reports damages of the car to the SA-MP server,
// thus spamming particles (parts falling off) which actually lags nearby
// clients due to all of the rendering it has to do.
// Tbis detection is simple, when they report damage to their vehicle, it gets
// the damages since the last damage update, and if there's changes to anything
// or everything but lights, it will increase how many times they've damaged
// their car in the last second, if it's above a certain amount, they're car
// particle spamming.
public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
	if(PInfo[playerid][loaded])
	{
		if(Settings[detection][VEHICLESPAM])
		{
			new panels, doors, lights, tires;
			GetVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
			if(VInfo[vehicleid][LastDamageInfo][0] != panels || VInfo[vehicleid][LastDamageInfo][1] != doors || VInfo[vehicleid][LastDamageInfo][3] != tires)
			{
			    VInfo[vehicleid][LastDamage]++;
			    if(VInfo[vehicleid][LastDamage] > 10)
			    {
					PunishForType(playerid, VEHICLESPAM);
					return 0;
			    }
				VInfo[vehicleid][LastDamageInfo][0] = panels;
				VInfo[vehicleid][LastDamageInfo][1] = doors;
				VInfo[vehicleid][LastDamageInfo][2] = lights;
				VInfo[vehicleid][LastDamageInfo][3] = tires;
			}
		}
	}
    return 1;
}

// Car modification hacking.
// All this does is checks the current interior of the player when they get a
// car mod, if they're in interior 0, they're not in a mod shop and likely
// hacking, so we ban them.
// Pretty straight forward.
public OnVehicleMod(playerid,vehicleid,componentid)
{
	if(PInfo[playerid][loaded])
	{
		if(Settings[detection][VEHICLEMODS])
		{
		    if(GetPlayerInterior(playerid) == 0)
		    {
				PunishForType(playerid, VEHICLEMODS);
				return 0;
		    }
	    }
    }
    return 1;
}

// Fake killing.
// Fake killing is a very vicous hack, because 1. it will mess with kill/death
// ratios of players, 2 (and the most important). it forces the server/script to
// process a lot of deaths, thus causing performance problems.
// Detecting it is pretty straight forward, if someone dies more than 3 times
// within in a second, obviously they're fake killing and need to be dealt with.
public OnPlayerDeath(playerid, killerid, reason)
{
    if(PInfo[playerid][loaded])
	{
		if(Settings[detection][FAKEKILL])
		{
			PInfo[playerid][Deaths]++;
			if(PInfo[playerid][Deaths] > 3) // Fake killer.
			{
				PunishForType(playerid, FAKEKILL);
				return 0;
			}
		}
	}
	return 1;
}

// 3 parts/functions - Car Warping and a lot of other hacks related to vehicles.
// Basically car warping can involve multiple things, so I'll just explain the
// detection and maybe you can get a gist of it.
// The detection is simple, if they change state or vehicle and their current
// and last state is driver, they're hacking.
stock StateChange(playerid)
{
    if(PInfo[playerid][loaded])
	{
		if(Settings[detection][VEHICLERELATED])
		{
		    PInfo[playerid][SCTime]++;
			if(PInfo[playerid][CurrentState] == PLAYER_STATE_DRIVER && PInfo[playerid][LastState] == PLAYER_STATE_DRIVER)
			{
			    PunishForType(playerid, VEHICLERELATED);
				return 0;
			}
			else if(PInfo[playerid][SCTime] > 3)
		    {
			    PunishForType(playerid, VEHICLERELATED);
				return 0;
			}
		}
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(PInfo[playerid][loaded])
	{
	    PInfo[playerid][CurrentVeh] = GetPlayerVehicleID(playerid);
	    PInfo[playerid][LastState] = PInfo[playerid][CurrentState];
	    PInfo[playerid][CurrentState] = GetPlayerState(playerid);
		return StateChange(playerid);
	}
	return 1;
}

// Speed Hacks
public OnPlayerUpdate(playerid)
{
	if(PInfo[playerid][loaded])
	{
		// The following is required to detect car warpers who are doing it while in
		// a vehicle, OnPlayerStateChange is not called in that case but this
		// emulates the effects of OnPlayerStateChange.
		if(GetPlayerVehicleID(playerid) != PInfo[playerid][CurrentVeh])
		{
		    PInfo[playerid][CurrentVeh] = GetPlayerVehicleID(playerid);
		    PInfo[playerid][LastState] = PInfo[playerid][CurrentState];
		    PInfo[playerid][CurrentState] = GetPlayerState(playerid);
			return StateChange(playerid);
		}
		if(Settings[detection][SPEEDHACKS])
		{
			if(IsPlayerInAnyVehicle(playerid))
			{
			    if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
			    {
					// Okay, let's detect vehicle speed hacks.
					// Now, there was a problem in the old anticheat where the Z velocity would
					// reach about 2.0 when falling in a car thus banning players.
					// The fix for this is simple, don't ban for the Z velocity being minus 1.8.
					// s0beit speed hacks reaches about 1.85 at max speed in any car, so we need
					// to ban when we reach that velocity on X, Y (plus or minus) or Z (plus only).
				    new Float:veloc[3];
					GetVehicleVelocity(GetPlayerVehicleID(playerid), veloc[0], veloc[1], veloc[2]);
					if(veloc[0] > 1.8 || veloc[0] < -1.8 || veloc[1] > 1.8 || veloc[1] < -1.8 || veloc[2] > 1.8)
					{
						// we gots us a speed haxer.
						PunishForType(playerid, SPEEDHACKS);
						return 0;
					}
				}
			}
			else
			{
			    // Alright then, player speed hacks it is.
			    // Now this can be multiple hacks whether it be player collision,
			    // fly hacks, and possibly airbrake.
			    // This would have the same problem with falling as the vehicles
			    // so we just need to do the exact same as above to avoid false
			    // positives.
			    new Float:veloc[3];
				GetPlayerVelocity(playerid, veloc[0], veloc[1], veloc[2]);
				if(veloc[0] > 1.25 || veloc[0] < -1.25 || veloc[1] > 1.25 || veloc[1] < -1.25 || veloc[2] > 1.25)
				{
				    // we gots us a player speeders
					PunishForType(playerid, SPEEDHACKS);
				    return 0;
				}
			}
		}
	}
	return 1;
}

// The main timer, for clearing out info and detecting admins logging in etc.
forward MainTiming();
public MainTiming()
{
	for(new playerid = 0; playerid < MAX_PLAYERS; playerid++)
	{
		PInfo[playerid][SCTime] = 0; // Clear how many times their state has changed.
		PInfo[playerid][Deaths] = 0; // Clear how many times they've died.
	    if(!IsPlayerConnected(playerid))
		{
		    if(PInfo[playerid][loaded]) // We need to clear him, he left.
		    {
				PInfo[playerid][alevel] = 0;
				PInfo[playerid][SCTime] = 0;
				PInfo[playerid][CurrentVeh] = 0;
				PInfo[playerid][LastState] = 0;
				PInfo[playerid][CurrentState] = 0;
				PInfo[playerid][Deaths] = 0;
				PInfo[playerid][LastPunishment] = 0;
				PInfo[playerid][checked] = false;
				
				// Let's not repeat that.
				PInfo[playerid][loaded] = false;
			}
		}
		else
		{
		    if(!PInfo[playerid][loaded])
		    {
		        GetPlayerName(playerid, a_string, MAX_PLAYER_NAME);
		        format(a_string, sizeof(a_string), "%s.ini", a_string);
		        if(fexist(a_string))
		        {
					PInfo[playerid][alevel] = dini_Int(a_string, "AdminLvl");
					PInfo[playerid][SCTime] = 0;
					PInfo[playerid][CurrentVeh] = 0;
					PInfo[playerid][LastState] = 0;
					PInfo[playerid][CurrentState] = 0;
					PInfo[playerid][Deaths] = 0;
					PInfo[playerid][LastPunishment] = 0;
					PInfo[playerid][checked] = false;

					// Let's not repeat that.
					PInfo[playerid][loaded] = true;
				}
			}
		}
	}
	for(new vid = 0; vid < MAX_VEHICLES; vid++)
	{
		VInfo[vid][LastDamage] = 0;
	}
	return 1;
}

// The dialogs responses.
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_ID_ANTICHEAT + 1) // Information, just to move back
	{
		ShowAntiCheatDialog(playerid);
		return 1;
	}
	
	if(dialogid == DIALOG_ID_ANTICHEAT + 2) // Punishments, change punishments.
	{
	    if(PInfo[playerid][alevel] < 2) return 1;
	    if(!response)
		{
		    ShowAntiCheatDialog(playerid);
			return 1;
		}
		else
		{
		    if(Settings[punishment][listitem] >= 3)
		    {
		        Settings[punishment][listitem] = 0;
			}
			else
			{
			    Settings[punishment][listitem]++;
			}

			strdel(a_string, 0, sizeof(a_string));

			for(new i = 0; i < DETECTIONS; i++)
			{
			    if(strlen(a_string) > 0)
			    {
			        format(a_string, sizeof(a_string), "%s\n%s: ", a_string, GetHackNameFromType(i));
				}
				else
				{
				    format(a_string, sizeof(a_string), "%s: ", GetHackNameFromType(i));
				}

				if(Settings[punishment][i] == NOTHING)
				{
					format(a_string, sizeof(a_string), "%s{FF0000}Nothing", a_string);
				}
				else if(Settings[punishment][i] == BAN)
				{
					format(a_string, sizeof(a_string), "%s{00FF00}Ban", a_string);
				}
				else if(Settings[punishment][i] == KICK)
				{
					format(a_string, sizeof(a_string), "%s{00FF00}Kick", a_string);
				}
				else if(Settings[punishment][i] == WARN)
				{
					format(a_string, sizeof(a_string), "%s{00FF00}Admin Warning", a_string);
				}
			}

			ShowPlayerDialog(	playerid, DIALOG_ID_ANTICHEAT + 2, DIALOG_STYLE_LIST,
			                    "Anticheat Punishments", a_string,
			                    "Change", "Back");
		}
		return 1;
	}
	
	if(dialogid == DIALOG_ID_ANTICHEAT + 3) // Detections, change detections.
	{
		if(PInfo[playerid][alevel] < 2) return 1;
		if(!response)
		{
			ShowAntiCheatDialog(playerid);
			return 1;
		}
		else
		{
			ToggleBool(Settings[detection][listitem]);

			strdel(a_string, 0, sizeof(a_string));

			for(new i = 0; i < DETECTIONS; i++)
			{
			    if(strlen(a_string) > 0)
			    {
			        format(a_string, sizeof(a_string), "%s\n%s: ", a_string, GetHackNameFromType(i));
				}
				else
				{
				    format(a_string, sizeof(a_string), "%s: ", GetHackNameFromType(i));
				}
				
				if(Settings[detection][i])
				{
					format(a_string, sizeof(a_string), "%s{00FF00}ON", a_string);
				}
				else
				{
					format(a_string, sizeof(a_string), "%s{FF0000}OFF", a_string);
				}
			}

			ShowPlayerDialog(	playerid, DIALOG_ID_ANTICHEAT + 3, DIALOG_STYLE_LIST,
								"Anticheat Detections", a_string,
								"Change", "Back");
		}
		return 1;
	}
	
	if(dialogid == DIALOG_ID_ANTICHEAT) // /anticheat
	{
	    if(PInfo[playerid][alevel] < 2) return 1;
	    if(!response)
		{
			return 1;
		}
		else
		{
		    if(listitem == 0) // Information, including timing, amount of players detected.
		    {
		        format(	a_string, sizeof(a_string),
						"Settings Time: %d\nPlayers Detected: %d",
						Timings[settingstime][1] - Timings[settingstime][0], Settings[detected]);
						
				ShowPlayerDialog(	playerid, DIALOG_ID_ANTICHEAT + 1, DIALOG_STYLE_MSGBOX,
				                    "Anticheat Information", a_string, "Back", "");
			}
			else if(listitem == 1) // Punishments, display/change punishments.
			{
				strdel(a_string, 0, sizeof(a_string));

				for(new i = 0; i < DETECTIONS; i++)
				{
				    if(strlen(a_string) > 0)
				    {
				        format(a_string, sizeof(a_string), "%s\n%s: ", a_string, GetHackNameFromType(i));
					}
					else
					{
					    format(a_string, sizeof(a_string), "%s: ", GetHackNameFromType(i));
					}

					if(Settings[punishment][i] == NOTHING)
					{
						format(a_string, sizeof(a_string), "%s{FF0000}Nothing", a_string);
					}
					else if(Settings[punishment][i] == BAN)
					{
						format(a_string, sizeof(a_string), "%s{00FF00}Ban", a_string);
					}
					else if(Settings[punishment][i] == KICK)
					{
						format(a_string, sizeof(a_string), "%s{00FF00}Kick", a_string);
					}
					else if(Settings[punishment][i] == WARN)
					{
						format(a_string, sizeof(a_string), "%s{00FF00}Admin Warning", a_string);
					}
				}

				ShowPlayerDialog(	playerid, DIALOG_ID_ANTICHEAT + 2, DIALOG_STYLE_LIST,
				                    "Anticheat Punishments", a_string,
				                    "Change", "Back");
			}
			else if(listitem == 2) // Detections, display/change detections.
			{
				strdel(a_string, 0, sizeof(a_string));

				for(new i = 0; i < DETECTIONS; i++)
				{
				    if(strlen(a_string) > 0)
				    {
				        format(a_string, sizeof(a_string), "%s\n%s: ", a_string, GetHackNameFromType(i));
					}
					else
					{
					    format(a_string, sizeof(a_string), "%s: ", GetHackNameFromType(i));
					}

					if(Settings[detection][i])
					{
						format(a_string, sizeof(a_string), "%s{00FF00}ON", a_string);
					}
					else
					{
						format(a_string, sizeof(a_string), "%s{FF0000}OFF", a_string);
					}
				}

				ShowPlayerDialog(	playerid, DIALOG_ID_ANTICHEAT + 3, DIALOG_STYLE_LIST,
				                    "Anticheat Detections", a_string,
				                    "Change", "Back");
			}
			else if(listitem == 3) // Toggle debug.
			{
				if(Settings[debugging]) Settings[debugging] = 0;
				else Settings[debugging] = 1;
				ShowAntiCheatDialog(playerid);
			}
		}
		return 1;
	}
	return 1;
}
