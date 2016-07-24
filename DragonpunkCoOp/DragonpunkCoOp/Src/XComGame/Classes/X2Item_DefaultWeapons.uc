class X2Item_DefaultWeapons extends X2Item config(GameData_WeaponData);

// Variables from config - GameData_WeaponData.ini
// ***** Damage arrays for attack actions  *****

var config int GENERIC_MELEE_ACCURACY;

var config WeaponDamageValue ASSAULTRIFLE_CONVENTIONAL_BASEDAMAGE;
var config WeaponDamageValue ASSAULTRIFLE_MAGNETIC_BASEDAMAGE;
var config WeaponDamageValue ASSAULTRIFLE_BEAM_BASEDAMAGE;

var config WeaponDamageValue LMG_CONVENTIONAL_BASEDAMAGE;
var config WeaponDamageValue LMG_MAGNETIC_BASEDAMAGE;
var config WeaponDamageValue LMG_BEAM_BASEDAMAGE;

var config WeaponDamageValue PISTOL_CONVENTIONAL_BASEDAMAGE;
var config WeaponDamageValue PISTOL_MAGNETIC_BASEDAMAGE;
var config WeaponDamageValue PISTOL_BEAM_BASEDAMAGE;

var config WeaponDamageValue SHOTGUN_CONVENTIONAL_BASEDAMAGE;
var config WeaponDamageValue SHOTGUN_MAGNETIC_BASEDAMAGE;
var config WeaponDamageValue SHOTGUN_BEAM_BASEDAMAGE;

var config WeaponDamageValue SNIPERRIFLE_CONVENTIONAL_BASEDAMAGE;
var config WeaponDamageValue SNIPERRIFLE_MAGNETIC_BASEDAMAGE;
var config WeaponDamageValue SNIPERRIFLE_BEAM_BASEDAMAGE;

var config WeaponDamageValue RANGERSWORD_CONVENTIONAL_BASEDAMAGE;
var config WeaponDamageValue RANGERSWORD_MAGNETIC_BASEDAMAGE;
var config WeaponDamageValue RANGERSWORD_BEAM_BASEDAMAGE;

// ***** Damage blocks for psipowers *****
var config array <WeaponDamageValue> PsiAmpT1_AbilityDamage;
var config array <WeaponDamageValue> PsiAmpT2_AbilityDamage;
var config array <WeaponDamageValue> PsiAmpT3_AbilityDamage;

var config array <WeaponDamageValue> GREMLINMK1_ABILITYDAMAGE;
var config array <WeaponDamageValue> GREMLINMK2_ABILITYDAMAGE;
var config array <WeaponDamageValue> GREMLINMK3_ABILITYDAMAGE;

var config WeaponDamageValue XCOMTURRETM1_WPN_BASEDAMAGE;
var config WeaponDamageValue XCOMTURRETM2_WPN_BASEDAMAGE;

var config WeaponDamageValue ASSAULTRIFLE_CENTRAL_BASEDAMAGE;

// ***** Advent and Alien RANGED Weapons *****
var config WeaponDamageValue ADVTROOPERM1_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVTURRETM1_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVCAPTAINM1_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVSTUNLANCERM1_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVMEC_M1_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVTROOPERM2_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVTURRETM2_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVCAPTAINM2_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVSTUNLANCERM2_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVSHIELDBEARERM2_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVPSIWITCHM2_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVMEC_M2_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVTROOPERM3_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVTURRETM3_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVCAPTAINM3_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVSTUNLANCERM3_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVSHIELDBEARERM3_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVPSIWITCHM3_WPN_BASEDAMAGE;
var config WeaponDamageValue SECTOID_WPN_BASEDAMAGE;
var config WeaponDamageValue MUTON_WPN_BASEDAMAGE;
var config WeaponDamageValue VIPER_WPN_BASEDAMAGE;
var config WeaponDamageValue CHRYSSALID_WPN_BASEDAMAGE;
var config WeaponDamageValue BERSERKER_WPN_BASEDAMAGE;
var config WeaponDamageValue ARCHON_WPN_BASEDAMAGE;
var config WeaponDamageValue FACELESS_WPN_BASEDAMAGE;
var config WeaponDamageValue ANDROMEDON_WPN_BASEDAMAGE;
var config WeaponDamageValue CYBERUS_WPN_BASEDAMAGE;
var config WeaponDamageValue GATEKEEPER_WPN_BASEDAMAGE;
var config WeaponDamageValue SECTOPOD_WPN_BASEDAMAGE;
var config WeaponDamageValue PROTOTYPESECTOPOD_WPN_BASEDAMAGE;
var config WeaponDamageValue ANDROMEDONROBOT_WPN_BASEDAMAGE;
var config WeaponDamageValue PSIZOMBIE_WPN_BASEDAMAGE;

// ***** Advent and Alien MELEE Weapons *****
var config WeaponDamageValue ADVSTUNLANCERM1_STUNLANCE_BASEDAMAGE;
var config WeaponDamageValue ADVSTUNLANCERM2_STUNLANCE_BASEDAMAGE;
var config WeaponDamageValue ADVSTUNLANCERM3_STUNLANCE_BASEDAMAGE;
var config WeaponDamageValue ANDROMEDONROBOT_MELEEATTACK_BASEDAMAGE;
var config WeaponDamageValue ARCHON_MELEEATTACK_BASEDAMAGE;
var config WeaponDamageValue BERSERKER_MELEEATTACK_BASEDAMAGE;
var config WeaponDamageValue BERSERKER_MELEEATTACK_MISSDAMAGE;
var config WeaponDamageValue CHRYSSALID_MELEEATTACK_BASEDAMAGE;
var config WeaponDamageValue FACELESS_MELEEAOE_BASEDAMAGE;
var config WeaponDamageValue MUTON_MELEEATTACK_BASEDAMAGE;
var config WeaponDamageValue PSIZOMBIE_MELEEATTACK_BASEDAMAGE;

// ***** MP Weapon Damage *****
var config WeaponDamageValue ADVTROOPERMP_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVCAPTAINMP_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVSTUNLANCERMP_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVMEC_MP_WPN_BASEDAMAGE;
var config WeaponDamageValue ADVSHIELDBEARERMP_WPN_BASEDAMAGE;
var config WeaponDamageValue SECTOIDMP_WPN_BASEDAMAGE;
var config WeaponDamageValue MUTONMP_WPN_BASEDAMAGE;
var config WeaponDamageValue VIPERMP_WPN_BASEDAMAGE;
var config WeaponDamageValue ARCHONMP_WPN_BASEDAMAGE;
var config WeaponDamageValue ANDROMEDONMP_WPN_BASEDAMAGE;
var config WeaponDamageValue CYBERUSMP_WPN_BASEDAMAGE;
var config WeaponDamageValue GATEKEEPERMP_WPN_BASEDAMAGE;
var config WeaponDamageValue SECTOPODMP_WPN_BASEDAMAGE;

// ***** MP Melee Damage *****
var config WeaponDamageValue ANDROMEDONROBOTMP_MELEEATTACK_BASEDAMAGE;
var config WeaponDamageValue BERSERKERMP_MELEEATTACK_BASEDAMAGE;
var config WeaponDamageValue CHRYSSALIDMP_MELEEATTACK_BASEDAMAGE;
var config WeaponDamageValue FACELESSMP_MELEEAOE_BASEDAMAGE;
var config WeaponDamageValue PSIZOMBIEMP_MELEEATTACK_BASEDAMAGE;

// ***** Data values for specific enemy abilities *****
var config WeaponDamageValue ADVMEC_M1_MICROMISSILES_BASEDAMAGE;
var config WeaponDamageValue ADVMEC_M2_MICROMISSILES_BASEDAMAGE;
var config WeaponDamageValue ADVPSIWITCHM2_PSI_DIMENSIONALRIFT_BASEDAMAGE;
var config array<WeaponDamageValue> AVATAR_PLAYER_PSIAMP_ABILITYDAMAGE;
var config array<WeaponDamageValue> AVATAR_AI_PSIAMP_ABILITYDAMAGE;
var config WeaponDamageValue ANDROMEDON_ACIDBLOB_BASEDAMAGE;
var config WeaponDamageValue ANDROMEDONROBOT_EMITACIDCLOUD_BASEDAMAGE;
var config WeaponDamageValue ARCHON_BLAZINGPINIONS_BASEDAMAGE;
var config int               ARCHON_BLAZINGPINIONS_ENVDAMAGE;
var config WeaponDamageValue CHRYSSALID_PARTHENOGENICPOISON_BASEDAMAGE;
var config WeaponDamageValue CYBERUS_MALFUNCTION_BASEDAMAGE;
var config WeaponDamageValue CYBERUS_TELEPORT_BASEDAMAGE;
var config WeaponDamageValue CYBERUS_PSI_BOMB_BASEDAMAGE;
var config WeaponDamageValue GATEKEEPER_ANIMACONSUME_BASEDAMAGE;
var config WeaponDamageValue GATEKEEPER_MASS_PSI_REANIMATION_BASEDAMAGE;
var config WeaponDamageValue GATEKEEPER_DEATH_EXPLOSION_BASEDAMAGE;
var config WeaponDamageValue SECTOID_PSI_DEATHDETONATION_BASEDAMAGE;
var config WeaponDamageValue SECTOPOD_WRATHCANNON_BASEDAMAGE;
var config WeaponDamageValue PROTOTYPESECTOPOD_WRATHCANNON_BASEDAMAGE;
var config WeaponDamageValue SECTOPOD_LIGHTINGFIELD_BASEDAMAGE;
var config WeaponDamageValue VIPER_BIND_BASEDAMAGE;

// ***** Core properties and variables for weapons *****
var config int ASSAULTRIFLE_CONVENTIONAL_AIM;
var config int ASSAULTRIFLE_CONVENTIONAL_CRITCHANCE;
var config int ASSAULTRIFLE_CONVENTIONAL_ICLIPSIZE;
var config int ASSAULTRIFLE_CONVENTIONAL_ISOUNDRANGE;
var config int ASSAULTRIFLE_CONVENTIONAL_IENVIRONMENTDAMAGE;
var config int ASSAULTRIFLE_CONVENTIONAL_ISUPPLIES;
var config int ASSAULTRIFLE_CONVENTIONAL_TRADINGPOSTVALUE;
var config int ASSAULTRIFLE_CONVENTIONAL_IPOINTS;

var config int ASSAULTRIFLE_MAGNETIC_AIM;
var config int ASSAULTRIFLE_MAGNETIC_CRITCHANCE;
var config int ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
var config int ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
var config int ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
var config int ASSAULTRIFLE_MAGNETIC_ISUPPLIES;
var config int ASSAULTRIFLE_MAGNETIC_TRADINGPOSTVALUE;
var config int ASSAULTRIFLE_MAGNETIC_IPOINTS;

var config int ASSAULTRIFLE_BEAM_AIM;
var config int ASSAULTRIFLE_BEAM_CRITCHANCE;
var config int ASSAULTRIFLE_BEAM_ICLIPSIZE;
var config int ASSAULTRIFLE_BEAM_ISOUNDRANGE;
var config int ASSAULTRIFLE_BEAM_IENVIRONMENTDAMAGE;
var config int ASSAULTRIFLE_BEAM_ISUPPLIES;
var config int ASSAULTRIFLE_BEAM_TRADINGPOSTVALUE;
var config int ASSAULTRIFLE_BEAM_IPOINTS;

var config int LMG_CONVENTIONAL_AIM;
var config int LMG_CONVENTIONAL_CRITCHANCE;
var config int LMG_CONVENTIONAL_ICLIPSIZE;
var config int LMG_CONVENTIONAL_ISOUNDRANGE;
var config int LMG_CONVENTIONAL_IENVIRONMENTDAMAGE;
var config int LMG_CONVENTIONAL_ISUPPLIES;
var config int LMG_CONVENTIONAL_TRADINGPOSTVALUE;
var config int LMG_CONVENTIONAL_IPOINTS;

var config int LMG_MAGNETIC_AIM;
var config int LMG_MAGNETIC_CRITCHANCE;
var config int LMG_MAGNETIC_ICLIPSIZE;
var config int LMG_MAGNETIC_ISOUNDRANGE;
var config int LMG_MAGNETIC_IENVIRONMENTDAMAGE;
var config int LMG_MAGNETIC_ISUPPLIES;
var config int LMG_MAGNETIC_TRADINGPOSTVALUE;
var config int LMG_MAGNETIC_IPOINTS;

var config int LMG_BEAM_AIM;
var config int LMG_BEAM_CRITCHANCE;
var config int LMG_BEAM_ICLIPSIZE;
var config int LMG_BEAM_ISOUNDRANGE;
var config int LMG_BEAM_IENVIRONMENTDAMAGE;
var config int LMG_BEAM_ISUPPLIES;
var config int LMG_BEAM_TRADINGPOSTVALUE;
var config int LMG_BEAM_IPOINTS;

var config int PISTOL_CONVENTIONAL_AIM;
var config int PISTOL_CONVENTIONAL_CRITCHANCE;
var config int PISTOL_CONVENTIONAL_ICLIPSIZE;
var config int PISTOL_CONVENTIONAL_ISOUNDRANGE;
var config int PISTOL_CONVENTIONAL_IENVIRONMENTDAMAGE;
var config int PISTOL_CONVENTIONAL_ISUPPLIES;
var config int PISTOL_CONVENTIONAL_TRADINGPOSTVALUE;
var config int PISTOL_CONVENTIONAL_IPOINTS;

var config int PISTOL_MAGNETIC_AIM;
var config int PISTOL_MAGNETIC_CRITCHANCE;
var config int PISTOL_MAGNETIC_ICLIPSIZE;
var config int PISTOL_MAGNETIC_ISOUNDRANGE;
var config int PISTOL_MAGNETIC_IENVIRONMENTDAMAGE;
var config int PISTOL_MAGNETIC_ISUPPLIES;
var config int PISTOL_MAGNETIC_TRADINGPOSTVALUE;
var config int PISTOL_MAGNETIC_IPOINTS;

var config int PISTOL_BEAM_AIM;
var config int PISTOL_BEAM_CRITCHANCE;
var config int PISTOL_BEAM_ICLIPSIZE;
var config int PISTOL_BEAM_ISOUNDRANGE;
var config int PISTOL_BEAM_IENVIRONMENTDAMAGE;
var config int PISTOL_BEAM_ISUPPLIES;
var config int PISTOL_BEAM_TRADINGPOSTVALUE;
var config int PISTOL_BEAM_IPOINTS;

var config int SHOTGUN_CONVENTIONAL_AIM;
var config int SHOTGUN_CONVENTIONAL_CRITCHANCE;
var config int SHOTGUN_CONVENTIONAL_ICLIPSIZE;
var config int SHOTGUN_CONVENTIONAL_ISOUNDRANGE;
var config int SHOTGUN_CONVENTIONAL_IENVIRONMENTDAMAGE;
var config int SHOTGUN_CONVENTIONAL_ISUPPLIES;
var config int SHOTGUN_CONVENTIONAL_TRADINGPOSTVALUE;
var config int SHOTGUN_CONVENTIONAL_IPOINTS;

var config int SHOTGUN_MAGNETIC_AIM;
var config int SHOTGUN_MAGNETIC_CRITCHANCE;
var config int SHOTGUN_MAGNETIC_ICLIPSIZE;
var config int SHOTGUN_MAGNETIC_ISOUNDRANGE;
var config int SHOTGUN_MAGNETIC_IENVIRONMENTDAMAGE;
var config int SHOTGUN_MAGNETIC_ISUPPLIES;
var config int SHOTGUN_MAGNETIC_TRADINGPOSTVALUE;
var config int SHOTGUN_MAGNETIC_IPOINTS;

var config int SHOTGUN_BEAM_AIM;
var config int SHOTGUN_BEAM_CRITCHANCE;
var config int SHOTGUN_BEAM_ICLIPSIZE;
var config int SHOTGUN_BEAM_ISOUNDRANGE;
var config int SHOTGUN_BEAM_IENVIRONMENTDAMAGE;
var config int SHOTGUN_BEAM_ISUPPLIES;
var config int SHOTGUN_BEAM_TRADINGPOSTVALUE;
var config int SHOTGUN_BEAM_IPOINTS;

var config int SNIPERRIFLE_CONVENTIONAL_AIM;
var config int SNIPERRIFLE_CONVENTIONAL_CRITCHANCE;
var config int SNIPERRIFLE_CONVENTIONAL_ICLIPSIZE;
var config int SNIPERRIFLE_CONVENTIONAL_ISOUNDRANGE;
var config int SNIPERRIFLE_CONVENTIONAL_IENVIRONMENTDAMAGE;
var config int SNIPERRIFLE_CONVENTIONAL_ISUPPLIES;
var config int SNIPERRIFLE_CONVENTIONAL_TRADINGPOSTVALUE;
var config int SNIPERRIFLE_CONVENTIONAL_IPOINTS;

var config int SNIPERRIFLE_MAGNETIC_AIM;
var config int SNIPERRIFLE_MAGNETIC_CRITCHANCE;
var config int SNIPERRIFLE_MAGNETIC_ICLIPSIZE;
var config int SNIPERRIFLE_MAGNETIC_ISOUNDRANGE;
var config int SNIPERRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
var config int SNIPERRIFLE_MAGNETIC_ISUPPLIES;
var config int SNIPERRIFLE_MAGNETIC_TRADINGPOSTVALUE;
var config int SNIPERRIFLE_MAGNETIC_IPOINTS;

var config int SNIPERRIFLE_BEAM_AIM;
var config int SNIPERRIFLE_BEAM_CRITCHANCE;
var config int SNIPERRIFLE_BEAM_ICLIPSIZE;
var config int SNIPERRIFLE_BEAM_ISOUNDRANGE;
var config int SNIPERRIFLE_BEAM_IENVIRONMENTDAMAGE;
var config int SNIPERRIFLE_BEAM_ISUPPLIES;
var config int SNIPERRIFLE_BEAM_TRADINGPOSTVALUE;
var config int SNIPERRIFLE_BEAM_IPOINTS;

var config int RANGERSWORD_CONVENTIONAL_AIM;
var config int RANGERSWORD_CONVENTIONAL_CRITCHANCE;
var config int RANGERSWORD_CONVENTIONAL_ICLIPSIZE;
var config int RANGERSWORD_CONVENTIONAL_ISOUNDRANGE;
var config int RANGERSWORD_CONVENTIONAL_IENVIRONMENTDAMAGE;
var config int RANGERSWORD_CONVENTIONAL_ISUPPLIES;
var config int RANGERSWORD_CONVENTIONAL_TRADINGPOSTVALUE;
var config int RANGERSWORD_CONVENTIONAL_IPOINTS;

var config int RANGERSWORD_MAGNETIC_AIM;
var config int RANGERSWORD_MAGNETIC_CRITCHANCE;
var config int RANGERSWORD_MAGNETIC_ICLIPSIZE;
var config int RANGERSWORD_MAGNETIC_ISOUNDRANGE;
var config int RANGERSWORD_MAGNETIC_IENVIRONMENTDAMAGE;
var config int RANGERSWORD_MAGNETIC_ISUPPLIES;
var config int RANGERSWORD_MAGNETIC_TRADINGPOSTVALUE;
var config int RANGERSWORD_MAGNETIC_IPOINTS;
var config int RANGERSWORD_MAGNETIC_STUNCHANCE;

var config int RANGERSWORD_BEAM_AIM;
var config int RANGERSWORD_BEAM_CRITCHANCE;
var config int RANGERSWORD_BEAM_ICLIPSIZE;
var config int RANGERSWORD_BEAM_ISOUNDRANGE;
var config int RANGERSWORD_BEAM_IENVIRONMENTDAMAGE;
var config int RANGERSWORD_BEAM_ISUPPLIES;
var config int RANGERSWORD_BEAM_TRADINGPOSTVALUE;
var config int RANGERSWORD_BEAM_IPOINTS;

var config int PSIAMP_CONVENTIONAL_ISOUNDRANGE;
var config int PSIAMP_CONVENTIONAL_IENVIRONMENTDAMAGE;
var config int PSIAMP_CONVENTIONAL_ISUPPLIES;
var config int PSIAMP_CONVENTIONAL_TRADINGPOSTVALUE;
var config int PSIAMP_CONVENTIONAL_IPOINTS;

var config int PSIAMP_MAGNETIC_ISOUNDRANGE;
var config int PSIAMP_MAGNETIC_IENVIRONMENTDAMAGE;
var config int PSIAMP_MAGNETIC_ISUPPLIES;
var config int PSIAMP_MAGNETIC_TRADINGPOSTVALUE;
var config int PSIAMP_MAGNETIC_IPOINTS;

var config int PSIAMP_BEAM_ISOUNDRANGE;
var config int PSIAMP_BEAM_IENVIRONMENTDAMAGE;
var config int PSIAMP_BEAM_ISUPPLIES;
var config int PSIAMP_BEAM_TRADINGPOSTVALUE;
var config int PSIAMP_BEAM_IPOINTS;

var config int GREMLIN_ISOUNDRANGE;
var config int GREMLIN_IENVIRONMENTDAMAGE;
var config int GREMLIN_ISUPPLIES;
var config int GREMLIN_TRADINGPOSTVALUE;
var config int GREMLIN_IPOINTS;
var config int GREMLIN_HACKBONUS;

var config int GREMLINMK2_ISOUNDRANGE;
var config int GREMLINMK2_IENVIRONMENTDAMAGE;
var config int GREMLINMK2_ISUPPLIES;
var config int GREMLINMK2_TRADINGPOSTVALUE;
var config int GREMLINMK2_IPOINTS;
var config int GREMLINMK2_HACKBONUS;

var config int GREMLINMK3_ISOUNDRANGE;
var config int GREMLINMK3_IENVIRONMENTDAMAGE;
var config int GREMLINMK3_ISUPPLIES;
var config int GREMLINMK3_TRADINGPOSTVALUE;
var config int GREMLINMK3_IPOINTS;
var config int GREMLINMK3_HACKBONUS;

var config int ADVTROOPERM1_IDEALRANGE;
var config int ADVTURRETM1_IDEALRANGE;
var config int ADVCAPTAINM1_IDEALRANGE;
var config int ADVSTUNLANCERM1_IDEALRANGE;
var config int ADVTROOPERM2_IDEALRANGE;
var config int ADVTURRETM2_IDEALRANGE;
var config int ADVCAPTAINM2_IDEALRANGE;
var config int ADVSTUNLANCERM2_IDEALRANGE;
var config int ADVSHIELDBEARERM2_IDEALRANGE;
var config int ADVPSIWITCHM2_IDEALRANGE;
var config int ADVMEC_M1_IDEALRANGE;
var config int ADVTROOPERM3_IDEALRANGE;
var config int ADVTURRETM3_IDEALRANGE;
var config int ADVCAPTAINM3_IDEALRANGE;
var config int ADVSTUNLANCERM3_IDEALRANGE;
var config int ADVSHIELDBEARERM3_IDEALRANGE;
var config int ADVPSIWITCHM3_IDEALRANGE;
var config int ADVMEC_M2_IDEALRANGE;
var config int SECTOID_IDEALRANGE;
var config int ANDROMEDON_IDEALRANGE;
var config int VIPER_IDEALRANGE;
var config int CHRYSSALID_IDEALRANGE;
var config int MUTON_IDEALRANGE;
var config int FACELESS_IDEALRANGE;
var config int ARCHON_IDEALRANGE;
var config int CYBERUS_IDEALRANGE;
var config int BERSERKER_IDEALRANGE;
var config int GATEKEEPER_IDEALRANGE;
var config int PROTOTYPESECTOPOD_IDEALRANGE;
var config int SECTOPOD_IDEALRANGE;
var config int ANDROMEDONROBOT_IDEALRANGE;
var config int PSIZOMBIE_IDEALRANGE;

// ***** Range Modifier Tables *****
var config array<int> SHORT_CONVENTIONAL_RANGE;
var config array<int> SHORT_MAGNETIC_RANGE;
var config array<int> SHORT_BEAM_RANGE;
var config array<int> MEDIUM_CONVENTIONAL_RANGE;
var config array<int> MEDIUM_MAGNETIC_RANGE;
var config array<int> MEDIUM_BEAM_RANGE;
var config array<int> LONG_CONVENTIONAL_RANGE;
var config array<int> LONG_MAGNETIC_RANGE;
var config array<int> LONG_BEAM_RANGE;
var config array<int> FLAT_CONVENTIONAL_RANGE;
var config array<int> FLAT_MAGNETIC_RANGE;
var config array<int> FLAT_BEAM_RANGE;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Weapons;
	
	Weapons.AddItem(CreateTemplate_Shotgun_Conventional());
	Weapons.AddItem(CreateTemplate_Shotgun_Magnetic());
	Weapons.AddItem(CreateTemplate_Shotgun_Beam());

	Weapons.AddItem(CreateTemplate_Cannon_Conventional());
	Weapons.AddItem(CreateTemplate_Cannon_Magnetic());
	Weapons.AddItem(CreateTemplate_Cannon_Beam());

	Weapons.AddItem(CreateTemplate_Pistol_Conventional());
	Weapons.AddItem(CreateTemplate_Pistol_Magnetic());
	Weapons.AddItem(CreateTemplate_Pistol_Beam());

	Weapons.AddItem(CreateTemplate_SniperRifle_Conventional());
	Weapons.AddItem(CreateTemplate_SniperRifle_Magnetic());
	Weapons.AddItem(CreateTemplate_SniperRifle_Beam());
	
	Weapons.AddItem(CreateTemplate_AssaultRifle_Conventional());
	Weapons.AddItem(CreateTemplate_AssaultRifle_Magnetic());
	Weapons.AddItem(CreateTemplate_AssaultRifle_Beam());

	Weapons.AddItem(CreateTemplate_Sword_Conventional());
	Weapons.AddItem(CreateTemplate_Sword_Magnetic());
	Weapons.AddItem(CreateTemplate_Sword_Beam());

	Weapons.AddItem(CreateTemplate_PsiAmp_Conventional());
	Weapons.AddItem(CreateTemplate_PsiAmp_Magnetic());
	Weapons.AddItem(CreateTemplate_PsiAmp_Beam());

	Weapons.AddItem(CreateTemplate_GremlinDrone_Conventional());
	Weapons.AddItem(CreateTemplate_GremlinDrone_Magnetic());
	Weapons.AddItem(CreateTemplate_GremlinDrone_Beam());
	Weapons.AddItem(CreateTemplate_GremlinDrone_MP());

	Weapons.AddItem(CreateTemplate_XComTurretM1_WPN());
	Weapons.AddItem(CreateTemplate_XComTurretM2_WPN());

	Weapons.AddItem(CreateTemplate_AssaultRifle_Central());

	Weapons.AddItem(CreateAssaultRifleMagneticAdventTemplate());

	// *********************************
	// enemy weapons
	Weapons.AddItem(CreateTemplate_AdvTrooperM1_WPN());
	Weapons.AddItem(CreateTemplate_AdvTurretM1_WPN());
	Weapons.AddItem(CreateTemplate_AdvShortTurretM1_WPN());
	Weapons.AddItem(CreateTemplate_AdvCaptainM1_WPN());
	Weapons.AddItem(CreateTemplate_AdvStunLancerM1_WPN());
	Weapons.AddItem(CreateTemplate_AdvTrooperM2_WPN());
	Weapons.AddItem(CreateTemplate_AdvTurretM2_WPN());
	Weapons.AddItem(CreateTemplate_AdvCaptainM2_WPN());
	Weapons.AddItem(CreateTemplate_AdvStunLancerM2_WPN());
	Weapons.AddItem(CreateTemplate_AdvShieldBearerM2_WPN());
	Weapons.AddItem(CreateTemplate_AdvPsiWitchM2_WPN());
	Weapons.AddItem(CreateTemplate_AdvPsiWitchM2_PsiAmp());
	Weapons.AddItem(CreateTemplate_AdvMEC_M2_WPN());
	Weapons.AddItem(CreateTemplate_AdvMEC_M2_Shoulder_WPN());
	Weapons.AddItem(CreateTemplate_AdvTrooperM3_WPN());
	Weapons.AddItem(CreateTemplate_AdvTurretM3_WPN());
	Weapons.AddItem(CreateTemplate_AdvCaptainM3_WPN());
	Weapons.AddItem(CreateTemplate_AdvStunLancerM3_WPN());
	Weapons.AddItem(CreateTemplate_AdvShieldBearerM3_WPN());
	Weapons.AddItem(CreateTemplate_AdvPsiWitchM3_WPN());
	Weapons.AddItem(CreateTemplate_AdvPsiWitchM3_PsiAmp());
	Weapons.AddItem(CreateTemplate_AdvMEC_M1_WPN());
	Weapons.AddItem(CreateTemplate_AdvMEC_M1_Shoulder_WPN());
	Weapons.AddItem(CreateTemplate_Andromedon_WPN());
	Weapons.AddItem(CreateTemplate_AndromedonRobot_WPN());
	Weapons.AddItem(CreateTemplate_Archon_WPN());
	Weapons.AddItem(CreateTemplate_Archon_Blazing_Pinions_WPN());
	Weapons.AddItem(CreateTemplate_Cyberus_WPN());
	Weapons.AddItem(CreateTemplate_Gatekeeper_WPN());
	Weapons.AddItem(CreateTemplate_Muton_WPN());
	Weapons.AddItem(CreateTemplate_Sectoid_WPN());
	Weapons.AddItem(CreateTemplate_Sectopod_WPN());
	Weapons.AddItem(CreateTemplate_Sectopod_WrathCannon_WPN());
	Weapons.AddItem(CreateTemplate_PrototypeSectopod_WPN());
	Weapons.AddItem(CreateTemplate_PrototypeSectopod_WrathCannon_WPN());

	Weapons.AddItem(CreateTemplate_Viper_WPN());
	Weapons.AddItem(CreateTemplate_Viper_Tongue_WPN());

	Weapons.AddItem(CreateTemplate_AdvStunLancerM1_StunLance());
	Weapons.AddItem(CreateTemplate_AdvStunLancerM2_StunLance());
	Weapons.AddItem(CreateTemplate_AdvStunLancerM3_StunLance());
	Weapons.AddItem(CreateTemplate_AndromedonRobot_MeleeAttack());
	Weapons.AddItem(CreateTemplate_Archon_MeleeAttack());
	//Weapons.AddItem(CreateTemplate_Berserker_MeleeAttack());
	Weapons.AddItem(CreateTemplate_Faceless_MeleeAoE());
	Weapons.AddItem(CreateTemplate_Muton_MeleeAttack());
	Weapons.AddItem(CreateTemplate_PsiZombie_MeleeAttack());

	// MP Weapons
	Weapons.AddItem(CreateTemplate_AdvTrooperMP_WPN());
	Weapons.AddItem(CreateTemplate_AdvCaptainMP_WPN());
	Weapons.AddItem(CreateTemplate_AdvStunLancerMP_WPN());
	Weapons.AddItem(CreateTemplate_AdvShieldBearerMP_WPN());
	Weapons.AddItem(CreateTemplate_AdvMEC_MP_WPN());
	Weapons.AddItem(CreateTemplate_SectoidMP_WPN());
	Weapons.AddItem(CreateTemplate_ViperMP_WPN());
	Weapons.AddItem(CreateTemplate_MutonMP_WPN());
	Weapons.AddItem(CreateTemplate_CyberusMP_WPN());
	Weapons.AddItem(CreateTemplate_ArchonMP_WPN());
	Weapons.AddItem(CreateTemplate_AndromedonMP_WPN());
	Weapons.AddItem(CreateTemplate_SectopodMP_WPN());
	Weapons.AddItem(CreateTemplate_GatekeeperMP_WPN());
	Weapons.AddItem(CreateTemplate_PsiZombieMP_MeleeAttack());

	return Weapons;
}

// **********************************************************************************************************
// ***                                            Player Weapons                                          ***
// **********************************************************************************************************

// **************************************************************************
// ***                          AssaultRifle                              ***
// **************************************************************************
static function X2DataTemplate CreateTemplate_AssaultRifle_Conventional()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AssaultRifle_CV');
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.EquipSound = "Conventional_Weapon_Equip";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_Base";
	Template.Tier = 0;

	Template.RangeAccuracy = default.MEDIUM_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ASSAULTRIFLE_CONVENTIONAL_BASEDAMAGE;
	Template.Aim = default.ASSAULTRIFLE_CONVENTIONAL_AIM;
	Template.CritChance = default.ASSAULTRIFLE_CONVENTIONAL_CRITCHANCE;
	Template.iClipSize = default.ASSAULTRIFLE_CONVENTIONAL_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_CONVENTIONAL_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_CONVENTIONAL_IENVIRONMENTDAMAGE;

	Template.NumUpgradeSlots = 1;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_CV.WP_AssaultRifle_CV";

	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_AssaultRifle';
	Template.AddDefaultAttachment('Mag', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_MagA", , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_MagA");
	Template.AddDefaultAttachment('Optic', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_OpticA", , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_OpticA");
	Template.AddDefaultAttachment('Reargrip', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_ReargripA", , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_ReargripA");
	Template.AddDefaultAttachment('Stock', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_StockA", , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_StockA");
	Template.AddDefaultAttachment('Trigger', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_TriggerA", , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_TriggerA");
	Template.AddDefaultAttachment('Light', "ConvAttachments.Meshes.SM_ConvFlashLight", , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_LightA");

	Template.iPhysicsImpulse = 5;

	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;
	
	Template.fKnockbackDamageAmount = 5.0f;
	Template.fKnockbackDamageRadius = 0.0f;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';
	
	return Template;
}

static function X2DataTemplate CreateTemplate_AssaultRifle_Magnetic()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AssaultRifle_MG');
	Template.WeaponPanelImage = "_MagneticRifle";                       // used by the UI. Probably determines iconview of the weapon.

	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.ItemCat = 'weapon';
	Template.strImage = "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_Base";
	Template.EquipSound = "Magnetic_Weapon_Equip";
	Template.Tier = 2;

	Template.RangeAccuracy = default.MEDIUM_MAGNETIC_RANGE;
	Template.BaseDamage = default.ASSAULTRIFLE_MAGNETIC_BASEDAMAGE;
	Template.Aim = default.ASSAULTRIFLE_MAGNETIC_AIM;
	Template.CritChance = default.ASSAULTRIFLE_MAGNETIC_CRITCHANCE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;

	Template.NumUpgradeSlots = 2;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_AssaultRifle';
	Template.AddDefaultAttachment('Mag', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_MagA", , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_MagA");
	Template.AddDefaultAttachment('Suppressor', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_SuppressorA", , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_SupressorA");
	Template.AddDefaultAttachment('Reargrip', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_ReargripA", , /* included with TriggerA */);
	Template.AddDefaultAttachment('Stock', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_StockA", , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_StockA");
	Template.AddDefaultAttachment('Trigger', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_TriggerA", , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_TriggerA");
	Template.AddDefaultAttachment('Light', "ConvAttachments.Meshes.SM_ConvFlashLight");

	Template.iPhysicsImpulse = 5;
	
	Template.CreatorTemplateName = 'AssaultRifle_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'AssaultRifle_CV'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_MagXCom';

	return Template;
}

static function X2DataTemplate CreateTemplate_AssaultRifle_Beam()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AssaultRifle_BM');
	Template.WeaponPanelImage = "_BeamRifle";                       // used by the UI. Probably determines iconview of the weapon.

	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'beam';
	Template.ItemCat = 'weapon';
	Template.strImage = "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_Base";
	Template.EquipSound = "Beam_Weapon_Equip";
	Template.Tier = 4;

	Template.RangeAccuracy = default.MEDIUM_BEAM_RANGE;
	Template.BaseDamage = default.ASSAULTRIFLE_BEAM_BASEDAMAGE;
	Template.Aim = default.ASSAULTRIFLE_BEAM_AIM;
	Template.CritChance = default.ASSAULTRIFLE_BEAM_CRITCHANCE;
	Template.iClipSize = default.ASSAULTRIFLE_BEAM_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_BEAM_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_BEAM_IENVIRONMENTDAMAGE;

	Template.NumUpgradeSlots = 2;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	Template.GameArchetype = "WP_AssaultRifle_BM.WP_AssaultRifle_BM";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_AssaultRifle';
	Template.AddDefaultAttachment('Mag', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_MagA", , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_MagA");
	Template.AddDefaultAttachment('Suppressor', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_SuppressorA", , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_SupressorA");
	Template.AddDefaultAttachment('Core', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_CoreA", , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_CoreA");
	Template.AddDefaultAttachment('HeatSink', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_HeatSinkA", , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_HeatsinkA");
	Template.AddDefaultAttachment('Light', "BeamAttachments.Meshes.BeamFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.CreatorTemplateName = 'AssaultRifle_BM_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'AssaultRifle_MG'; // Which item this will be upgraded from

	Template.DamageTypeTemplateName = 'Projectile_BeamXCom';

	return Template;
}

// **************************************************************************
// ***                          Pistol                                    ***
// **************************************************************************
static function X2DataTemplate CreateTemplate_Pistol_Conventional()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Pistol_CV');
	Template.WeaponPanelImage = "_Pistol";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'pistol';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.ConvSecondaryWeapons.ConvPistol";
	Template.EquipSound = "Secondary_Weapon_Equip_Conventional";
	Template.Tier = 0;

	Template.RangeAccuracy = default.SHORT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.PISTOL_CONVENTIONAL_BASEDAMAGE;
	Template.Aim = default.PISTOL_CONVENTIONAL_AIM;
	Template.CritChance = default.PISTOL_CONVENTIONAL_CRITCHANCE;
	Template.iClipSize = default.PISTOL_CONVENTIONAL_ICLIPSIZE;
	Template.iSoundRange = default.PISTOL_CONVENTIONAL_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.PISTOL_CONVENTIONAL_IENVIRONMENTDAMAGE;

	Template.NumUpgradeSlots = 1;

	Template.InfiniteAmmo = true;
	Template.OverwatchActionPoint = class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint;
	
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.Abilities.AddItem('PistolOverwatch');
	Template.Abilities.AddItem('PistolOverwatchShot');
	Template.Abilities.AddItem('PistolReturnFire');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');

	Template.SetAnimationNameForAbility('FanFire', 'FF_FireMultiShotConvA');	
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Pistol_CV.WP_Pistol_CV";

	Template.iPhysicsImpulse = 5;
	
	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	Template.bHideClipSizeStat = true;

	return Template;
}

static function X2DataTemplate CreateTemplate_Pistol_Magnetic()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Pistol_MG');
	Template.WeaponPanelImage = "_Pistol";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'pistol';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.MagSecondaryWeapons.MagPistol";
	Template.EquipSound = "Secondary_Weapon_Equip_Magnetic";
	Template.Tier = 2;

	Template.RangeAccuracy = default.SHORT_MAGNETIC_RANGE;
	Template.BaseDamage = default.PISTOL_MAGNETIC_BASEDAMAGE;
	Template.Aim = default.PISTOL_MAGNETIC_AIM;
	Template.CritChance = default.PISTOL_MAGNETIC_CRITCHANCE;
	Template.iClipSize = default.PISTOL_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.PISTOL_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.PISTOL_MAGNETIC_IENVIRONMENTDAMAGE;

	Template.NumUpgradeSlots = 2;

	Template.OverwatchActionPoint = class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint;
	Template.InfiniteAmmo = true;

	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.Abilities.AddItem('PistolOverwatch');
	Template.Abilities.AddItem('PistolOverwatchShot');
	Template.Abilities.AddItem('PistolReturnFire');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');

	Template.SetAnimationNameForAbility('FanFire', 'FF_FireMultiShotMagA');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Pistol_MG.WP_Pistol_MG";

	Template.iPhysicsImpulse = 5;

	Template.CreatorTemplateName = 'Pistol_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Pistol_CV'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_MagXCom';

	Template.bHideClipSizeStat = true;

	return Template;
}

static function X2DataTemplate CreateTemplate_Pistol_Beam()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Pistol_BM');
	Template.WeaponPanelImage = "_Pistol";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'pistol';
	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.BeamSecondaryWeapons.BeamPistol";
	Template.EquipSound = "Secondary_Weapon_Equip_Beam";
	Template.Tier = 4;

	Template.RangeAccuracy = default.SHORT_BEAM_RANGE;
	Template.BaseDamage = default.PISTOL_BEAM_BASEDAMAGE;
	Template.Aim = default.PISTOL_BEAM_AIM;
	Template.CritChance = default.PISTOL_BEAM_CRITCHANCE;
	Template.iClipSize = default.PISTOL_BEAM_ICLIPSIZE;
	Template.iSoundRange = default.PISTOL_BEAM_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.PISTOL_BEAM_IENVIRONMENTDAMAGE;

	Template.NumUpgradeSlots = 2;

	Template.OverwatchActionPoint = class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint;
	Template.InfiniteAmmo = true;
	
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.Abilities.AddItem('PistolOverwatch');
	Template.Abilities.AddItem('PistolOverwatchShot');
	Template.Abilities.AddItem('PistolReturnFire');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');

	Template.SetAnimationNameForAbility('FanFire', 'FF_FireMultiShotBeamA');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Pistol_BM.WP_Pistol_BM";

	Template.iPhysicsImpulse = 5;

	Template.CreatorTemplateName = 'Pistol_BM_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Pistol_MG'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;
	
	Template.DamageTypeTemplateName = 'Projectile_BeamXCom';

	Template.bHideClipSizeStat = true;

	return Template;
}

// **************************************************************************
// ***                       Shotgun                                      ***
// **************************************************************************

static function X2DataTemplate CreateTemplate_Shotgun_Conventional()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Shotgun_CV');
	Template.WeaponPanelImage = "_ConventionalShotgun";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'shotgun';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.ConvShotgun.ConvShotgun_Base";
	Template.EquipSound = "Conventional_Weapon_Equip";
	Template.Tier = 0;

	Template.RangeAccuracy = default.SHORT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.SHOTGUN_CONVENTIONAL_BASEDAMAGE;
	Template.Aim = default.SHOTGUN_CONVENTIONAL_AIM;
	Template.CritChance = default.SHOTGUN_CONVENTIONAL_CRITCHANCE;
	Template.iClipSize = default.SHOTGUN_CONVENTIONAL_ICLIPSIZE;
	Template.iSoundRange = default.SHOTGUN_CONVENTIONAL_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SHOTGUN_CONVENTIONAL_IENVIRONMENTDAMAGE;

	Template.NumUpgradeSlots = 1;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Shotgun_CV.WP_Shotgun_CV";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Shotgun';
	Template.AddDefaultAttachment('Foregrip', "ConvShotgun.Meshes.SM_ConvShotgun_ForegripA" /*FORGRIP INCLUDED IN MAG IMAGE*/);
	Template.AddDefaultAttachment('Mag', "ConvShotgun.Meshes.SM_ConvShotgun_MagA", , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_MagA");
	Template.AddDefaultAttachment('Reargrip', "ConvShotgun.Meshes.SM_ConvShotgun_ReargripA" /*REARGRIP IS INCLUDED IN THE TRIGGER IMAGE*/);
	Template.AddDefaultAttachment('Stock', "ConvShotgun.Meshes.SM_ConvShotgun_StockA", , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_StockA");
	Template.AddDefaultAttachment('Trigger', "ConvShotgun.Meshes.SM_ConvShotgun_TriggerA", , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_TriggerA");
	Template.AddDefaultAttachment('Light', "ConvAttachments.Meshes.SM_ConvFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.fKnockbackDamageAmount = 10.0f;
	Template.fKnockbackDamageRadius = 16.0f;

	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_Shotgun_Magnetic()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Shotgun_MG');
	Template.WeaponPanelImage = "_MagneticShotgun";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'shotgun';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_Base";
	Template.EquipSound = "Magnetic_Weapon_Equip";
	Template.Tier = 3;

	Template.RangeAccuracy = default.SHORT_MAGNETIC_RANGE;
	Template.BaseDamage = default.SHOTGUN_MAGNETIC_BASEDAMAGE;
	Template.Aim = default.SHOTGUN_MAGNETIC_AIM;
	Template.CritChance = default.SHOTGUN_MAGNETIC_CRITCHANCE;
	Template.iClipSize = default.SHOTGUN_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.SHOTGUN_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SHOTGUN_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.NumUpgradeSlots = 2;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Shotgun_MG.WP_Shotgun_MG";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Shotgun';
	Template.AddDefaultAttachment('Foregrip', "MagShotgun.Meshes.SM_MagShotgun_ForegripA", , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_ForegripA");
	Template.AddDefaultAttachment('Mag', "MagShotgun.Meshes.SM_MagShotgun_MagA", , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_MagA");
	Template.AddDefaultAttachment('Reargrip', "MagShotgun.Meshes.SM_MagShotgun_ReargripA" /* included in trigger image */);
	Template.AddDefaultAttachment('Stock', "MagShotgun.Meshes.SM_MagShotgun_StockA", , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_StockA");
	Template.AddDefaultAttachment('Trigger', "MagShotgun.Meshes.SM_MagShotgun_TriggerA", , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_TriggerA");
	Template.AddDefaultAttachment('Light', "ConvAttachments.Meshes.SM_ConvFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.fKnockbackDamageAmount = 10.0f;
	Template.fKnockbackDamageRadius = 16.0f;

	Template.CreatorTemplateName = 'Shotgun_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Shotgun_CV'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_MagXCom';

	return Template;
}

static function X2DataTemplate CreateTemplate_Shotgun_Beam()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Shotgun_BM');
	Template.WeaponPanelImage = "_BeamShotgun";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'shotgun';
	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_Base";
	Template.EquipSound = "Beam_Weapon_Equip";
	Template.Tier = 5;

	Template.RangeAccuracy = default.SHORT_BEAM_RANGE;
	Template.BaseDamage = default.SHOTGUN_BEAM_BASEDAMAGE;
	Template.Aim = default.SHOTGUN_BEAM_AIM;
	Template.CritChance = default.SHOTGUN_BEAM_CRITCHANCE;
	Template.iClipSize = default.SHOTGUN_BEAM_ICLIPSIZE;
	Template.iSoundRange = default.SHOTGUN_BEAM_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SHOTGUN_BEAM_IENVIRONMENTDAMAGE;
	Template.NumUpgradeSlots = 2;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Shotgun_BM.WP_Shotgun_BM";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Shotgun';
	Template.AddDefaultAttachment('Mag', "BeamShotgun.Meshes.SM_BeamShotgun_MagA", , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_MagA");
	Template.AddDefaultAttachment('Suppressor', "BeamShotgun.Meshes.SM_BeamShotgun_SuppressorA", , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_SupressorA");
	Template.AddDefaultAttachment('Core_Left', "BeamShotgun.Meshes.SM_BeamShotgun_CoreA", , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_CoreA");
	Template.AddDefaultAttachment('Core_Right', "BeamShotgun.Meshes.SM_BeamShotgun_CoreA");
	Template.AddDefaultAttachment('HeatSink', "BeamShotgun.Meshes.SM_BeamShotgun_HeatSinkA", , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_HeatsinkA");
	Template.AddDefaultAttachment('Foregrip', "BeamShotgun.Meshes.SM_BeamShotgun_ForegripA", , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_Foregrip");
	Template.AddDefaultAttachment('Light', "BeamAttachments.Meshes.BeamFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.fKnockbackDamageAmount = 10.0f;
	Template.fKnockbackDamageRadius = 16.0f;

	Template.CreatorTemplateName = 'Shotgun_BM_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Shotgun_MG'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_BeamXCom';

	return Template;
}

// **************************************************************************
// ***                       Cannon                                       ***
// **************************************************************************

static function X2DataTemplate CreateTemplate_Cannon_Conventional()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Cannon_CV');
	Template.WeaponPanelImage = "_ConventionalCannon";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'cannon';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.ConvCannon.ConvCannon_Base";
	Template.EquipSound = "Conventional_Weapon_Equip";
	Template.Tier = 0;

	Template.RangeAccuracy = default.MEDIUM_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.LMG_CONVENTIONAL_BASEDAMAGE;
	Template.Aim = default.LMG_CONVENTIONAL_AIM;
	Template.CritChance = default.LMG_CONVENTIONAL_CRITCHANCE;
	Template.iClipSize = default.LMG_CONVENTIONAL_ICLIPSIZE;
	Template.iSoundRange = default.LMG_CONVENTIONAL_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.LMG_CONVENTIONAL_IENVIRONMENTDAMAGE;
	Template.NumUpgradeSlots = 1;
	Template.bIsLargeWeapon = true;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Cannon_CV.WP_Cannon_CV";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Cannon';
	Template.AddDefaultAttachment('Mag', 		"ConvCannon.Meshes.SM_ConvCannon_MagA", , "img:///UILibrary_Common.ConvCannon.ConvCannon_MagA");
	Template.AddDefaultAttachment('Reargrip',   "ConvCannon.Meshes.SM_ConvCannon_ReargripA"/*REARGRIP INCLUDED IN TRIGGER IMAGE*/);
	Template.AddDefaultAttachment('Stock', 		"ConvCannon.Meshes.SM_ConvCannon_StockA", , "img:///UILibrary_Common.ConvCannon.ConvCannon_StockA");
	Template.AddDefaultAttachment('StockSupport', "ConvCannon.Meshes.SM_ConvCannon_StockA_Support");
	Template.AddDefaultAttachment('Suppressor', "ConvCannon.Meshes.SM_ConvCannon_SuppressorA");
	Template.AddDefaultAttachment('Trigger', "ConvCannon.Meshes.SM_ConvCannon_TriggerA", , "img:///UILibrary_Common.ConvCannon.ConvCannon_TriggerA");
	Template.AddDefaultAttachment('Light', "ConvAttachments.Meshes.SM_ConvFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_Cannon_Magnetic()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Cannon_MG');
	Template.WeaponPanelImage = "_MagneticCannon";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'cannon';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.UI_MagCannon.MagCannon_Base";
	Template.EquipSound = "Magnetic_Weapon_Equip";
	Template.Tier = 3;

	Template.RangeAccuracy = default.MEDIUM_MAGNETIC_RANGE;
	Template.BaseDamage = default.LMG_MAGNETIC_BASEDAMAGE;
	Template.Aim = default.LMG_MAGNETIC_AIM;
	Template.CritChance = default.LMG_MAGNETIC_CRITCHANCE;
	Template.iClipSize = default.LMG_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.LMG_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.LMG_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.NumUpgradeSlots = 2;
	Template.bIsLargeWeapon = true;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Cannon_MG.WP_Cannon_MG";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Cannon';
	Template.AddDefaultAttachment('Mag', "MagCannon.Meshes.SM_MagCannon_MagA", , "img:///UILibrary_Common.UI_MagCannon.MagCannon_MagA");
	Template.AddDefaultAttachment('Reargrip',   "MagCannon.Meshes.SM_MagCannon_ReargripA");
	Template.AddDefaultAttachment('Foregrip', "MagCannon.Meshes.SM_MagCannon_StockA", , "img:///UILibrary_Common.UI_MagCannon.MagCannon_StockA");
	Template.AddDefaultAttachment('Trigger', "MagCannon.Meshes.SM_MagCannon_TriggerA", , "img:///UILibrary_Common.UI_MagCannon.MagCannon_TriggerA");
	Template.AddDefaultAttachment('Light', "ConvAttachments.Meshes.SM_ConvFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.CreatorTemplateName = 'Cannon_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Cannon_CV'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_MagXCom';

	return Template;
}

static function X2DataTemplate CreateTemplate_Cannon_Beam()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Cannon_BM');
	Template.WeaponPanelImage = "_BeamCannon";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'cannon';
	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_Base";
	Template.EquipSound = "Beam_Weapon_Equip";
	Template.Tier = 5;

	Template.RangeAccuracy = default.MEDIUM_BEAM_RANGE;
	Template.BaseDamage = default.LMG_BEAM_BASEDAMAGE;
	Template.Aim = default.LMG_BEAM_AIM;
	Template.CritChance = default.LMG_BEAM_CRITCHANCE;
	Template.iClipSize = default.LMG_BEAM_ICLIPSIZE;
	Template.iSoundRange = default.LMG_BEAM_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.LMG_BEAM_IENVIRONMENTDAMAGE;
	Template.NumUpgradeSlots = 2;
	Template.bIsLargeWeapon = true;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Cannon_BM.WP_Cannon_BM";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Cannon';
	Template.AddDefaultAttachment('Mag', "BeamCannon.Meshes.SM_BeamCannon_MagA", , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_MagA");
	Template.AddDefaultAttachment('Core', "BeamCannon.Meshes.SM_BeamCannon_CoreA", , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_CoreA");
	Template.AddDefaultAttachment('Core_Center',"BeamCannon.Meshes.SM_BeamCannon_CoreA_Center");
	Template.AddDefaultAttachment('HeatSink', "BeamCannon.Meshes.SM_BeamCannon_HeatSinkA", , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_HeatsinkA");
	Template.AddDefaultAttachment('Suppressor', "BeamCannon.Meshes.SM_BeamCannon_SuppressorA", , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_SupressorA");
	Template.AddDefaultAttachment('Light', "BeamAttachments.Meshes.BeamFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.CreatorTemplateName = 'Cannon_BM_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Cannon_MG'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_BeamXCom';

	return Template;
}

// **************************************************************************
// ***                       Sniper Rifle                                 ***
// **************************************************************************

static function X2DataTemplate CreateTemplate_SniperRifle_Conventional()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'SniperRifle_CV');
	Template.WeaponPanelImage = "_ConventionalSniperRifle";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'sniper_rifle';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.ConvSniper.ConvSniper_Base";
	Template.EquipSound = "Conventional_Weapon_Equip";
	Template.Tier = 0;

	Template.RangeAccuracy = default.LONG_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.SNIPERRIFLE_CONVENTIONAL_BASEDAMAGE;
	Template.Aim = default.SNIPERRIFLE_CONVENTIONAL_AIM;
	Template.CritChance = default.SNIPERRIFLE_CONVENTIONAL_CRITCHANCE;
	Template.iClipSize = default.SNIPERRIFLE_CONVENTIONAL_ICLIPSIZE;
	Template.iSoundRange = default.SNIPERRIFLE_CONVENTIONAL_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SNIPERRIFLE_CONVENTIONAL_IENVIRONMENTDAMAGE;
	Template.NumUpgradeSlots = 1;
	Template.iTypicalActionCost = 2;

	Template.bIsLargeWeapon = true;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('SniperStandardFire');
	Template.Abilities.AddItem('SniperRifleOverwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_SniperRifle_CV.WP_SniperRifle_CV";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Sniper';
	Template.AddDefaultAttachment('Mag', "ConvSniper.Meshes.SM_ConvSniper_MagA", , "img:///UILibrary_Common.ConvSniper.ConvSniper_MagA");
	Template.AddDefaultAttachment('Optic', "ConvSniper.Meshes.SM_ConvSniper_OpticA", , "img:///UILibrary_Common.ConvSniper.ConvSniper_OpticA");
	Template.AddDefaultAttachment('Reargrip', "ConvSniper.Meshes.SM_ConvSniper_ReargripA" /*REARGRIP INCLUDED IN TRIGGER IMAGE*/);
	Template.AddDefaultAttachment('Stock', "ConvSniper.Meshes.SM_ConvSniper_StockA", , "img:///UILibrary_Common.ConvSniper.ConvSniper_StockA");
	Template.AddDefaultAttachment('Suppressor', "ConvSniper.Meshes.SM_ConvSniper_SuppressorA", , "img:///UILibrary_Common.ConvSniper.ConvSniper_SuppressorA");
	Template.AddDefaultAttachment('Trigger', "ConvSniper.Meshes.SM_ConvSniper_TriggerA", , "img:///UILibrary_Common.ConvSniper.ConvSniper_TriggerA");
	Template.AddDefaultAttachment('Light', "ConvAttachments.Meshes.SM_ConvFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_SniperRifle_Magnetic()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'SniperRifle_MG');
	Template.WeaponPanelImage = "_MagneticSniperRifle";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'sniper_rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.UI_MagSniper.MagSniper_Base";
	Template.EquipSound = "Magnetic_Weapon_Equip";
	Template.Tier = 3;

	Template.RangeAccuracy = default.LONG_MAGNETIC_RANGE;
	Template.BaseDamage = default.SNIPERRIFLE_MAGNETIC_BASEDAMAGE;
	Template.Aim = default.SNIPERRIFLE_MAGNETIC_AIM;
	Template.CritChance = default.SNIPERRIFLE_MAGNETIC_CRITCHANCE;
	Template.iClipSize = default.SNIPERRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.SNIPERRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SNIPERRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.NumUpgradeSlots = 2;
	Template.iTypicalActionCost = 2;

	Template.bIsLargeWeapon = true;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('SniperStandardFire');
	Template.Abilities.AddItem('SniperRifleOverwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_SniperRifle_MG.WP_SniperRifle_MG";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Sniper';
	Template.AddDefaultAttachment('Mag', "MagSniper.Meshes.SM_MagSniper_MagA", , "img:///UILibrary_Common.UI_MagSniper.MagSniper_MagA");
	Template.AddDefaultAttachment('Optic', "MagSniper.Meshes.SM_MagSniper_OpticA", , "img:///UILibrary_Common.UI_MagSniper.MagSniper_OpticA");
	Template.AddDefaultAttachment('Reargrip',   "MagSniper.Meshes.SM_MagSniper_ReargripA" /* image included in TriggerA */);
	Template.AddDefaultAttachment('Stock', "MagSniper.Meshes.SM_MagSniper_StockA", , "img:///UILibrary_Common.UI_MagSniper.MagSniper_StockA");
	Template.AddDefaultAttachment('Suppressor', "MagSniper.Meshes.SM_MagSniper_SuppressorA", , "img:///UILibrary_Common.UI_MagSniper.MagSniper_SuppressorA");
	Template.AddDefaultAttachment('Trigger', "MagSniper.Meshes.SM_MagSniper_TriggerA", , "img:///UILibrary_Common.UI_MagSniper.MagSniper_TriggerA");
	Template.AddDefaultAttachment('Light', "ConvAttachments.Meshes.SM_ConvFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.CreatorTemplateName = 'SniperRifle_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'SniperRifle_CV'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_MagXCom';

	return Template;
}

static function X2DataTemplate CreateTemplate_SniperRifle_Beam()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'SniperRifle_BM');
	Template.WeaponPanelImage = "_BeamSniperRifle";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'sniper_rifle';
	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_Base";
	Template.EquipSound = "Beam_Weapon_Equip";
	Template.Tier = 5;

	Template.RangeAccuracy = default.LONG_BEAM_RANGE;
	Template.BaseDamage = default.SNIPERRIFLE_BEAM_BASEDAMAGE;
	Template.Aim = default.SNIPERRIFLE_BEAM_AIM;
	Template.CritChance = default.SNIPERRIFLE_BEAM_CRITCHANCE;
	Template.iClipSize = default.SNIPERRIFLE_BEAM_ICLIPSIZE;
	Template.iSoundRange = default.SNIPERRIFLE_BEAM_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SNIPERRIFLE_BEAM_IENVIRONMENTDAMAGE;
	Template.NumUpgradeSlots = 2;
	Template.iTypicalActionCost = 2;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('SniperStandardFire');
	Template.Abilities.AddItem('SniperRifleOverwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_SniperRifle_BM.WP_SniperRifle_BM";
	Template.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Sniper';
	Template.AddDefaultAttachment('Optic', "BeamSniper.Meshes.SM_BeamSniper_OpticA", , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_OpticA");
	Template.AddDefaultAttachment('Mag', "BeamSniper.Meshes.SM_BeamSniper_MagA", , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_MagA");
	Template.AddDefaultAttachment('Suppressor', "BeamSniper.Meshes.SM_BeamSniper_SuppressorA", , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_SupressorA");
	Template.AddDefaultAttachment('Core', "BeamSniper.Meshes.SM_BeamSniper_CoreA", , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_CoreA");
	Template.AddDefaultAttachment('HeatSink', "BeamSniper.Meshes.SM_BeamSniper_HeatSinkA", , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_HeatsinkA");
	Template.AddDefaultAttachment('Light', "BeamAttachments.Meshes.BeamFlashLight");

	Template.iPhysicsImpulse = 5;

	Template.CreatorTemplateName = 'SniperRifle_BM_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'SniperRifle_MG'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Projectile_BeamXCom';

	return Template;
}

// **************************************************************************
// ***                       Melee Weapons                                ***
// **************************************************************************

static function X2DataTemplate CreateTemplate_Sword_Conventional()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Sword_CV');
	Template.WeaponPanelImage = "_Sword";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'sword';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.ConvSecondaryWeapons.Sword";
	Template.EquipSound = "Sword_Equip_Conventional";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sword_CV.WP_Sword_CV";
	Template.AddDefaultAttachment('Sheath', "ConvSword.Meshes.SM_ConvSword_Sheath", true);
	Template.Tier = 0;

	Template.iRadius = 1;
	Template.NumUpgradeSlots = 1;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;

	Template.iRange = 0;
	Template.BaseDamage = default.RANGERSWORD_CONVENTIONAL_BASEDAMAGE;
	Template.Aim = default.RANGERSWORD_CONVENTIONAL_AIM;
	Template.CritChance = default.RANGERSWORD_CONVENTIONAL_CRITCHANCE;
	Template.iSoundRange = default.RANGERSWORD_CONVENTIONAL_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.RANGERSWORD_CONVENTIONAL_IENVIRONMENTDAMAGE;
	Template.BaseDamage.DamageType = 'Melee';
	
	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Melee';

	return Template;
}

static function X2DataTemplate CreateTemplate_Sword_Magnetic()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Sword_MG');
	Template.WeaponPanelImage = "_Pistol";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'sword';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.MagSecondaryWeapons.MagSword";
	Template.EquipSound = "Sword_Equip_Magnetic";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sword_MG.WP_Sword_MG";
	Template.AddDefaultAttachment('R_Back', "MagSword.Meshes.SM_MagSword_Sheath", false);
	Template.Tier = 2;

	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;

	Template.iRange = 0;
	Template.BaseDamage = default.RANGERSWORD_MAGNETIC_BASEDAMAGE;
	Template.Aim = default.RANGERSWORD_MAGNETIC_AIM;
	Template.CritChance = default.RANGERSWORD_MAGNETIC_CRITCHANCE;
	Template.iSoundRange = default.RANGERSWORD_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.RANGERSWORD_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.BaseDamage.DamageType='Melee';

	Template.BonusWeaponEffects.AddItem(class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, default.RANGERSWORD_MAGNETIC_STUNCHANCE, false));

	Template.CreatorTemplateName = 'Sword_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Sword_CV'; // Which item this will be upgraded from
	
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Melee';
	
	Template.SetUIStatMarkup(class'XLocalizedData'.default.StunChanceLabel, , default.RANGERSWORD_MAGNETIC_STUNCHANCE, , , "%");

	return Template;
}

static function X2DataTemplate CreateTemplate_Sword_Beam()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Sword_BM');
	Template.WeaponPanelImage = "_Pistol";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'sword';
	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.BeamSecondaryWeapons.BeamSword";
	Template.EquipSound = "Sword_Equip_Beam";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sword_BM.WP_Sword_BM";
	Template.AddDefaultAttachment('R_Back', "BeamSword.Meshes.SM_BeamSword_Sheath", false);
	Template.Tier = 4;

	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;

	Template.iRange = 0;
	Template.BaseDamage = default.RANGERSWORD_BEAM_BASEDAMAGE;
	Template.Aim = default.RANGERSWORD_BEAM_AIM;
	Template.CritChance = default.RANGERSWORD_BEAM_CRITCHANCE;
	Template.iSoundRange = default.RANGERSWORD_BEAM_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.RANGERSWORD_BEAM_IENVIRONMENTDAMAGE;
	Template.BaseDamage.DamageType='Melee';

	Template.BonusWeaponEffects.AddItem(class'X2StatusEffects'.static.CreateBurningStatusEffect(2, 0));
	
	Template.CreatorTemplateName = 'Sword_BM_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Sword_MG'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Melee';
	
	return Template;
}

// **************************************************************************
// ***                       Gremlin Weapons                              ***
// **************************************************************************

static function X2DataTemplate CreateTemplate_GremlinDrone_Conventional()
{
	local X2GremlinTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GremlinTemplate', Template, 'Gremlin_CV');
	Template.WeaponPanelImage = "_Gremlin";                       // used by the UI. Probably determines iconview of the weapon.
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Gremlin_Drone";
	Template.EquipSound = "Gremlin_Equip";

	Template.CosmeticUnitTemplate = "GremlinMk1";
	Template.Tier = 0;

	Template.ExtraDamage = default.GREMLINMK1_ABILITYDAMAGE;
	Template.HackingAttemptBonus = default.GREMLIN_HACKBONUS;
	Template.AidProtocolBonus = 0;
	Template.HealingBonus = 0;
	Template.BaseDamage.Damage = 2;     //  combat protocol
	Template.BaseDamage.Pierce = 1000;  //  ignore armor

	Template.iRange = 2;
	Template.iRadius = 40;              //  only for scanning protocol
	Template.NumUpgradeSlots = 1;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;

	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Electrical';

	Template.bHideDamageStat = true;
	Template.SetUIStatMarkup(class'XLocalizedData'.default.TechBonusLabel, eStat_Hacking, default.GREMLIN_HACKBONUS, true);

	return Template;
}

static function X2DataTemplate CreateTemplate_GremlinDrone_Magnetic()
{
	local X2GremlinTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GremlinTemplate', Template, 'Gremlin_MG');
	Template.WeaponPanelImage = "_Gremlin";                       // used by the UI. Probably determines iconview of the weapon.

	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.MagSecondaryWeapons.MagGremlin";
	Template.EquipSound = "Gremlin_Equip";

	Template.CosmeticUnitTemplate = "GremlinMk2";
	Template.Tier = 2;

	Template.ExtraDamage = default.GREMLINMK2_ABILITYDAMAGE;
	Template.HackingAttemptBonus = default.GREMLINMK2_HACKBONUS;
	Template.AidProtocolBonus = 10;
	Template.HealingBonus = 1;
	Template.BaseDamage.Damage = 4;     //  combat protocol
	Template.BaseDamage.Pierce = 1000;  //  ignore armor

	Template.iRange = 2;
	Template.iRadius = 40;              //  only for scanning protocol
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;

	Template.CreatorTemplateName = 'Gremlin_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Gremlin_CV'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Electrical';

	Template.bHideDamageStat = true;
	Template.SetUIStatMarkup(class'XLocalizedData'.default.TechBonusLabel, eStat_Hacking, default.GREMLINMK2_HACKBONUS);

	return Template;
}

static function X2DataTemplate CreateTemplate_GremlinDrone_Beam()
{
	local X2GremlinTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GremlinTemplate', Template, 'Gremlin_BM');
	Template.WeaponPanelImage = "_Gremlin";                       // used by the UI. Probably determines iconview of the weapon.

	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.BeamSecondaryWeapons.BeamGremlin";
	Template.EquipSound = "Gremlin_Equip";

	Template.CosmeticUnitTemplate = "GremlinMk3";
	Template.Tier = 4;

	Template.ExtraDamage = default.GREMLINMK3_ABILITYDAMAGE;
	Template.HackingAttemptBonus = default.GREMLINMK3_HACKBONUS;
	Template.AidProtocolBonus = 20;
	Template.HealingBonus = 2;
	Template.RevivalChargesBonus = 1;
	Template.ScanningChargesBonus = 1;
	Template.BaseDamage.Damage = 6;     //  combat protocol
	Template.BaseDamage.Pierce = 1000;  //  ignore armor

	Template.iRange = 2;
	Template.iRadius = 40;              //  only for scanning protocol
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;

	Template.CreatorTemplateName = 'Gremlin_BM_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'Gremlin_MG'; // Which item this will be upgraded from
	
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Electrical';
	
	Template.bHideDamageStat = true;
	Template.SetUIStatMarkup(class'XLocalizedData'.default.TechBonusLabel, eStat_Hacking, default.GREMLINMK3_HACKBONUS);

	return Template;
}

static function X2DataTemplate CreateTemplate_GremlinDrone_MP()
{
	local X2GremlinTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GremlinTemplate', Template, 'Gremlin_MP');
	Template.WeaponPanelImage = "_Gremlin";                       // used by the UI. Probably determines iconview of the weapon.

	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.BeamSecondaryWeapons.BeamGremlin";
	Template.EquipSound = "Gremlin_Equip";

	Template.CosmeticUnitTemplate = "GremlinMk3";
	Template.Tier = 4;

	Template.ExtraDamage = default.GREMLINMK2_ABILITYDAMAGE;
	Template.HackingAttemptBonus = default.GREMLINMK3_HACKBONUS;
	Template.AidProtocolBonus = 0;
	Template.HealingBonus = 2;
	Template.RevivalChargesBonus = 1;
	Template.ScanningChargesBonus = 1;
	Template.BaseDamage.Damage = 4;     //  combat protocol
	Template.BaseDamage.Pierce = 1000;  //  ignore armor

	Template.iRange = 2;
	Template.iRadius = 40;              //  only for scanning protocol
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = false;

	Template.DamageTypeTemplateName = 'Electrical';

	Template.bHideDamageStat = true;
	Template.SetUIStatMarkup(class'XLocalizedData'.default.TechBonusLabel, eStat_Hacking, default.GREMLINMK3_HACKBONUS);

	return Template;
}

// **************************************************************************
// ***                       Psi Amps                                     ***
// **************************************************************************

static function X2DataTemplate CreateTemplate_PsiAmp_Conventional()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'PsiAmp_CV');
	Template.WeaponPanelImage = "_PsiAmp";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.DamageTypeTemplateName = 'Psi';
	Template.WeaponCat = 'psiamp';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.ConvSecondaryWeapons.PsiAmp";
	Template.EquipSound = "Psi_Amp_Equip";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	Template.Tier = 0;
	// This all the resources; sounds, animations, models, physics, the works.
	
	Template.GameArchetype = "WP_PsiAmp_CV.WP_PsiAmp_CV";

	Template.Abilities.AddItem('PsiAmpCV_BonusStats');
	
	Template.ExtraDamage = default.PSIAMPT1_ABILITYDAMAGE;

	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	// Show In Armory Requirements
	Template.ArmoryDisplayRequirements.RequiredTechs.AddItem('Psionics');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.PsiOffenseBonusLabel, eStat_PsiOffense, class'X2Ability_ItemGrantedAbilitySet'.default.PSIAMP_CV_STATBONUS, true);

	return Template;
}

static function X2DataTemplate CreateTemplate_PsiAmp_Magnetic()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'PsiAmp_MG');
	Template.WeaponPanelImage = "_PsiAmp";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'psiamp';
	Template.DamageTypeTemplateName = 'Psi';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.MagSecondaryWeapons.MagPsiAmp";
	Template.EquipSound = "Psi_Amp_Equip";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	Template.Tier = 2;
	// This all the resources; sounds, animations, models, physics, the works.
	
	Template.GameArchetype = "WP_PsiAmp_MG.WP_PsiAmp_MG";

	Template.Abilities.AddItem('PsiAmpMG_BonusStats');

	Template.ExtraDamage = default.PSIAMPT2_ABILITYDAMAGE;

	Template.CreatorTemplateName = 'PsiAmp_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'PsiAmp_CV'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;
	
	Template.SetUIStatMarkup(class'XLocalizedData'.default.PsiOffenseBonusLabel, eStat_PsiOffense, class'X2Ability_ItemGrantedAbilitySet'.default.PSIAMP_MG_STATBONUS);

	return Template;
}

static function X2DataTemplate CreateTemplate_PsiAmp_Beam()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'PsiAmp_BM');
	Template.WeaponPanelImage = "_PsiAmp";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'psiamp';
	Template.DamageTypeTemplateName = 'Psi';
	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.BeamSecondaryWeapons.BeamPsiAmp";
	Template.EquipSound = "Psi_Amp_Equip";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	Template.Tier = 4;
	// This all the resources; sounds, animations, models, physics, the works.
	
	Template.GameArchetype = "WP_PsiAmp_BM.WP_PsiAmp_BM";

	Template.Abilities.AddItem('PsiAmpBM_BonusStats');

	Template.ExtraDamage = default.PSIAMPT3_ABILITYDAMAGE;

	Template.CreatorTemplateName = 'PsiAmp_BM_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'PsiAmp_MG'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.SetUIStatMarkup(class'XLocalizedData'.default.PsiOffenseBonusLabel, eStat_PsiOffense, class'X2Ability_ItemGrantedAbilitySet'.default.PSIAMP_BM_STATBONUS);

	return Template;
}

// **********************************************************************************************************
// // ***                              XCom Avenger Defense Turret                                        ***
// **********************************************************************************************************

static function X2DataTemplate CreateTemplate_XComTurretM1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'XComTurretM1_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventTurret";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.XCOMTURRETM1_WPN_BASEDAMAGE;
	Template.iClipSize = 1;
	Template.InfiniteAmmo = true;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot_NoEnd');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Turret_MG.WP_Turret_MG";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_MagAdvent';

	return Template;
}

static function X2DataTemplate CreateTemplate_XComTurretM2_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'XComTurretM2_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventTurret";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.XCOMTURRETM2_WPN_BASEDAMAGE;
	Template.iClipSize = 1;
	Template.InfiniteAmmo = true;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot_NoEnd');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Turret_MG.WP_Turret_MG";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_BeamAlien';

	return Template;
}

// **********************************************************************************************************
// // ***                              XCom Central's Assault Rifle                                       ***
// **********************************************************************************************************

static function X2DataTemplate CreateTemplate_AssaultRifle_Central()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AssaultRifle_Central');
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.EquipSound = "Conventional_Weapon_Equip";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.CentralAR";
	Template.Tier = 5;

	Template.RangeAccuracy = default.MEDIUM_MAGNETIC_RANGE;
	Template.BaseDamage = default.ASSAULTRIFLE_CENTRAL_BASEDAMAGE;
	Template.Aim = default.ASSAULTRIFLE_MAGNETIC_AIM;
	Template.CritChance = default.ASSAULTRIFLE_MAGNETIC_CRITCHANCE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;

	Template.NumUpgradeSlots = 0;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_CentralAR.WP_CentralAR";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;

	Template.fKnockbackDamageAmount = 5.0f;
	Template.fKnockbackDamageRadius = 0.0f;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

// **********************************************************************************************************
// // ***                                         Enemy Weapons                                           ***
// **********************************************************************************************************

// NOTE: 'BASIC WEAPONS' ARE AUTO GENERATED DEFAULT WEAPONS, NOT SPECIAL WEAPONS. That means, basically, "rifles".
// Melee attacks and attacks that use custom abilities other than "standard shot" should be additional, different entries.

// **************************************************************************
// ***                 Advent Troops - BASIC WEAPONS                      ***
// **************************************************************************

static function X2DataTemplate CreateAssaultRifleMagneticAdventTemplate()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AssaultRifle_MG_Advent');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.

	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.ItemCat = 'weapon';
	Template.strImage = "img:///UILibrary_StrategyImages.InventoryIcons.Inv_AssaultRifleModern";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_MAGNETIC_RANGE;
	Template.Aim = default.ASSAULTRIFLE_MAGNETIC_AIM;
	Template.BaseDamage.Damage = 2;
	Template.BaseDamage.PlusOne = 66;
	Template.BaseDamage.Crit = 2;
	//Template.ExtraDamage = default.ASSAULTRIFLE_MAGNETIC_EXTRADAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.NumUpgradeSlots = 2;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_MagAdvent';

	return Template;
}

// *********************************

static function X2DataTemplate CreateTemplate_AdvCaptainM1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvCaptainM1_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVCAPTAINM1_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVCAPTAINM1_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvCaptainM2_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvCaptainM2_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVCAPTAINM2_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVCAPTAINM2_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_MagAdvent';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvCaptainM3_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvCaptainM3_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVCAPTAINM3_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVCAPTAINM3_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_BeamAlien';

	return Template;
}

// *********************************

static function X2DataTemplate CreateTemplate_AdvMEC_M2_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvMEC_M2_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventMecGun";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVMEC_M2_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVMEC_M2_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Suppression');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AdvMec_Gun.WP_AdvMecGun";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_MagAdvent';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvMEC_M2_Shoulder_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvMEC_M2_Shoulder_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'shoulder_launcher';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventMecGun";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.AdvMEC_M2_MicroMissiles_BaseDamage;
	Template.iClipSize = 2;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVMEC_M2_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.Abilities.AddItem('MicroMissiles');
	Template.Abilities.AddItem('MicroMissileFuse');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AdvMec_Launcher.WP_AdvMecLauncher";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;
	Template.iRange = 20;


	// This controls how much arc this projectile may have and how many times it may bounce
	Template.WeaponPrecomputedPathData.InitialPathTime = 1.5;
	Template.WeaponPrecomputedPathData.MaxPathTime = 2.5;
	Template.WeaponPrecomputedPathData.MaxNumberOfBounces = 0;

	Template.DamageTypeTemplateName = 'Explosion';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvMEC_M1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvMEC_M1_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventMecGun";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVMEC_M1_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVMEC_M1_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Suppression');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AdvMec_Gun.WP_AdvMecGun";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvMEC_M1_Shoulder_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvMEC_M1_Shoulder_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'shoulder_launcher';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventMecGun";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.AdvMEC_M1_MicroMissiles_BaseDamage;
	Template.iClipSize = 1;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVMEC_M2_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.Abilities.AddItem('MicroMissiles');
	Template.Abilities.AddItem('MicroMissileFuse');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AdvMec_Launcher.WP_AdvMecLauncher";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;
	Template.iRange = 20;

	// This controls how much arc this projectile may have and how many times it may bounce
	Template.WeaponPrecomputedPathData.InitialPathTime = 1.5;
	Template.WeaponPrecomputedPathData.MaxPathTime = 2.5;
	Template.WeaponPrecomputedPathData.MaxNumberOfBounces = 0;

	Template.DamageTypeTemplateName = 'Explosion';

	return Template;
}

// *********************************

static function X2DataTemplate CreateTemplate_AdvPsiWitchM2_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvPsiWitchM2_WPN');
	
	Template.WeaponPanelImage = "_BeamRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AvatarRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVPSIWITCHM2_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVPSIWITCHM2_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Avatar_Rifle.WP_AvatarRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_BeamAvatar';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvPsiWitchM2_PsiAmp()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvPsiWitchM2_PsiAmp');
	Template.WeaponPanelImage = "_PsiAmp";                       // used by the UI. Probably determines iconview of the weapon.
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'psiamp';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Psi_Amp";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	
	Template.GameArchetype = "WP_PsiAmp_MG.WP_PsiAmp_MG_Advent";

	Template.Abilities.AddItem('PsiDimensionalRiftStage1');
	Template.Abilities.AddItem('PsiDimensionalRiftStage2');
	Template.Abilities.AddItem('NullLance');
	Template.Abilities.AddItem('PsiMindControl');
	
	Template.ExtraDamage = default.AVATAR_PLAYER_PSIAMP_ABILITYDAMAGE;

	Template.CanBeBuilt = false;

	Template.DamageTypeTemplateName = 'Psi';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvPsiWitchM3_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvPsiWitchM3_WPN');
	
	Template.WeaponPanelImage = "_BeamRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'beam';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AvatarRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVPSIWITCHM3_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVPSIWITCHM3_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Avatar_Rifle.WP_AvatarRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_BeamAvatar';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvPsiWitchM3_PsiAmp()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvPsiWitchM3_PsiAmp');
	Template.WeaponPanelImage = "_PsiAmp";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'psiamp';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Psi_Amp";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability
	// This all the resources; sounds, animations, models, physics, the works.
	
	Template.GameArchetype = "WP_PsiAmp_MG.WP_PsiAmp_MG_Advent";

	Template.Abilities.AddItem('PsiDimensionalRiftStage1');
	Template.Abilities.AddItem('PsiDimensionalRiftStage2');
	Template.Abilities.AddItem('NullLance');
	Template.Abilities.AddItem('PsiMindControl');

	Template.ExtraDamage = default.AVATAR_AI_PSIAMP_ABILITYDAMAGE;

	Template.CanBeBuilt = false;

	Template.DamageTypeTemplateName = 'Psi';

	return Template;
}
// *********************************

static function X2DataTemplate CreateTemplate_AdvShieldBearerM2_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvShieldBearerM2_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVSHIELDBEARERM2_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVSHIELDBEARERM2_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_MagAdvent';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvShieldBearerM3_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvShieldBearerM3_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVSHIELDBEARERM3_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVSHIELDBEARERM3_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_BeamAlien';

	return Template;
}

// *********************************

static function X2DataTemplate CreateTemplate_AdvStunLancerM1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvStunLancerM1_WPN');
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVSTUNLANCERM1_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVSTUNLANCERM1_IDEALRANGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvStunLancerM2_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvStunLancerM2_WPN');
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVSTUNLANCERM2_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVSTUNLANCERM2_IDEALRANGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_MagAdvent';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvStunLancerM3_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvStunLancerM3_WPN');
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVSTUNLANCERM3_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVSTUNLANCERM3_IDEALRANGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_BeamAlien';

	return Template;
}

// *********************************

static function X2DataTemplate CreateTemplate_AdvTrooperM1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvTrooperM1_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVTROOPERM1_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVTROOPERM1_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvTrooperM2_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvTrooperM2_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVTROOPERM2_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVTROOPERM2_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_MagAdvent';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvTrooperM3_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvTrooperM3_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVTROOPERM3_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVTROOPERM3_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_BeamAlien';

	return Template;
}

// *********************************

static function X2DataTemplate CreateTemplate_AdvTurretM1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvTurretM1_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventTurret";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVTURRETM1_WPN_BASEDAMAGE;
	Template.iClipSize = 1;
	Template.InfiniteAmmo = true;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVTURRETM1_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot_NoEnd'); // UPDATE - All turrets can TakeTwo shots (was- deliberately different from the mk2 and mk3).
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Turret_MG.WP_Turret_MG";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvShortTurretM1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvShortTurretM1_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventTurret";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVTURRETM1_WPN_BASEDAMAGE;
	Template.iClipSize = 1;
	Template.InfiniteAmmo = true;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVTURRETM1_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot_NoEnd'); // UPDATE - All turrets can TakeTwo shots (was- deliberately different from the mk2 and mk3).
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Turret_MG.WP_Turret_MG";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvTurretM2_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvTurretM2_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventTurret";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVTURRETM2_WPN_BASEDAMAGE;
	Template.iClipSize = 1;
	Template.InfiniteAmmo = true;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVTURRETM2_IDEALRANGE;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot_NoEnd');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Turret_MG.WP_Turret_MG";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_MagAdvent';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvTurretM3_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvTurretM3_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventTurret";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ADVTURRETM3_WPN_BASEDAMAGE;
	Template.iClipSize = 1;
	Template.InfiniteAmmo = true;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVTURRETM3_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot_NoEnd');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Turret_MG.WP_Turret_MG";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_BeamAlien';

	return Template;
}

// **************************************************************************
// ***                Alien Troops - BASIC WEAPONS                        ***
// **************************************************************************

static function X2DataTemplate CreateTemplate_Andromedon_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Andromedon_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AndromedonRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ANDROMEDON_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ANDROMEDON_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Andromedon_Cannon.WP_AndromedonCannon";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_AndromedonRobot_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AndromedonRobot_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AndromedonRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.iClipSize = 0;
	Template.iSoundRange = 0;
	Template.iEnvironmentDamage = 0;
	Template.iIdealRange = 0;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Andromedon_Cannon.WP_AndromedonCannon_Smashed";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.bDisplayWeaponAndAmmo = false;

	return Template;
}

static function X2DataTemplate CreateTemplate_Archon_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Archon_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ArchonStaff";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ARCHON_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ARCHON_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Archon_Rifle.WP_ArchonRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_Archon_Blazing_Pinions_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Archon_Blazing_Pinions_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ArchonStaff";

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.ARCHON_BLAZINGPINIONS_BASEDAMAGE;
	Template.iClipSize = 0;
	Template.iSoundRange = 0;
	Template.iEnvironmentDamage = default.ARCHON_BLAZINGPINIONS_ENVDAMAGE;
	Template.iIdealRange = 0;
	Template.iPhysicsImpulse = 5;
	Template.DamageTypeTemplateName = 'BlazingPinions';

	Template.InventorySlot = eInvSlot_Utility;
	Template.Abilities.AddItem('BlazingPinionsStage2');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Archon_Blazing_Pinions.WP_Blazing_Pinions_CV";

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 0;

	return Template;
}

static function X2DataTemplate CreateTemplate_Cyberus_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Cyberus_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ViperRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.CYBERUS_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.CYBERUS_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';
	
	Template.InfiniteAmmo = true;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Cyberus_Gun.WP_CyberusRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_Gatekeeper_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Gatekeeper_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.GatekeeperEyeball";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.BaseDamage = default.GATEKEEPER_WPN_BASEDAMAGE;
	Template.iClipSize = 1;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Gatekeeper_Anima_Gate.WP_Gatekeeper_Anima_Gate";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_Muton_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Muton_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.MutonRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.MUTON_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.MUTON_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('Suppression');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Execute');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Muton_Rifle.WP_MutonRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_Sectoid_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Sectoid_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.SectoidPistol";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.SECTOID_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.SECTOID_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sectoid_ArmPistol.WP_SectoidPistol";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_Sectopod_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Sectopod_WPN');
	
	Template.WeaponPanelImage = "_BeamSniperRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventTurret";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_BEAM_RANGE;
	Template.BaseDamage = default.SECTOPOD_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.SECTOPOD_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('Blaster');
	Template.Abilities.AddItem('BlasterDuringCannon');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sectopod_Turret.WP_Sectopod_Turret";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_Sectopod_WrathCannon_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Sectopod_Wrathcannon_WPN');

	Template.WeaponPanelImage = "_BeamCannon";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_BEAM_RANGE;
	Template.BaseDamage = default.SECTOPOD_WRATHCANNON_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.SECTOPOD_IDEALRANGE;
	Template.iRange = 25;
	Template.iRadius = 12;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.Abilities.AddItem('WrathCannonStage1');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sectopod_Turret.WP_Sectopod_WrathCannon";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_PrototypeSectopod_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'PrototypeSectopod_WPN');
	
	Template.WeaponPanelImage = "_BeamSniperRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventTurret";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_BEAM_RANGE;
	Template.BaseDamage = default.PROTOTYPESECTOPOD_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.PROTOTYPESECTOPOD_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('Blaster');
	Template.Abilities.AddItem('BlasterDuringCannon');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sectopod_Turret.WP_Sectopod_Turret";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_PrototypeSectopod_WrathCannon_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'PrototypeSectopod_Wrathcannon_WPN');

	Template.WeaponPanelImage = "_BeamCannon";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_BEAM_RANGE;
	Template.BaseDamage = default.PROTOTYPESECTOPOD_WRATHCANNON_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.PROTOTYPESECTOPOD_IDEALRANGE;
	Template.iRange = 25;
	Template.iRadius = 12;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InventorySlot = eInvSlot_SecondaryWeapon;
//	Template.Abilities.AddItem('WrathCannon');
	Template.Abilities.AddItem('WrathCannonStage1');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sectopod_Turret.WP_Sectopod_WrathCannon";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_Viper_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Viper_WPN');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ViperRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.VIPER_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.VIPER_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Viper_Rifle.WP_ViperRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_Viper_Tongue_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Viper_Tongue_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ViperRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.Aim = 20;

	Template.RangeAccuracy = default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.VIPER_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.VIPER_IDEALRANGE;

	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.Abilities.AddItem('GetOverHere');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Viper_Strangle_and_Pull.WP_Viper_Strangle_and_Pull";
	
	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

// **************************************************************************
// ***                       Enemy Melee Weapons                          ***
// **************************************************************************

static function X2DataTemplate CreateTemplate_Archon_MeleeAttack()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'ArchonStaff');

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'baton';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ArchonStaff";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Archon_Staff.WP_ArchonStaff";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.Aim = default.GENERIC_MELEE_ACCURACY;

	Template.iRange = 0;
	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;
	Template.iIdealRange = 1;

	Template.BaseDamage = default.ARCHON_MELEEATTACK_BASEDAMAGE;
	Template.BaseDamage.DamageType='Melee';
	Template.iSoundRange = 2;
	Template.iEnvironmentDamage = 10;

	//Build Data
	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	Template.Abilities.AddItem('StandardMelee');
	Template.AddAbilityIconOverride('StandardMelee', "img:///UILibrary_PerkIcons.UIPerk_archon_beatdown");

	return Template;
}

static function X2DataTemplate CreateTemplate_AndromedonRobot_MeleeAttack()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AndromedonRobot_MeleeAttack');
	
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'baton';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.Sword";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sword_CV.WP_Sword_CV";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.Aim = default.GENERIC_MELEE_ACCURACY;

	Template.iRange = 2;
	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;
	Template.iIdealRange = 1;

	Template.BaseDamage = default.ANDROMEDONROBOT_MELEEATTACK_BASEDAMAGE;
	Template.BaseDamage.DamageType='Melee';
	Template.iSoundRange = 2;
	Template.iEnvironmentDamage = 10;

	//Build Data
	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	Template.Abilities.AddItem('StandardMelee');

	return Template;
}

//The Berserker uses the ability Devastating Punch (search key: "CreateDevastatingPunchAbility")
//static function X2DataTemplate CreateTemplate_Berserker_MeleeAttack()
//{
//	local X2WeaponTemplate Template;

//	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Berserker_MeleeAttack');
	
//	Template.ItemCat = 'weapon';
//	Template.WeaponCat = 'baton';
//	Template.WeaponTech = 'magnetic';
//	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
//	Template.InventorySlot = eInvSlot_SecondaryWeapon;
//	Template.StowedLocation = eSlot_RightBack;
//	// This all the resources; sounds, animations, models, physics, the works.
//	Template.GameArchetype = "WP_Sword_CV.WP_Sword_CV";
//  Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

//	Template.iRange = 2;
//	Template.iRadius = 1;
//	Template.NumUpgradeSlots = 2;
//	Template.InfiniteAmmo = true;
//	Template.iPhysicsImpulse = 5;
//	Template.iIdealRange = default.BERSERKER_IDEALRANGE;

//	Template.BaseDamage = default.BERSERKER_MELEEATTACK_BASEDAMAGE;
//	Template.BaseDamage.DamageType='Melee';
//	Template.iSoundRange = 2;
//	Template.iEnvironmentDamage = 10;

//	//Build Data
//	Template.StartingItem = false;
//	Template.CanBeBuilt = false;

//	Template.Abilities.AddItem('StandardMelee');

//	return Template;
//}

static function X2DataTemplate CreateTemplate_Faceless_MeleeAoE()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Faceless_MeleeAoE');
	
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'melee';
	Template.WeaponTech = 'alien';
	Template.strImage = "img:///UILibrary_Common.Sword";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sword_CV.WP_Sword_CV";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.iRange = class'X2Ability_Faceless'.default.SCYTHING_CLAWS_LENGTH_TILES;
	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;
	Template.iIdealRange = MAX(class'X2Ability_Faceless'.default.SCYTHING_CLAWS_LENGTH_TILES-1, 1);

	Template.BaseDamage = default.FACELESS_MELEEAOE_BASEDAMAGE;
	Template.BaseDamage.DamageType='Melee';
	Template.iSoundRange = 2;
	Template.iEnvironmentDamage = 10;

	//Build Data
	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	Template.Abilities.AddItem('StandardMelee');

	return Template;
}

static function X2DataTemplate CreateTemplate_Muton_MeleeAttack()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Muton_MeleeAttack');
	
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'baton';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.Sword";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Muton_Bayonet.WP_MutonBayonet";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.iRange = 0;
	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;
	Template.iIdealRange = 1;

	Template.BaseDamage = default.MUTON_MELEEATTACK_BASEDAMAGE;
	Template.BaseDamage.DamageType='Melee';
	Template.iSoundRange = 2;
	Template.iEnvironmentDamage = 10;

	//Build Data
	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	Template.Abilities.AddItem('Bayonet');
	Template.Abilities.AddItem('CounterattackBayonet');

	return Template;
}

static function X2DataTemplate CreateTemplate_PsiZombie_MeleeAttack()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'PsiZombie_MeleeAttack');
	
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'melee';
	Template.WeaponTech = 'alien';
	Template.strImage = "img:///UILibrary_StrategyImages.Sword";
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.StowedLocation = eSlot_RightHand;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Zombiefist.WP_Zombiefist";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.iRange = 2;
	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;
	Template.iIdealRange = 1;

	Template.BaseDamage = default.PSIZOMBIE_MELEEATTACK_BASEDAMAGE;
	Template.BaseDamage.DamageType='Melee';
	Template.iSoundRange = 2;
	Template.iEnvironmentDamage = 10;

	//Build Data
	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	Template.bDisplayWeaponAndAmmo = false;

	Template.Abilities.AddItem('StandardMelee');

	return Template;
}

// ********************************* Stun Lance
static function X2DataTemplate CreateTemplate_AdvStunLancerM1_StunLance()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvStunLancerM1_StunLance');
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'baton';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.Sword";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Adv_StunLancer.WP_StunLance";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.Aim = default.GENERIC_MELEE_ACCURACY;
	//Template.Aim = 10;

	Template.iRange = 0;
	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;
	Template.iIdealRange = 1;

	Template.BaseDamage = default.ADVSTUNLANCERM1_STUNLANCE_BASEDAMAGE;
	Template.BaseDamage.DamageType='Melee';
	Template.iSoundRange = 2;
	Template.iEnvironmentDamage = 0;

	//Build Data
	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	Template.Abilities.AddItem('StunLance');

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvStunLancerM2_StunLance()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvStunLancerM2_StunLance');
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'baton';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.Sword";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Adv_StunLancer.WP_StunLance";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.Aim = default.GENERIC_MELEE_ACCURACY;

	Template.iRange = 0;
	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;

	Template.BaseDamage = default.ADVSTUNLANCERM2_STUNLANCE_BASEDAMAGE;
	Template.BaseDamage.DamageType='Melee';
	Template.iSoundRange = 2;
	Template.iEnvironmentDamage = 0;
	Template.iIdealRange = 1;

	//Build Data
	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	Template.Abilities.AddItem('StunLance');

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvStunLancerM3_StunLance()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvStunLancerM3_StunLance');
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'baton';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.Sword";
	Template.InventorySlot = eInvSlot_SecondaryWeapon;
	Template.StowedLocation = eSlot_RightBack;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Adv_StunLancer.WP_StunLance";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.Aim = default.GENERIC_MELEE_ACCURACY;

	Template.iRange = 0;
	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;
	Template.iIdealRange = 1;

	Template.BaseDamage = default.ADVSTUNLANCERM3_STUNLANCE_BASEDAMAGE;
	Template.BaseDamage.DamageType='Melee';
	Template.iSoundRange = 2;
	Template.iEnvironmentDamage = 0;

	//Build Data
	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	Template.Abilities.AddItem('StunLance');

	return Template;
}
// *********************************

// #######################################################################################
// -------------------- MP WEAPONS -------------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateTemplate_AdvTrooperMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvTrooperMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_MAGNETIC_RANGE;
	Template.BaseDamage = default.ADVTROOPERMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVTROOPERM1_IDEALRANGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvCaptainMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvCaptainMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_MAGNETIC_RANGE;
	Template.BaseDamage = default.ADVCAPTAINMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVCAPTAINM1_IDEALRANGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvStunLancerMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvStunLancerMP_WPN');
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_MAGNETIC_RANGE;
	Template.BaseDamage = default.ADVSTUNLANCERMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVSTUNLANCERM1_IDEALRANGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvShieldBearerMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvShieldBearerMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventAssaultRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_MAGNETIC_RANGE;
	Template.BaseDamage = default.ADVSHIELDBEARERMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVSHIELDBEARERM2_IDEALRANGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AssaultRifle_MG.WP_AssaultRifle_MG_Advent";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_MagAdvent';

	return Template;
}

static function X2DataTemplate CreateTemplate_AdvMEC_MP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AdvMEC_MP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventMecGun";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_MAGNETIC_RANGE;
	Template.BaseDamage = default.ADVMEC_MP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ADVMEC_M1_IDEALRANGE;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Suppression');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_AdvMec_Gun.WP_AdvMecGun";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	Template.DamageTypeTemplateName = 'Projectile_Conventional';

	return Template;
}

static function X2DataTemplate CreateTemplate_SectoidMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'SectoidMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.SectoidPistol";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_BEAM_RANGE;
	Template.BaseDamage = default.SECTOIDMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.SECTOID_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sectoid_ArmPistol.WP_SectoidPistol";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_ViperMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'ViperMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ViperRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_BEAM_RANGE;
	Template.BaseDamage = default.VIPERMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.VIPER_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Viper_Rifle.WP_ViperRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_MutonMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'MutonMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.MutonRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_BEAM_RANGE;
	Template.BaseDamage = default.MUTONMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.MUTON_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('Suppression');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Execute');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Muton_Rifle.WP_MutonRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_CyberusMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'CyberusMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ViperRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_BEAM_RANGE;
	Template.BaseDamage = default.CYBERUSMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.CYBERUS_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InfiniteAmmo = true;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Cyberus_Gun.WP_CyberusRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_ArchonMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'ArchonMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ArchonStaff";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_MAGNETIC_RANGE;
	Template.BaseDamage = default.ARCHONMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ARCHON_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Archon_Rifle.WP_ArchonRifle";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_AndromedonMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AndromedonMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AndromedonRifle";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_BEAM_RANGE;
	Template.BaseDamage = default.ANDROMEDONMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.ANDROMEDON_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('StandardShot');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Andromedon_Cannon.WP_AndromedonCannon";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_SectopodMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'SectopodMP_WPN');

	Template.WeaponPanelImage = "_BeamSniperRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.AdventTurret";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.SECTOPODMP_WPN_BASEDAMAGE;
	Template.iClipSize = default.ASSAULTRIFLE_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.ASSAULTRIFLE_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ASSAULTRIFLE_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iIdealRange = default.SECTOPOD_IDEALRANGE;

	Template.DamageTypeTemplateName = 'Heavy';

	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.Abilities.AddItem('Blaster');
	Template.Abilities.AddItem('BlasterDuringCannon');
	Template.Abilities.AddItem('Overwatch');
	Template.Abilities.AddItem('OverwatchShot');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('HotLoadAmmo');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Sectopod_Turret.WP_Sectopod_Turret";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_GatekeeperMP_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'GatekeeperMP_WPN');

	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'rifle';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.GatekeeperEyeball";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.RangeAccuracy = default.MEDIUM_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.GATEKEEPERMP_WPN_BASEDAMAGE;
	Template.iClipSize = 1;

	Template.InventorySlot = eInvSlot_PrimaryWeapon;

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Gatekeeper_Anima_Gate.WP_Gatekeeper_Anima_Gate";

	Template.iPhysicsImpulse = 5;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;

	return Template;
}

static function X2DataTemplate CreateTemplate_PsiZombieMP_MeleeAttack()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'PsiZombieMP_MeleeAttack');

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'melee';
	Template.WeaponTech = 'alien';
	Template.strImage = "img:///UILibrary_StrategyImages.Sword";
	Template.InventorySlot = eInvSlot_PrimaryWeapon;
	Template.StowedLocation = eSlot_RightHand;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "WP_Zombiefist.WP_Zombiefist";
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); //invalidates multiplayer availability

	Template.iRange = 2;
	Template.iRadius = 1;
	Template.NumUpgradeSlots = 2;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;
	Template.iIdealRange = 1;

	Template.BaseDamage = default.PSIZOMBIEMP_MELEEATTACK_BASEDAMAGE;
	Template.BaseDamage.DamageType = 'Melee';
	Template.iSoundRange = 2;
	Template.iEnvironmentDamage = 10;

	//Build Data
	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	Template.bDisplayWeaponAndAmmo = false;

	Template.Abilities.AddItem('StandardMovingMelee');

	return Template;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = true
}
