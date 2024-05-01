#define DAMAGE_RECIEVED
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>

static const COLOR[] = "^x04" //green
static const CONTACT[] = ""
new maxplayers
new gmsgSayText
new mpd, mkb, mhb
new g_MsgSync
new health_add
new health_hs_add
new health_max
new nKiller
new nKiller_hp
new nHp_add
new nHp_max
new g_awp_active
new g_menu_active
new CurrentRound
new bool:HasC4[33]
new bool:HasHE[33]
new bool:HasFL[33]
new bool:HasSM[33]

new bool:g_restart_attempt[33]
new bool:g_Spawned[33]
#define Keysrod (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9) // Keys: 1234567890
#if defined DAMAGE_RECIEVED
	new g_MsgSync2
#endif

public plugin_init()
{
	register_plugin("VIP Eng Version", "3.0", "Dunno")
	mpd = register_cvar("money_per_damage","3")
	mkb = register_cvar("money_kill_bonus","200")
	mhb = register_cvar("money_hs_bonus","500")
	health_add = register_cvar("amx_vip_hp", "15")
	health_hs_add = register_cvar("amx_vip_hp_hs", "30")
	health_max = register_cvar("amx_vip_max_hp", "100")
	g_awp_active = register_cvar("awp_active", "1")
	g_menu_active = register_cvar("menu_active", "1")
	register_event("Damage","Damage","b")
	register_event("DeathMsg","death_msg","a")
	register_menucmd(register_menuid("rod"), Keysrod, "Pressedrod")
	register_clcmd("awp","HandleCmd")
    	register_clcmd("sg550","HandleCmd")
    	register_clcmd("g3sg1","HandleCmd")
	register_clcmd("say /wantvip","ShowMotd")
	maxplayers = get_maxplayers()
	gmsgSayText = get_user_msgid("SayText")
	register_clcmd("say", "handle_say")
	register_cvar("amx_contactinfo", CONTACT, FCVAR_SERVER)
	register_logevent("LogEvent_RoundStart", 2, "1=Round_Start" );
	register_event("TextMsg","Event_RoundRestart","a","2&#Game_w")
	register_event("TextMsg","Event_RoundRestart","a","2&#Game_C");
	register_event("DeathMsg", "hook_death", "a", "1>0")
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")


	register_event("ResetHUD", "event_hud_reset", "be")
	register_event("TextMsg", "event_restart_attempt", "a", "2=#Game_will_restart_in")

	g_MsgSync = CreateHudSyncObj()
#if defined DAMAGE_RECIEVED
	g_MsgSync2 = CreateHudSyncObj()
#endif	
}

public client_connect(id)
{
	g_restart_attempt[id] = false
	g_Spawned[id] = false
}

public client_disconnected(id)
{
	g_restart_attempt[id] = false
	g_Spawned[id] = false
}

public event_restart_attempt()
{
	new players[32], num_players
	get_players(players, num_players, "a")
	for (new i; i < num_players; ++i)
		g_restart_attempt[players[i]] = true
}

public on_damage(id)
{
	new attacker = get_user_attacker(id)

#if defined DAMAGE_RECIEVED
	// id should be connected if this message is sent, but lets check anyway
	if ( is_user_connected(id) && is_user_connected(attacker) )
	if (get_user_flags(attacker) & ADMIN_LEVEL_H)
	{
		new damage = read_data(2)

		set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(id, g_MsgSync2, "%i^n", damage)
#else
	if ( is_user_connected(attacker) && if (get_user_flags(attacker) & ADMIN_LEVEL_H) )
	{
		new damage = read_data(2)
#endif
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_MsgSync, "%i^n", damage)
	}
}

public Damage(id)
{
	new weapon, hitpoint, attacker = get_user_attacker(id,weapon,hitpoint)
	if(attacker<=maxplayers && is_user_alive(attacker) && attacker!=id)
	if (get_user_flags(attacker) & ADMIN_LEVEL_H) 
	{
		new money = read_data(2) * get_pcvar_num(mpd)
		if(hitpoint==1) money += get_pcvar_num(mhb)
		cs_set_user_money(attacker,cs_get_user_money(attacker) + money)
	}
}

public death_msg()
{
	if(read_data(1)<=maxplayers && read_data(1) && read_data(1)!=read_data(2)) cs_set_user_money(read_data(1),cs_get_user_money(read_data(1)) + get_pcvar_num(mkb) - 300)
}

public LogEvent_RoundStart()
{
	CurrentRound++;
	new players[32], player, pnum;
	get_players(players, pnum, "a");
	for(new i = 0; i < pnum; i++)
	{
		player = players[i];
		if(is_user_alive(player) && get_user_flags(player) & ADMIN_LEVEL_H)
		{
			if (!get_pcvar_num(g_menu_active))
				return PLUGIN_CONTINUE
			
			if(CurrentRound >= 3)
			{
				Showrod(player);
			}
		}
	}
	return PLUGIN_HANDLED
}

public Event_RoundRestart()
{
	CurrentRound=0;
}

public hook_death()
{
   // Killer id
   nKiller = read_data(1)
   
   if ( (read_data(3) == 1) && (read_data(5) == 0) )
   {
      nHp_add = get_pcvar_num (health_hs_add)
   }
   else
      nHp_add = get_pcvar_num (health_add)
   nHp_max = get_pcvar_num (health_max)
   // Updating Killer HP
   if(!(get_user_flags(nKiller) & ADMIN_LEVEL_H))
   return;

   nKiller_hp = get_user_health(nKiller)
   nKiller_hp += nHp_add
   // Maximum HP check
   if (nKiller_hp > nHp_max) nKiller_hp = nHp_max
   set_user_health(nKiller, nKiller_hp)
   // Hud message "Healed +15/+30 hp"
   set_hudmessage(0, 255, 0, -1.0, 0.15, 0, 1.0, 1.0, 0.1, 0.1, -1)
   show_hudmessage(nKiller, "Healed +%d hp", nHp_add)
   // Screen fading
   message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, nKiller)
   write_short(1<<10)
   write_short(1<<10)
   write_short(0x0000)
   write_byte(0)
   write_byte(0)
   write_byte(200)
   write_byte(75)
   message_end()
 
}

public Showrod(id) {
	show_menu(id, Keysrod, "\rFree VIP Guns^n^n\y... Machine Guns ...^n\r1.\w Famas + Deagle^n\r2.\w M4A1 + Deagle ^n\r3.\w Galil + Deagle^n\r4.\w AK47 + Deagle^n^n\y... Sniper Rifle ...^n\r5.\w Scout + Deagle^n\r6.\w D3/AU1 + Deagle^n\r7.\w SG550 + Deagle^n\r8.\w AWP + Deagle^n^n\y... Submachine Guns ...^n\r9. \wMP5 + Deagle^n^n\r0.\w Exit^n",  floatround(60 * get_cvar_float("mp_buytime")), "rod") // Display menu
}
public Pressedrod(id, key) {
	HasC4[id] = false;
	HasHE[id] = false;
	HasFL[id] = false;
	HasSM[id] = false;
	if (user_has_weapon(id, CSW_C4) && get_user_team(id) == 1) HasC4[id] = true;
	if (user_has_weapon(id, CSW_HEGRENADE)) HasHE[id] = true;
	if (user_has_weapon(id, CSW_FLASHBANG)) HasFL[id] = true;
	if (user_has_weapon(id, CSW_SMOKEGRENADE)) HasSM[id] = true;
	switch (key) {
		case 0: { 
			strip_user_weapons (id)
			give_item(id,"weapon_famas")
			give_item(id,"ammo_556nato")
			give_item(id,"ammo_556nato")
			give_item(id,"ammo_556nato")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"weapon_knife")
			give_item(id, "item_assaultsuit");
			give_item(id, "item_thighpack");
			client_print(id, print_center, "You are rewarded Famas + Deagle")
			}
		case 1: { 
			strip_user_weapons (id)
			give_item(id,"weapon_m4a1")
			give_item(id,"ammo_556nato")
			give_item(id,"ammo_556nato")
			give_item(id,"ammo_556nato")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"weapon_knife")
			give_item(id, "item_assaultsuit");
			give_item(id, "item_thighpack");
			client_print(id, print_center, "You are rewarded M4A1 + Deagle")
			}
		case 2: { 
			strip_user_weapons (id)
			give_item(id,"weapon_galil")
			give_item(id,"ammo_556nato")
			give_item(id,"ammo_556nato")
			give_item(id,"ammo_556nato")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"weapon_knife")
			give_item(id, "item_assaultsuit");
			give_item(id, "item_thighpack");
			client_print(id, print_center, "You are rewarded Galil + Deagle")
			}
		case 3: { 
			strip_user_weapons (id)
			give_item(id,"weapon_ak47")
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"weapon_knife")
			give_item(id, "item_assaultsuit");
			give_item(id, "item_thighpack");
			client_print(id, print_center, "You are rewarded AK47 + Deagle")
			}
		case 4: { 
			strip_user_weapons (id)
			give_item(id,"weapon_scout")
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"weapon_knife")
			give_item(id, "item_assaultsuit");
			give_item(id, "item_thighpack");
			client_print(id, print_center, "You are rewarded Scout + Deagle")
			}
		case 5: { 
			strip_user_weapons (id)
			give_item(id,"weapon_g3sg1")
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
			give_item(id,"ammo_762nato")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"weapon_knife")
			give_item(id, "item_assaultsuit");
			give_item(id, "item_thighpack");
			client_print(id, print_center, "You are rewarded D3/AU1 + Deagle")
			}
		case 6: { 
			strip_user_weapons (id)
			give_item(id,"weapon_sg550")
			give_item(id,"ammo_556nato")
			give_item(id,"ammo_556nato")
			give_item(id,"ammo_556nato")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"weapon_knife")
			give_item(id, "item_assaultsuit");
			give_item(id, "item_thighpack");
			client_print(id, print_center, "You are rewarded SG550 + Deagle")
			}
		case 7: { 
			strip_user_weapons (id)
			give_item(id,"weapon_awp")
			give_item(id,"ammo_338magnum")
			give_item(id,"ammo_338magnum")
			give_item(id,"ammo_338magnum")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"weapon_knife")
			give_item(id, "item_assaultsuit");
			give_item(id, "item_thighpack");
			client_print(id, print_center, "You are rewarded SG550 + Deagle")
			
			}
		case 8: { 
			strip_user_weapons (id)
			give_item(id,"weapon_mp5navy")
			give_item(id,"ammo_9mm")
			give_item(id,"ammo_9mm")
			give_item(id,"ammo_9mm")
			give_item(id,"ammo_9mm")
			give_item(id,"ammo_9mm")
			give_item(id,"ammo_9mm")
			give_item(id,"weapon_deagle")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"ammo_50ae")
			give_item(id,"weapon_knife")
			give_item(id, "item_assaultsuit");
			give_item(id, "item_thighpack");
			client_print(id, print_center, "You are rewarded MP5 + Deagle")
			
			}
		case 9: { 			
		}
	}

	if (HasHE[id]) give_item(id, "weapon_hegrenade")
	if (HasFL[id]) give_item(id, "weapon_flashbang");
	if (HasFL[id]) give_item(id, "weapon_flashbang");
	if (HasSM[id]) give_item(id, "weapon_smokegrenade")

	if (HasC4[id])
	{
		give_item(id, "weapon_c4");
		cs_set_user_plant( id );
	}

	return PLUGIN_CONTINUE
}

public HandleCmd(id){
	if (!get_pcvar_num(g_awp_active))
      return PLUGIN_CONTINUE
	if(get_user_flags(id) & ADMIN_LEVEL_H) 
		return PLUGIN_CONTINUE
	client_print(id, print_center, "Sniper's Only For VIP's")
	return PLUGIN_HANDLED
}

public ShowMotd(id)
{
 show_motd(id, "vip.txt")
}
public client_authorized(id)
{
 set_task(30.0, "PrintText" , id, "", 0, "a", 5)
}
public PrintText(id)
{
 client_print(id, print_chat, "[VIP] Join Our Discord https://discord.gg/PDAmb6JrmU & Forum https://www.basement-gaming.net/ to get your Free VIP or Admin")
}

public handle_say(id) {
	new said[192]
	read_args(said,192)
	if( ( containi(said, "who") != -1 && containi(said, "admin") != -1 ) || contain(said, "/vips") != -1 )
		set_task(0.1,"print_adminlist",id)
	return PLUGIN_CONTINUE
}

public print_adminlist(user) 
{
	new adminnames[33][32]
	new message[256]
	new contactinfo[256], contact[112]
	new id, count, x, len
	
	for(id = 1 ; id <= maxplayers ; id++)
		if(is_user_connected(id))
			if(get_user_flags(id) & ADMIN_LEVEL_H)
				get_user_name(id, adminnames[count++], 31)

	len = format(message, 255, "%s VIP ONLINE: ",COLOR)
	if(count > 0) {
		for(x = 0 ; x < count ; x++) {
			len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"")
			if(len > 96 ) {
				print_message(user, message)
				len = format(message, 255, "%s ",COLOR)
			}
		}
		print_message(user, message)
	}
	else {
		len += format(message[len], 255-len, "No VIP online.")
		print_message(user, message)
	}
	
	get_cvar_string("amx_contactinfo", contact, 63)
	if(contact[0])  {
		format(contactinfo, 111, "%s Contact Server Admin -- %s", COLOR, contact)
		print_message(user, contactinfo)
	}
}

print_message(id, msg[]) {
	message_begin(MSG_ONE, gmsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}

public event_hud_reset(id)
{
	if (g_restart_attempt[id]) {
		g_restart_attempt[id] = false
		return
	}
	event_player_spawn(id)
}

public event_player_spawn(id)
{
	g_Spawned[id] = true
}

public client_PreThink(id)
{
	if (g_Spawned[id]) {
		g_Spawned[id] = false
		if(is_user_alive(id) && get_user_flags(id) & ADMIN_LEVEL_H) {
			give_item(id, "weapon_hegrenade")
			give_item(id, "weapon_flashbang")
			give_item(id, "weapon_flashbang")
			give_item(id, "weapon_smokegrenade")
			give_item(id, "item_assaultsuit")
			give_item(id, "item_thighpack")
		}
	}
	return PLUGIN_CONTINUE
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1063\\ f0\\ fs16 \n\\ par }
*/
