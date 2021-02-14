/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Map Management Plugin
 * Provides all map related functionality, including map changing, map voting,
 * and nextmap.
 *
 * SourceMod (C)2004-2016 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
 
#include <sourcemod>
#include <sdktools>
#include <emitsoundany>
#include <zombiereloaded>
#include <colors_csgo>
#pragma newdecls required // let's go new syntax! 


#define EFL_NO_PHYSCANNON_INTERACTION (1<<30)

#pragma semicolon 1

#define WEAPONS_MAX_LENGTH 32
#define DATA "3.2-B"
#define MAX_FILE_LEN 80
#define DMG_GENERIC 0

#define PLAYER_ONFIRE (1 << 24)

#define EXPLODE_SOUND	"ambient/explosions/explode_8.mp3"
#define SOUND_END "zombie_plague/survivor1.mp3"

#define zr_facosa "zr_facosa/normal4.mp3"
#define zr_facosa1 "zr_facosa/rambo1.mp3"
#define zr_facosa2 "zr_facosa/rambo2.mp3"
#define zr_facosa3 "zr_facosa/chuck_norris1.mp3"
#define zr_facosa4 "zr_facosa/chuck_norris2.mp3"

#define zr_punishment1 "zr_punishment/punishment1.mp3"
#define zr_punishment2 "zr_punishment/punishment2.mp3"
#define zr_punishment3 "zr_punishment/punishment3.mp3"
#define zr_punishment4 "zr_punishment/punishment4.mp3"

ConVar h_kbooom_enable;
ConVar h_punishkn_enable;
ConVar h_punishat_enable;
ConVar h_mother_protect;
ConVar h_sounds_punish;
ConVar h_sounds_congra;
ConVar h_time_mother;
ConVar h_time_explod;
ConVar h_volume_sounds;
ConVar h_volume_explod;

Handle h_mtime;
Handle h_etime[MAXPLAYERS+1];
Handle g_CvarSoundName = INVALID_HANDLE;

bool kbooom_enable;
bool punishkn_enable;
bool punishat_enable;
bool mother_protect;
bool sounds_punish;
bool sounds_congra;
bool mother;
bool contar;
bool g_ZombieExplode[MAXPLAYERS+1] = false;

float time_mother;
float time_explod;
float f_volume_sounds;
float f_volume_explod;

char g_soundName[MAX_FILE_LEN];

int g_ExplosionSprite;
int orange;
int g_HaloSprite;
int g_LightningSprite;
int g_SmokeSprite;
int g_Serial_Gen = 0;
int h_btime[MAXPLAYERS+1] = { 0, ... };

public Plugin myinfo =
{
	name = "KBOOOM",
	author = "Franug, Amauri Bueno dos Santos, Anubis edition",
	description = "Kill zombies with knife",
	version = DATA,
	url = "www.sourcemod.com"
};

public void OnPluginStart()
{
	CreateConVar("sm_kbooom_version", DATA, "version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	h_kbooom_enable = CreateConVar("sm_kbooom_enable", "1", "Enables/Disables Bzm_KBoom.", 0, true, 0.0, true, 1.0);
	h_punishkn_enable = CreateConVar("sm_kbooom_punishknife", "1", "Enables/Disables punished for knife the first zombie.", 0, true, 0.0, true, 1.0);
	h_punishat_enable = CreateConVar("sm_kbooom_punishatack", "1", "Enables/Disables punished for attacker the first zombie.", 0, true, 0.0, true, 1.0);
	h_mother_protect = CreateConVar("sm_kbooom_mprotect", "1", "Enables/Disables mother protect Bzm_KBoom.", 0, true, 0.0, true, 1.0);
	h_sounds_punish = CreateConVar("sm_kbooom_spunish", "1", "Enables/Disables sounds punishment.", 0, true, 0.0, true, 1.0);
	h_sounds_congra = CreateConVar("sm_kbooom_scongra", "1", "Enables/Disables sounds congratulation.", 0, true, 0.0, true, 1.0);
	h_time_mother = CreateConVar("sm_kbooom_tmprotect", "60.0", "Seconds mother protect. Dependence sm_kbooom_mprotect Enable");
	h_time_explod = CreateConVar("sm_kbooom_explode", "6.0", "Seconds that zombie have for catch to humans.");
	g_CvarSoundName = CreateConVar("sm_kbooom_knife_sound", "weapons/knife_stab.wav", "Stab victory");
	h_volume_sounds = CreateConVar("sm_kbooom_volume_sounds", "1.0", "Volume of sounds.");
	h_volume_explod = CreateConVar("sm_kbooom_volume_explod", "1.0", "Explosion volume.");

	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_hurt", EnDamage);
	HookEvent("player_death", PlayerDeathEvent);
	HookEvent("round_start", eventRoundStart);
	HookEvent("round_end", EventRoundEnd);

	kbooom_enable = h_kbooom_enable.BoolValue;
	punishkn_enable = h_punishkn_enable.BoolValue;
	punishat_enable = h_punishat_enable.BoolValue;
	mother_protect = h_mother_protect.BoolValue;
	sounds_punish = h_sounds_punish.BoolValue;
	sounds_congra = h_sounds_congra.BoolValue;
	time_mother = h_time_mother.FloatValue;
	time_explod = h_time_explod.FloatValue;
	f_volume_sounds = h_volume_sounds.FloatValue;
	f_volume_explod = h_volume_explod.FloatValue;

	h_kbooom_enable.AddChangeHook(OnConVarChanged);
	h_punishkn_enable.AddChangeHook(OnConVarChanged);
	h_punishat_enable.AddChangeHook(OnConVarChanged);
	h_mother_protect.AddChangeHook(OnConVarChanged);
	h_sounds_punish.AddChangeHook(OnConVarChanged);
	h_sounds_congra.AddChangeHook(OnConVarChanged);
	h_time_mother.AddChangeHook(OnConVarChanged);
	h_time_explod.AddChangeHook(OnConVarChanged);
	h_volume_sounds.AddChangeHook(OnConVarChanged);
	h_volume_explod.AddChangeHook(OnConVarChanged);

}

public void OnConVarChanged(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	kbooom_enable = h_kbooom_enable.BoolValue;
	punishkn_enable = h_punishkn_enable.BoolValue;
	punishat_enable = h_punishat_enable.BoolValue;
	mother_protect = h_mother_protect.BoolValue;
	sounds_punish = h_sounds_punish.BoolValue;
	sounds_congra = h_sounds_congra.BoolValue;
	time_mother = h_time_mother.FloatValue;
	time_explod = h_time_explod.FloatValue;
	f_volume_sounds = h_volume_sounds.FloatValue;
	f_volume_explod = h_volume_explod.FloatValue;
}

public void OnMapStart()
{
	LoadTranslations("bzm_kbooom.phrases");

	AddFileToDownloadsTable("sound/zombie_plague/nemesis_pain2.mp3");
	AddFileToDownloadsTable("sound/zombie_plague/survivor1.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/normal4.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/chuck_norris1.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/chuck_norris2.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/rambo1.mp3");
	AddFileToDownloadsTable("sound/zr_facosa/rambo2.mp3");
	AddFileToDownloadsTable("sound/zr_punishment/punishment1.mp3");
	AddFileToDownloadsTable("sound/zr_punishment/punishment2.mp3");
	AddFileToDownloadsTable("sound/zr_punishment/punishment3.mp3");
	AddFileToDownloadsTable("sound/zr_punishment/punishment4.mp3");
	AddFileToDownloadsTable("sound/ambient/explosions/explode_8.mp3");

	AddFileToDownloadsTable("materials/sprites/laser.vmt");
	AddFileToDownloadsTable("materials/sprites/glow_test02.vmt");
	AddFileToDownloadsTable("materials/sprites/lgtning.vmt");
	AddFileToDownloadsTable("materials/sprites/halo01.vmt");
	AddFileToDownloadsTable("materials/sprites/tp_beam001.vmt");
	AddFileToDownloadsTable("materials/sprites/fire.vmt");

	PrecacheSoundAny(EXPLODE_SOUND, true);
	PrecacheSoundAny(SOUND_END, true);
	PrecacheSoundAny(zr_facosa, true);
	PrecacheSoundAny(zr_facosa1, true);
	PrecacheSoundAny(zr_facosa2, true);
	PrecacheSoundAny(zr_facosa3, true);
	PrecacheSoundAny(zr_facosa4, true);
	PrecacheSoundAny(zr_punishment1, true);
	PrecacheSoundAny(zr_punishment2, true);
	PrecacheSoundAny(zr_punishment3, true);
	PrecacheSoundAny(zr_punishment4, true);
	PrecacheSoundAny("zombie_plague/nemesis_pain2.mp3", true);
	orange=PrecacheModel("materials/sprites/fire.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	AutoExecConfig(true, "bZm_KOOOM");
}

public void OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	char buffer[MAX_FILE_LEN];
	PrecacheSoundAny(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}

public Action eventRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!kbooom_enable)	return;
	if(kbooom_enable) contar = false;
	
	if(h_mtime != INVALID_HANDLE)
	{
		KillTimer(h_mtime);
		h_mtime = INVALID_HANDLE;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if(h_etime[i] != INVALID_HANDLE)
		{
			//KillTimer(h_etime[client]);
			h_etime[i] = INVALID_HANDLE;
		}
		KillBeacon(i);
	}

	if(mother_protect)
	{
		mother = true;
		contar = true;
		CPrintToChatAll("%t", "Mother Protect Enabled", time_mother);
		if((!punishkn_enable) && (!punishat_enable))	contar = true;
		h_mtime = CreateTimer(time_mother, Motherprotect);
	}

	if(!mother_protect)
	{
		mother = false;
		if((!punishkn_enable) && (!punishat_enable))	contar = true;
	}
}

public Action Motherprotect(Handle hTimer)
{
	CPrintToChatAll("%t", "Mother Protect finished Chat");
	PrintCenterTextAll("%t", "Mother Protect finished Center");
	mother = false;
	h_mtime = INVALID_HANDLE;
}

public Action EventRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (!kbooom_enable)	return;

	if(h_mtime != INVALID_HANDLE)
	{
		KillTimer(h_mtime);
		h_mtime = INVALID_HANDLE;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if(h_etime[i] != INVALID_HANDLE)
		{
			//KillTimer(h_etime[client]);
			h_etime[i] = INVALID_HANDLE;
		}
		KillBeacon(i);
	}
	contar = false;
	mother = false;
	int ev_winner = GetEventInt(event, "winner");
	if(ev_winner == 2) {
	EmitSoundToAllAny(SOUND_END, _, SNDCHAN_AUTO, _, _, f_volume_sounds);
	}
}

bool IsValidClient(int client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
		return false;
	
	return true;
}

public void OnClientDisconnect(int client)
{
	if(!kbooom_enable)	return;

	char nome[MAX_NAME_LENGTH];
	GetClientName(client, nome, sizeof(nome));
	if(h_etime[client] != INVALID_HANDLE)
	{
		h_etime[client] = INVALID_HANDLE;
		CPrintToChatAll("%t", "Disconnect", nome);
		if(sounds_punish)	EmitSoundToAllAny(zr_punishment3, _, SNDCHAN_AUTO, _, _, f_volume_sounds);
	}
	KillBeacon(client);
}

public Action PlayerDeathEvent(Handle event, const char[] name, bool dontBroadcast)
{
	if (!kbooom_enable)	return;
	int	victim   = GetClientOfUserId(GetEventInt(event,"userid"));
	contar = true;
	float vecOrigin[3];
	GetClientAbsOrigin(victim, vecOrigin);
	if(IsValidClient(victim) && GetClientTeam(victim) == 2)
	{
		if(sounds_congra)	EmitAmbientSoundAny("zombie_plague/nemesis_pain2.mp3", vecOrigin, victim, _, _, f_volume_sounds);
	}
}

public Action EnDamage(Handle event, const char[] name, bool dontBroadcast)
{
	if (!kbooom_enable)	return;
	if (mother)	return;
	
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	char nome[MAX_NAME_LENGTH];
	GetClientName(attacker, nome, sizeof(nome));

	if (!IsValidClient(attacker))
		return;

	if (IsPlayerAlive(attacker))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		char weapon[WEAPONS_MAX_LENGTH];
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && (contar))
		{
			if(h_etime[client] != INVALID_HANDLE) return;
			float vec[3];
			GetClientAbsOrigin(client, vec);
			if(StrEqual(weapon, "knife", false))
			{
				g_ZombieExplode[client] = true;
				CPrintToChat(client, "%t", "you will die", nome, time_explod);
				Handle pack;
				int rnd_sound = GetRandomInt(1, 6);
				if(rnd_sound == 1) 
				{
					if(sounds_congra)	EmitAmbientSoundAny(g_soundName, vec, client, SNDLEVEL_RAIDSIREN, _, f_volume_sounds);
					CPrintToChat(attacker, "%t", "Kill Zombie 1", nome);
				}
				else if(rnd_sound == 2) {
					if(sounds_congra)	EmitAmbientSoundAny(zr_facosa, vec, client, SNDLEVEL_RAIDSIREN, _, f_volume_sounds);
					CPrintToChat(attacker, "%t", "Kill Zombie 2", nome);
				}
				else if(rnd_sound == 3) {
					if(sounds_congra)	EmitAmbientSoundAny(zr_facosa1, vec, client, SNDLEVEL_RAIDSIREN, _, f_volume_sounds);
					CPrintToChat(attacker, "%t", "Kill Zombie 3", nome);
				}
				else if(rnd_sound == 4) {
					if(sounds_congra)	EmitAmbientSoundAny(zr_facosa2, vec, client, SNDLEVEL_RAIDSIREN, _, f_volume_sounds);
					CPrintToChat(attacker, "%t", "Kill Zombie 4", nome);
				}
				else if(rnd_sound == 5) {
					if(sounds_congra)	EmitAmbientSoundAny(zr_facosa3, vec, client, SNDLEVEL_RAIDSIREN, _, f_volume_sounds);
					CPrintToChat(attacker, "%t", "Kill Zombie 5", nome);
				}
				else if(rnd_sound == 6) {
					if(sounds_congra)	EmitAmbientSoundAny(zr_facosa4, vec, client, SNDLEVEL_RAIDSIREN, _, f_volume_sounds);
					CPrintToChat(attacker, "%t", "Kill Zombie 6", nome);
				}
				h_btime[client] = ++g_Serial_Gen;
				CreateTimer(0.5, Timer_Beacon, client | (g_Serial_Gen << 7), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				h_etime[client] = CreateDataTimer(time_explod, ByeZM, pack, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(pack, client);
				WritePackCell(pack, attacker);
			}
		}
		else if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && StrEqual(weapon, "knife", false) && (!contar))
		{
			contar = true;
			if(punishkn_enable)
			{
				if(sounds_punish)	EmitSoundToAllAny(zr_punishment1, _, SNDCHAN_AUTO, _, _, f_volume_sounds);
				CPrintToChatAll("%t", "Knife the first zombie", nome);
				IgniteEntity(attacker,12.0);
				ZR_InfectClient(attacker);
			}
		}
		else if(ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client) && (!contar))
		{
			contar = true;
			if(punishat_enable)
			{
				if(sounds_punish)	EmitSoundToAllAny(zr_punishment4, _, SNDCHAN_AUTO, _, _, f_volume_sounds);
				ZR_InfectClient(attacker);
				CPrintToChatAll("%t", "Attacker the first zombie Chat", nome);
				PrintHintTextToAll("%t", "Attacker the first zombie Center", nome);
			}
		}
	}
}

public Action ZR_OnClientInfect(int &client, int &attacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if (!IsValidClient(attacker))
	return Plugin_Continue;

	if(g_ZombieExplode[attacker])
	{
		g_ZombieExplode[attacker] = false;
		CPrintToChat(attacker, "%t", "You have saved");
		h_etime[attacker] = INVALID_HANDLE;
		KillBeacon(attacker);
	}
	return Plugin_Continue;
}

public Action ByeZM(Handle timer, Handle pack)
{
	int client;
	int attacker;
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	attacker = ReadPackCell(pack);

	if (IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientZombie(client) && g_ZombieExplode[client])
	{
		
		g_ZombieExplode[client] = false;
		int vida = GetClientHealth(client);
		float location[3];
		GetClientAbsOrigin(client, location);
		int ent = CreateEntityByName("env_explosion");
		SetEntProp(ent, Prop_Data, "m_iMagnitude", 300);
		SetEntProp(ent, Prop_Data, "m_iRadiusOverride", 350);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		DispatchSpawn(ent);
		TeleportEntity(ent, location, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent, "explode");
		float vec2[3];
		vec2 = location;
		vec2[2] = location[2] + 300.0;
		Lightning(location);
		spark(location);
		Explode1(location);
		Explode2(location);
		EmitAmbientSoundAny(EXPLODE_SOUND, vec2, client, SNDLEVEL_NORMAL, _, f_volume_explod);

		KillBeacon(client);
		h_etime[client] = INVALID_HANDLE;
		if (IsValidClient(attacker)){
			DealDamage(client,vida,attacker,DMG_GENERIC," "); // enemy down ;)
		}
		else ForcePlayerSuicide(client);
	}
}

public Action Lightning(float vec1[3])
{
	int g_lightning	 = PrecacheModel("materials/sprites/tp_beam001.vmt");
	float toppos[3];
	toppos[0] = vec1[0];
	toppos[1] = vec1[1];
	toppos[2] = vec1[2]+1000;
	int lightningcolor[4];
	lightningcolor[0]			   = 255;
	lightningcolor[1]			   = 255;
	lightningcolor[2]			   = 255;
	lightningcolor[3]			   = 255;
	float lightninglife		 = 0.1;
	float lightningwidth		= 40.0;
	float lightningendwidth	 = 10.0;
	int lightningstartframe		 = 0;
	int lightningframerate		  = 20;
	int lightningfadelength		 = 1;
	float lightningamplitude	= 20.0;
	int lightningspeed			  = 250;
	//raios
	
	int color[4] = {255, 255, 255, 255};
	
	// define the direction of the sparks
	float dir[3] = {0.0, 0.0, 0.0};
	
	TE_SetupBeamPoints(toppos, vec1, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();
	
	TE_SetupSparks(vec1, dir, 5000, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(vec1, dir, false);
	TE_SendToAll();
	
	TE_SetupSmoke(vec1, g_SmokeSprite, 5.0, 10);
	TE_SendToAll();
	TE_SetupBeamPoints(toppos, vec1, g_lightning, g_lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
	
	TE_SendToAll(0.0);
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(!kbooom_enable)	return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillBeacon(client);
	g_ZombieExplode[client] = false;
	if(ZR_IsClientZombie(client))
	{
		contar = true;
	}
}

public Action Timer_Beacon(Handle timer, any value)
{
	int client = value & 0x7f;
	int serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| h_btime[client] != serial)
	{
		KillBeacon(client);
		return Plugin_Stop;
	}
	
	if (IsClientInGame(client))
	{
		float vec[3];
		GetClientAbsOrigin(client, vec);
		int beaconColor[4];
		int modelindex = PrecacheModel("sprites/laser.vmt");
		int haloindex = PrecacheModel("sprites/glow_test02.vmt");

		int g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
		int g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");

		beaconColor[0] = 255;
		beaconColor[1] = 255;
		beaconColor[2] = 255;
		beaconColor[3] = 500;
		TE_SetupBeamRingPoint(vec, 10.0, 80.0, modelindex, haloindex, 0, 15, 0.6, 10.0, 0.5, beaconColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
		TE_SendToAll();
		//Red
		beaconColor[0] = 255;
		beaconColor[1] = 0;
		beaconColor[2] = 0;
		beaconColor[3] = 500;
		TE_SetupBeamRingPoint(vec, 210.0, 70.0, g_beamsprite, g_halosprite, 0, 15, 0.5, 10.0, 0.5, beaconColor, 100, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
		TE_SendToAll();
		//Green
		beaconColor[0] = 0;
		beaconColor[1] = 255;
		beaconColor[2] = 0;
		beaconColor[3] = 500;
		TE_SetupBeamRingPoint(vec, 10.0, 60.0, modelindex, haloindex, 0, 15, 0.4, 10.0, 0.5, beaconColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, 400.0, haloindex, modelindex, 1, 1, 0.2, 100.0, 1.0, beaconColor, 0, 0);
		TE_SendToAll();
		EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN, _, f_volume_sounds);
	}
	return Plugin_Continue;
}

void KillBeacon(int client)
{
	h_btime[client] = 0;
}

public void Explode1(float vec1[3])
{
	int color[4]={0,255,0,500};
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 500.0, orange, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
	TE_SendToAll();
}

public void Explode2(float vec1[3])
{
	vec1[2] += 10;
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
}

public void spark(float vec[3])
{
	float dir[3]={10.0,1.0,600.5000};//0.0,0.0,0.0
	TE_SetupSparks(vec, dir, 500, 50);
	TE_SendToAll();
}

stock void DealDamage(int nClientVictim, int nDamage, int nClientAttacker = 0, int nDamageType = DMG_GENERIC, char[] sWeapon = "")
{
	if(	nClientVictim > 0 &&
	   IsValidEdict(nClientVictim) &&
	   IsClientInGame(nClientVictim) &&
	   IsPlayerAlive(nClientVictim) &&
	   nDamage > 0)
	{
		int EntityPointHurt = CreateEntityByName("point_hurt");
		if(EntityPointHurt != 0)
		{
			char sDamage[16];
			IntToString(nDamage, sDamage, sizeof(sDamage));
			
			char sDamageType[32];
			IntToString(nDamageType, sDamageType, sizeof(sDamageType));
			
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"DamageTarget",	"war3_hurtme");
			DispatchKeyValue(EntityPointHurt,		"Damage",				sDamage);
			DispatchKeyValue(EntityPointHurt,		"DamageType",		sDamageType);
			if(!StrEqual(sWeapon, ""))
			DispatchKeyValue(EntityPointHurt,	"classname",		sWeapon);
			DispatchSpawn(EntityPointHurt);
			AcceptEntityInput(EntityPointHurt,	"Hurt",					(nClientAttacker != 0) ? nClientAttacker : -1);
			DispatchKeyValue(EntityPointHurt,		"classname",		"point_hurt");
			DispatchKeyValue(nClientVictim,			"targetname",		"war3_donthurtme");
			
			RemoveEdict(EntityPointHurt);
		}
	}
}