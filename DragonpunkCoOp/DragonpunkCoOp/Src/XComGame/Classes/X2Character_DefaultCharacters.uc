class X2Character_DefaultCharacters extends X2Character config(GameData_CharacterStats);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSoldierTemplate());

	Templates.AddItem(CreateTutorialCentralTemplate());
	Templates.AddItem(CreateStrategyCentralTemplate());

	Templates.AddItem(CreateCivilianTemplate());
	Templates.AddItem(CreateFacelessCivilianTemplate());
	Templates.AddItem(CreateHostileCivilianTemplate());
	Templates.AddItem(CreateFriendlyVIPCivilianTemplate());
	Templates.AddItem(CreateFriendlyVIPCivilianTemplate('Soldier_VIP'));
	Templates.AddItem(CreateFriendlyVIPCivilianTemplate('Scientist_VIP'));
	Templates.AddItem(CreateFriendlyVIPCivilianTemplate('Engineer_VIP'));
	Templates.AddItem(CreateHostileVIPCivilianTemplate());
	Templates.AddItem(CreateScientistTemplate());
	Templates.AddItem(CreateHeadScientistTemplate());
	Templates.AddItem(CreateEngineerTemplate());
	Templates.AddItem(CreateHeadEngineerTemplate());
	Templates.AddItem(CreateHeadquartersClerkTemplate());

	Templates.AddItem(CreateCommanderVIPTemplate());
	Templates.AddItem(CreateStasisSuitVIPTemplate());

	Templates.AddItem(CreateGremlinMk1Template());
	Templates.AddItem(CreateGremlinMk2Template());
	Templates.AddItem(CreateGremlinMk3Template());

	Templates.AddItem(CreateTemplate_XComTurretMk1());
	Templates.AddItem(CreateTemplate_XComTurretMk2());

	Templates.AddItem(CreateTemplate_AdvCaptainM1());
	Templates.AddItem(CreateTemplate_AdvCaptainM2());
	Templates.AddItem(CreateTemplate_AdvCaptainM3());
	Templates.AddItem(CreateTemplate_AdvMEC_M1());
	Templates.AddItem(CreateTemplate_AdvMEC_M2());
	Templates.AddItem(CreateTemplate_AdvPsiWitchM2());
	Templates.AddItem(CreateTemplate_AdvPsiWitchM3());
	Templates.AddItem(CreateTemplate_AdvShieldBearerM2());
	Templates.AddItem(CreateTemplate_AdvShieldBearerM3());
	Templates.AddItem(CreateTemplate_AdvStunLancerM1());
	Templates.AddItem(CreateTemplate_AdvStunLancerM2());
	Templates.AddItem(CreateTemplate_AdvStunLancerM3());
	Templates.AddItem(CreateTemplate_AdvTrooperM1());
	Templates.AddItem(CreateTemplate_AdvTrooperM2());
	Templates.AddItem(CreateTemplate_AdvTrooperM3());
	Templates.AddItem(CreateTemplate_AdvTurretMk1());
	Templates.AddItem(CreateTemplate_AdvTurretMk2());
	Templates.AddItem(CreateTemplate_AdvTurretMk3());
	Templates.AddItem(CreateTemplate_AdvShortTurretM1());
	Templates.AddItem(CreateTemplate_AdvShortTurretM2());
	Templates.AddItem(CreateTemplate_AdvShortTurretM3());
	Templates.AddItem(CreateTemplate_AdvShortTurret());
	Templates.AddItem(CreateTemplate_Andromedon());
	Templates.AddItem(CreateTemplate_AndromedonRobot());
	Templates.AddItem(CreateTemplate_Archon());
	Templates.AddItem(CreateTemplate_Berserker());
	Templates.AddItem(CreateTemplate_Chryssalid());
	Templates.AddItem(CreateTemplate_Cyberus());
	Templates.AddItem(CreateTemplate_Faceless());
	Templates.AddItem(CreateTemplate_Gatekeeper());
	Templates.AddItem(CreateTemplate_Muton());
	Templates.AddItem(CreateTemplate_Sectoid());
	Templates.AddItem(CreateTemplate_Sectopod());
	Templates.AddItem(CreateTemplate_PrototypeSectopod());
	Templates.AddItem(CreateTemplate_Viper());
	Templates.AddItem(CreateTemplate_PsiZombie());
	Templates.AddItem(CreateTemplate_PsiZombieHuman());	
	Templates.AddItem(CreateTemplate_TheLost());	
	Templates.AddItem(CreateTemplate_AdventTroopTransport());
	Templates.AddItem(CreateTemplate_ChryssalidCocoon());
	Templates.AddItem(CreateTemplate_ChryssalidCocoonHuman());

	Templates.AddItem(CreateTemplate_MimicBeacon());

	Templates.AddItem(CreateTemplate_TestDummyPanic());

	// characters that only exist to serve as speakers for conversations (template name, speaker name, speaker portrait image path)
	Templates.AddItem(CreateSpeakerTemplate('Council', "Council", "img:///UILibrary_Common.Head_Council"));
	Templates.AddItem(CreateSpeakerTemplate('Denmother', "Denmother", "img:///UILibrary_Common.Head_Denmother"));
	Templates.AddItem(CreateSpeakerTemplate('ShipAI', "Ship AI", "img:///UILibrary_Common.Head_ShipAI"));
	Templates.AddItem(CreateSpeakerTemplate('AdventSpokesman', "Spokesman", "img:///UILibrary_Common.Head_Speaker"));
	Templates.AddItem(CreateSpeakerTemplate('Firebrand', "Firebrand", "img:///UILibrary_Common.Head_Firebrand"));
	Templates.AddItem(CreateSpeakerTemplate('Ethereal', "Ethereal", "img:///UILibrary_Common.Head_Ethereal"));
	Templates.AddItem(CreateSpeakerTemplate('TutorialOsei', "Osei", "img:///UILibrary_Common.Head_Osei"));
	Templates.AddItem(CreateSpeakerTemplate('TutorialRamirez', "Ramirez",  "img:///UILibrary_Common.Head_Ramirez"));
	Templates.AddItem(CreateSpeakerTemplate('TutorialKelly', "Kelly", "img:///UILibrary_Common.Head_Kelly"));
	Templates.AddItem(CreateSpeakerTemplate('Speaker', "Speaker", "img:///UILibrary_Common.Head_Speaker"));
	Templates.AddItem(CreateSpeakerTemplate('PropagandaAnnouncer', "Propaganda Announcer", "img:///UILibrary_Common.Head_Propaganda"));
	Templates.AddItem(CreateSpeakerTemplate('AngelisEthereal', "Angelis Ethereal", "img:///UILibrary_Common.Head_AngelisEthereal"));
	Templates.AddItem(CreateSpeakerTemplate('ShadowShen', "Avenger", "img:///UILibrary_Common.Head_ShadowShen"));
	Templates.AddItem(CreateSpeakerTemplate('EmptyHead', "Empty Head", "img:///UILibrary_Common.Head_Empty"));
	return Templates;
}

// **************************************************************************
// ***                         XCom Templates                             ***
// **************************************************************************

static function X2CharacterTemplate CreateSoldierTemplate()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Soldier');	
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = true;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = true;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bCanBeCarried = true;	
	CharTemplate.bCanBeRevived = true;
	CharTemplate.bUsePoolSoldiers = true;
	CharTemplate.bStaffingAllowed = true;
	CharTemplate.bAppearInBase = true;
	CharTemplate.strMatineePackages.AddItem("CIN_Soldier");
	CharTemplate.strIntroMatineeSlotPrefix = "Char";
	CharTemplate.strLoadingMatineeSlotPrefix = "Soldier";

	CharTemplate.DefaultSoldierClass = 'Rookie';
	CharTemplate.DefaultLoadout = 'RookieSoldier';
	CharTemplate.RequiredLoadout = 'RequiredSoldier';
	CharTemplate.Abilities.AddItem('Loot');
	CharTemplate.Abilities.AddItem('Interact_PlantBomb');
	CharTemplate.Abilities.AddItem('Interact_TakeVial');
	CharTemplate.Abilities.AddItem('Interact_StasisTube');
	CharTemplate.Abilities.AddItem('CarryUnit');
	CharTemplate.Abilities.AddItem('PutDownUnit');
	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('PlaceEvacZone');
	CharTemplate.Abilities.AddItem('LiftOffAvenger');
	CharTemplate.Abilities.AddItem('Knockout');
	CharTemplate.Abilities.AddItem('KnockoutSelf');
	CharTemplate.Abilities.AddItem('Panicked');
	CharTemplate.Abilities.AddItem('HunkerDown');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_XCom;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateTutorialCentralTemplate()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'TutorialCentral');
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = true;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = true;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bCanBeCarried = true;
	CharTemplate.bCanBeRevived = true;
	CharTemplate.strMatineePackages.AddItem("CIN_Soldier");
	CharTemplate.strIntroMatineeSlotPrefix = "Char";
	CharTemplate.strLoadingMatineeSlotPrefix = "Soldier";


	CharTemplate.DefaultLoadout = 'RookieSoldier';
	CharTemplate.RequiredLoadout = 'RequiredSoldier';
	CharTemplate.Abilities.AddItem('Loot');
	CharTemplate.Abilities.AddItem('CarryUnit');
	CharTemplate.Abilities.AddItem('PutDownUnit');
	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('PlaceEvacZone');
	CharTemplate.Abilities.AddItem('LiftOffAvenger');
	CharTemplate.Abilities.AddItem('Knockout');
	CharTemplate.Abilities.AddItem('Panicked');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;
	
	CharTemplate.bForceAppearance = true;
	CharTemplate.ForceAppearance.nmPawn		= 'XCom_Central';
	CharTemplate.ForceAppearance.nmTorso	= 'Central_Torso_A';
	CharTemplate.ForceAppearance.nmArms		= 'Central_Arms_A';
	CharTemplate.ForceAppearance.nmLegs		= 'Central_Legs_A';
	CharTemplate.ForceAppearance.nmHead		= 'Central';
	CharTemplate.ForceAppearance.nmHaircut	= 'Central_Hair';
	CharTemplate.ForceAppearance.nmBeard	= 'Central_Beard';

	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_XCom;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateStrategyCentralTemplate()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'StrategyCentral');
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 27;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = true;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bCanBeCarried = true;
	CharTemplate.bCanBeRevived = true;
	CharTemplate.bAppearInBase = true;
	CharTemplate.strMatineePackages.AddItem("CIN_Soldier");

	CharTemplate.DefaultLoadout = 'RookieSoldier';
	CharTemplate.RequiredLoadout = 'RequiredSoldier';
	CharTemplate.Abilities.AddItem('Loot');
	CharTemplate.Abilities.AddItem('CarryUnit');
	CharTemplate.Abilities.AddItem('PutDownUnit');
	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('PlaceEvacZone');
	CharTemplate.Abilities.AddItem('LiftOffAvenger');
	CharTemplate.Abilities.AddItem('Knockout');
	CharTemplate.Abilities.AddItem('Panicked');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;
	
	CharTemplate.bForceAppearance = true;
	CharTemplate.ForceAppearance.nmPawn		= 'XCom_StratCentral';
	CharTemplate.ForceAppearance.nmTorso	= 'Central_Torso_B';
	CharTemplate.ForceAppearance.nmArms	= 'Central_Arms_B';
	CharTemplate.ForceAppearance.nmLegs	= 'Central_Legs_B';
	CharTemplate.ForceAppearance.nmHead	= 'Central';
	CharTemplate.ForceAppearance.nmHaircut= 'Central_Hair';

	CharTemplate.SpeakerPortrait = "img:///UILibrary_Common.Head_Central";
	
	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_XCom;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateCivilianTemplate(optional name TemplateName = 'Civilian')
{
	local X2CharacterTemplate CharTemplate;
	
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bDisplayUIUnitFlag=false;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_XComCivilians.ARC_Unit_XComCivilianUnisex");

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.Abilities.AddItem('CivilianPanicked');
	CharTemplate.Abilities.AddItem('CivilianInitialState');
	CharTemplate.Abilities.AddItem('CivilianEasyToHit');
	CharTemplate.Abilities.AddItem('CivilianRescuedState');
	CharTemplate.strBehaviorTree="CivRoot";

	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Civilian;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateFacelessCivilianTemplate(optional name TemplateName = 'FacelessCivilian')
{
	local X2CharacterTemplate CharTemplate;
	
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = true;
	CharTemplate.bIsCivilian = true;
	//CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bDisplayUIUnitFlag=false;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_XComCivilians.ARC_Unit_XComCivilianUnisex");

	//CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('ChangeForm');
	CharTemplate.Abilities.AddItem('HunkerDown');
	//CharTemplate.Abilities.AddItem('CivilianPanicked');
	CharTemplate.Abilities.AddItem('CivilianInitialState');

	CharTemplate.strBehaviorTree="FacelessCivRoot";
	CharTemplate.strPanicBT = "";

	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Civilian;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateHostileCivilianTemplate( )
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = CreateCivilianTemplate( 'HostileCivilian' );
	
	CharTemplate.bIsHostileCivilian = true;
	CharTemplate.strBehaviorTree = "HostileCivRoot";

	CharTemplate.bShouldCreateDifficultyVariants = false;

	return CharTemplate;
}

static function X2CharacterTemplate CreateFriendlyVIPCivilianTemplate(optional name TemplateName = 'FriendlyVIPCivilian')
{
	local X2CharacterTemplate CharTemplate;
	
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);
	CharTemplate.CharacterBaseStats[eStat_HP] = 5;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 14;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.CanFlankUnits = false;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCarried = true;
	CharTemplate.bCanBeRevived = true;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bUsePoolVIPs = true;

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	//CharTemplate.Abilities.AddItem('Panicked');
	CharTemplate.strBehaviorTree="VIPCowardRoot";

	CharTemplate.strPanicBT="";

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_VIP;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;

}

static function X2CharacterTemplate CreateCommanderVIPTemplate(optional name TemplateName = 'CommanderVIP')
{
	local X2CharacterTemplate CharTemplate;
	
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);

	CharTemplate.strPawnArchetypes.AddItem("GameUnit_StasisSuit.ARC_StasisSuitVIP");
	
	CharTemplate.CharacterBaseStats[eStat_HP] = 5;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 6;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 14;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;

	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.strIntroMatineeSlotPrefix = "Char";

	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;

	CharTemplate.bCanBeCarried = true;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.Abilities.AddItem('KnockoutSelf');
	CharTemplate.strBehaviorTree="VIPRoot";

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_VIP;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateStasisSuitVIPTemplate(optional name TemplateName = 'StasisSuitVIP')
{
	local X2CharacterTemplate CharTemplate;
	
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);

	CharTemplate.strPawnArchetypes.AddItem("GameUnit_StasisSuit.ARC_StasisSuitVIP_Silver");
	
	CharTemplate.CharacterBaseStats[eStat_HP] = 5;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 6;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 14;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;

	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';

	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;

	CharTemplate.bCanBeCarried = true;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.Abilities.AddItem('KnockoutSelf');
	CharTemplate.strBehaviorTree="VIPRoot";

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_VIP;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateHostileVIPCivilianTemplate()
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = CreateCivilianTemplate('HostileVIPCivilian');
	CharTemplate.CharacterBaseStats[eStat_HP] = 5;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 14;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.CharacterBaseStats[eStat_DetectionRadius] = 6;
	CharTemplate.UnitSize = 1;
	CharTemplate.CanFlankUnits = false;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bIsHostileCivilian = true;
	CharTemplate.bCanBeCarried = true;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bUsePoolDarkVIPs = true;

	// TODO: Set behavior tree here
	CharTemplate.strBehaviorTree = "VIPCowardRoot";
	CharTemplate.strPanicBT = "";

	//CharTemplate.Abilities.AddItem('Panicked');

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_VIP;

	return CharTemplate;
}

static function X2CharacterTemplate CreateScientistTemplate()
{
	local X2CharacterTemplate CharTemplate;
	
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Scientist');
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 27;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = true;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsScientist = true;
	CharTemplate.bCanTakeCover = true;	
	CharTemplate.bUsePoolVIPs = true;
	CharTemplate.bStaffingAllowed = true;
	CharTemplate.bAppearInBase = true;

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.strBehaviorTree="VIPCowardRoot";

	// Level-up Thresholds
	CharTemplate.SkillLevelThresholds[0] = 0;
	CharTemplate.SkillLevelThresholds[1] = 0;
	CharTemplate.SkillLevelThresholds[2] = 0;
	CharTemplate.SkillLevelThresholds[3] = 0;
	CharTemplate.SkillLevelThresholds[4] = 0;
	CharTemplate.SkillLevelThresholds[5] = 0;
	CharTemplate.SkillLevelThresholds[6] = 600;
	CharTemplate.SkillLevelThresholds[7] = 1500;
	CharTemplate.SkillLevelThresholds[8] = 2500;
	CharTemplate.SkillLevelThresholds[9] = 4000;
	CharTemplate.SkillLevelThresholds[10] = 6000;
		
	//Give this character type a specific palette selection
	CharTemplate.DefaultAppearance.iArmorTint = class'XComContentManager'.default.DefaultScientistArmorTint;
	CharTemplate.DefaultAppearance.iArmorTintSecondary = class'XComContentManager'.default.DefaultScientistArmorTintSecondary;

	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Civilian;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateHeadScientistTemplate()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'HeadScientist');
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 27;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = true;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsScientist = true;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bStaffingAllowed = false;
	CharTemplate.bAppearInBase = true;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_HeadScientist.ARC_Unit_HeadScientist");

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.strBehaviorTree = "CivRoot";

	// Level-up Thresholds
	CharTemplate.SkillLevelThresholds[0] = 0;
	CharTemplate.SkillLevelThresholds[1] = 0;
	CharTemplate.SkillLevelThresholds[2] = 0;
	CharTemplate.SkillLevelThresholds[3] = 0;
	CharTemplate.SkillLevelThresholds[4] = 0;
	CharTemplate.SkillLevelThresholds[5] = 0;
	CharTemplate.SkillLevelThresholds[6] = 0;
	CharTemplate.SkillLevelThresholds[7] = 0;
	CharTemplate.SkillLevelThresholds[8] = 0;
	CharTemplate.SkillLevelThresholds[9] = 0;
	CharTemplate.SkillLevelThresholds[10] = 0;
	
	CharTemplate.SpeakerPortrait = "img:///UILibrary_Common.Head_Tygan";
	
	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Civilian;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateEngineerTemplate()
{
	local X2CharacterTemplate CharTemplate;
	
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Engineer');
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 27;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = true;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsEngineer = true;
	CharTemplate.bCanTakeCover = true;	
	CharTemplate.bUsePoolVIPs = true;
	CharTemplate.bStaffingAllowed = true;
	CharTemplate.bAppearInBase = true;

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.strBehaviorTree="VIPCowardRoot";

	// Level-up Thresholds
	CharTemplate.SkillLevelThresholds[0] = 0;
	CharTemplate.SkillLevelThresholds[1] = 0;
	CharTemplate.SkillLevelThresholds[2] = 0;
	CharTemplate.SkillLevelThresholds[3] = 0;
	CharTemplate.SkillLevelThresholds[4] = 0;
	CharTemplate.SkillLevelThresholds[5] = 0;
	CharTemplate.SkillLevelThresholds[6] = 600;
	CharTemplate.SkillLevelThresholds[7] = 1500;
	CharTemplate.SkillLevelThresholds[8] = 2500;
	CharTemplate.SkillLevelThresholds[9] = 4000;
	CharTemplate.SkillLevelThresholds[10] = 6000;

	//Give this character type a specific palette selection
	CharTemplate.DefaultAppearance.iArmorTint = class'XComContentManager'.default.DefaultEngineerArmorTint;
	CharTemplate.DefaultAppearance.iArmorTintSecondary = class'XComContentManager'.default.DefaultEngineerArmorTintSecondary;

	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Civilian;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateHeadEngineerTemplate()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'HeadEngineer');
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 27;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = true;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsEngineer = true;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bStaffingAllowed = false;
	CharTemplate.bAppearInBase = true;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_HeadEngineer.ARC_Unit_HeadEngineer");	

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.strBehaviorTree = "CivRoot";

	// Level-up Thresholds
	CharTemplate.SkillLevelThresholds[0] = 0;
	CharTemplate.SkillLevelThresholds[1] = 0;
	CharTemplate.SkillLevelThresholds[2] = 0;
	CharTemplate.SkillLevelThresholds[3] = 0;
	CharTemplate.SkillLevelThresholds[4] = 0;
	CharTemplate.SkillLevelThresholds[5] = 0;
	CharTemplate.SkillLevelThresholds[6] = 600;
	CharTemplate.SkillLevelThresholds[7] = 1500;
	CharTemplate.SkillLevelThresholds[8] = 2500;
	CharTemplate.SkillLevelThresholds[9] = 4000;
	CharTemplate.SkillLevelThresholds[10] = 6000;
	
	CharTemplate.SpeakerPortrait = "img:///UILibrary_Common.Head_Shen";

	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Civilian;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateHeadquartersClerkTemplate()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Clerk');
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 27;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = true;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsEngineer = false;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bUsePoolVIPs = false;
	CharTemplate.bStaffingAllowed = false;
	CharTemplate.bAppearInBase = true;

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.strBehaviorTree = "VIPCowardRoot";

	//Give this character type a specific palette selection
	CharTemplate.DefaultAppearance.iArmorTint = -1;
	CharTemplate.DefaultAppearance.iArmorTintSecondary = -1;

	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Civilian;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}

static function X2CharacterTemplate CreateGremlinMk1Template()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'GremlinMk1');
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 1;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.AvengerOffset.X = 45;
	CharTemplate.AvengerOffset.Y = 90;
	CharTemplate.AvengerOffset.Z = -20;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanUse_eTraversal_Launch = true;
	CharTemplate.bCanUse_eTraversal_Flying = true;
	CharTemplate.bCanUse_eTraversal_Land = true;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bIsAfraidOfFire = false;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = false;
	CharTemplate.bIsCosmetic = true;
	CharTemplate.bDisplayUIUnitFlag=false;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_GremlinMk1.ARC_GameUnit_GremlinMk1");
	CharTemplate.bAllowRushCam = false;
	CharTemplate.SoloMoveSpeedModifier = 2.0f;

	CharTemplate.HQIdleAnim = "HL_Idle";
	CharTemplate.HQOffscreenAnim = "HL_FlyUpStart";
	CharTemplate.HQOnscreenAnimPrefix = "HL_FlyDwn";
	CharTemplate.HQOnscreenOffset.X = 0;
	CharTemplate.HQOnscreenOffset.Y = 0;
	CharTemplate.HQOnscreenOffset.Z = 96.0f;

	CharTemplate.Abilities.AddItem('Panicked');

	return CharTemplate;
}

static function X2CharacterTemplate CreateGremlinMk2Template()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'GremlinMk2');
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 1;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.AvengerOffset.X = 45;
	CharTemplate.AvengerOffset.Y = 90;
	CharTemplate.AvengerOffset.Z = -20;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanUse_eTraversal_Launch = true;
	CharTemplate.bCanUse_eTraversal_Flying = true;
	CharTemplate.bCanUse_eTraversal_Land = true;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bIsAfraidOfFire = false;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = false;
	CharTemplate.bIsCosmetic = true;
	CharTemplate.bDisplayUIUnitFlag=false;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_GremlinMk2.ARC_GameUnit_GremlinMk2");
	CharTemplate.bAllowRushCam = false;
	CharTemplate.SoloMoveSpeedModifier = 2.0f;

	CharTemplate.HQIdleAnim = "HL_Idle";
	CharTemplate.HQOffscreenAnim = "HL_FlyUpStart";
	CharTemplate.HQOnscreenAnimPrefix = "HL_FlyDwn";
	CharTemplate.HQOnscreenOffset.X = 0;
	CharTemplate.HQOnscreenOffset.Y = 0;
	CharTemplate.HQOnscreenOffset.Z = 96.0f;

	CharTemplate.Abilities.AddItem('Panicked');

	return CharTemplate;
}

static function X2CharacterTemplate CreateGremlinMk3Template()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'GremlinMk3');
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 12;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 1;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;
	CharTemplate.AvengerOffset.X = 45;
	CharTemplate.AvengerOffset.Y = 90;
	CharTemplate.AvengerOffset.Z = -20;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanUse_eTraversal_Launch = true;
	CharTemplate.bCanUse_eTraversal_Flying = true;
	CharTemplate.bCanUse_eTraversal_Land = true;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bIsAfraidOfFire = false;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = false;
	CharTemplate.bIsCosmetic = true;
	CharTemplate.bDisplayUIUnitFlag=false;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_GremlinMk3.ARC_GameUnit_GremlinMk3");
	CharTemplate.bAllowRushCam = false;
	CharTemplate.SoloMoveSpeedModifier = 2.0f;

	CharTemplate.HQIdleAnim = "HL_Idle";
	CharTemplate.HQOffscreenAnim = "HL_FlyUpStart";
	CharTemplate.HQOnscreenAnimPrefix = "HL_FlyDwn";
	CharTemplate.HQOnscreenOffset.X = 0;
	CharTemplate.HQOnscreenOffset.Y = 0;
	CharTemplate.HQOnscreenOffset.Z = 96.0f;

	CharTemplate.Abilities.AddItem('Panicked');

	return CharTemplate;
}

static function CreateDefaultTurretTemplate(out X2CharacterTemplate CharTemplate, Name TemplateName, bool bShort=false)
{
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);
	CharTemplate.BehaviorClass = class'XGAIBehavior';
	CharTemplate.strMatineePackages.AddItem("CIN_Turret");
	CharTemplate.strTargetingMatineePrefix = "CIN_Turret_FF_StartPos";
	if( bShort )
	{
		CharTemplate.RevealMatineePrefix = "CIN_Turret_Short";
		CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTurret.ARC_GameUnit_AdvTurretVan");
	}
	else
	{
		CharTemplate.RevealMatineePrefix = "CIN_Turret_Tall";
		CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTurret.ARC_GameUnit_AdvTurretM1");
	}

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = true;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsTurret = true;

	CharTemplate.UnitSize = 1;
	CharTemplate.VisionArcDegrees = 360;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;

	CharTemplate.bAllowSpawnFromATT = false;
	CharTemplate.bSkipDefaultAbilities = true;

	CharTemplate.bBlocksPathingWhenDead = true;

	CharTemplate.ImmuneTypes.AddItem('Fire');
	CharTemplate.ImmuneTypes.AddItem('Poison');
	CharTemplate.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType);
	CharTemplate.ImmuneTypes.AddItem('Panic');

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_turret_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Turret;

	CharTemplate.bDisablePodRevealMovementChecks = true;
}

static function X2CharacterTemplate CreateTemplate_XComTurretMk1(optional name TemplateName = 'XComTurretM1')
{
	local X2CharacterTemplate CharTemplate;

	CreateDefaultTurretTemplate(CharTemplate, TemplateName);
	CharTemplate.DefaultLoadout = 'XComTurretM1_Loadout';
	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_XComTurretMk2(optional name TemplateName = 'XComTurretM2')
{
	local X2CharacterTemplate CharTemplate;

	CreateDefaultTurretTemplate(CharTemplate, TemplateName);
	CharTemplate.DefaultLoadout = 'XComTurretM2_Loadout';
	return CharTemplate;
}

// **************************************************************************
// ***                         Enemy Templates                            ***
// **************************************************************************

// **************************************************************************

static function X2CharacterTemplate CreateTemplate_AdventTroopTransport( )
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdventTroopTransport');
	CharTemplate.DefaultLoadout = 'AdvCaptainM1_Loadout';
	CharTemplate.BehaviorClass = class'XGAIBehavior_AdventTroopTransport';
	CharTemplate.strPawnArchetypes.AddItem( "GameUnit_AdventTroopTransport.ARC_GameUnit_AdventTroopTransport" );

	CharTemplate.UnitSize = 4;
	CharTemplate.bCanUse_eTraversal_Normal = false;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = false;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = false;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bIsAfraidOfFire = false;
	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = false;
	CharTemplate.bSkipDefaultAbilities = true;
	CharTemplate.bDoesAlwaysFly = true;
	CharTemplate.strMatineePackages.AddItem("CIN_Advent");

	Loot.ForceLevel = 0;
	CharTemplate.Loot.LootReferences.AddItem( Loot );
	Loot.LootTableName = 'SectoidMidGameLoot';
	Loot.ForceLevel = 2;
	CharTemplate.Loot.LootReferences.AddItem( Loot );

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvCaptainM1()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvCaptainM1');
	CharTemplate.CharacterGroupName = 'AdventCaptain';
	CharTemplate.DefaultLoadout='AdvCaptainM1_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvCaptain.ARC_GameUnit_AdvCaptainM1_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvCaptain.ARC_GameUnit_AdvCaptainM1_F");
	Loot.ForceLevel = 0;
	Loot.LootTableName='AdvCaptainM1_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvCaptainM1_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvCaptainM1_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_Captain";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.Abilities.AddItem('MarkTarget');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvCaptainM1');
	CharTemplate.SightedEvents.AddItem('AdventCaptainSighted');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvCaptainM2()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvCaptainM2');
	CharTemplate.CharacterGroupName = 'AdventCaptain';
	CharTemplate.DefaultLoadout='AdvCaptainM2_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvCaptain.ARC_GameUnit_AdvCaptainM2_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvCaptain.ARC_GameUnit_AdvCaptainM2_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvCaptainM2_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvCaptainM2_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvCaptainM2_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_Captain";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvCaptainM2');
	CharTemplate.SightedEvents.AddItem('AdventCaptainSighted');

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.Abilities.AddItem('MarkTarget');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvCaptainM3()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvCaptainM3');
	CharTemplate.CharacterGroupName = 'AdventCaptain';
	CharTemplate.DefaultLoadout='AdvCaptainM3_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvCaptain.ARC_GameUnit_AdvCaptainM3_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvCaptain.ARC_GameUnit_AdvCaptainM3_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvCaptainM3_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvCaptainM3_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvCaptainM3_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_Captain";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.Abilities.AddItem('MarkTarget');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvCaptainM3');
	CharTemplate.SightedEvents.AddItem('AdventCaptainSighted');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvMEC_M1()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvMEC_M1');
	CharTemplate.CharacterGroupName = 'AdventMEC';
	CharTemplate.DefaultLoadout='AdvMEC_M1_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvMEC_M3.ARC_GameUnit_AdvMEC_M3");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvMEC_M1_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvMEC_M1_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvMEC_M1_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_AdventMEC");
	CharTemplate.strTargetingMatineePrefix = "CIN_AdventMEC_FF_StartPos";

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.Enemy_Sighted_ADVENTmec');

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = true;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = true;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bFacesAwayFromPod = true;

	CharTemplate.strScamperBT = "ScamperRoot_Flanker";

	CharTemplate.Abilities.AddItem('RobotImmunities');

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_robot_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvMEC_M2()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvMEC_M2');
	CharTemplate.CharacterGroupName = 'AdventMEC';
	CharTemplate.DefaultLoadout='AdvMEC_M2_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvMEC_M2.ARC_GameUnit_AdvMEC_M2");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvMEC_M2_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvMEC_M2_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvMEC_M2_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_AdventMEC");
	CharTemplate.strTargetingMatineePrefix = "CIN_AdventMEC_FF_StartPos";

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = true;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = true;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bFacesAwayFromPod = true;

	//CharTemplate.strScamperBT = "ScamperRoot_NoCover";
	CharTemplate.strScamperBT = "ScamperRoot_Overwatch";

	CharTemplate.Abilities.AddItem('RobotImmunities');

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_robot_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvPsiWitchM2()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvPsiWitchM2');
	CharTemplate.CharacterGroupName = 'AdventPsiWitch';
	CharTemplate.DefaultLoadout='AdvPsiWitchM2_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvPsiWitch.ARC_GameUnit_AdvPsiWitchM2_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvPsiWitch.ARC_GameUnit_AdvPsiWitchM2_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvPsiWitchM2_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvPsiWitchM2_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvPsiWitchM2_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_Avatar";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = true;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.Abilities.AddItem('AvatarInitialization');

	CharTemplate.ImmuneTypes.AddItem('Mental');
	
	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;
	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvPsiWitchM3()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvPsiWitchM3');
	CharTemplate.CharacterGroupName = 'AdventPsiWitch';
	CharTemplate.DefaultLoadout='AdvPsiWitchM3_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvPsiWitch.ARC_GameUnit_AdvPsiWitchM3_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvPsiWitch.ARC_GameUnit_AdvPsiWitchM3_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvPsiWitchM3_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvPsiWitchM3_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvPsiWitchM3_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_Avatar";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = true;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.Abilities.AddItem('AvatarInitialization');
	CharTemplate.Abilities.AddItem('TriggerDamagedTeleportListener');
	CharTemplate.Abilities.AddItem('AvatarDamagedTeleport');

	CharTemplate.ImmuneTypes.AddItem('Mental');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.T_Incomplete_Avatar_Sighted_Tygan');
	CharTemplate.DeathEvent = 'KilledAnAvatar';

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	CharTemplate.OnStatAssignmentCompleteFn = OnPsiWitchStatAssignmentComplete;

	return CharTemplate;
}

function OnPsiWitchStatAssignmentComplete(XComGameState_Unit UnitState)
{
	if ((class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T1_M5_SKULLJACKCodex') == eObjectiveState_InProgress || 
		class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T1_M6_KillAvatar') == eObjectiveState_InProgress))
	{
		UnitState.SetCurrentStat(eStat_HP, UnitState.GetMaxStat(eStat_HP) * class'X2TacticalGameRuleset'.default.DepletedAvatarHealthMod);
	}
}

static function X2CharacterTemplate CreateTemplate_AdvShieldBearerM2()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvShieldBearerM2');
	CharTemplate.CharacterGroupName = 'AdventShieldBearer';
	CharTemplate.DefaultLoadout='AdvShieldBearerM2_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvShieldBearer.ARC_GameUnit_AdvShieldBearerM2_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvShieldBearer.ARC_GameUnit_AdvShieldBearerM2_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvShieldBearerM2_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvShieldBearerM2_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvShieldBearerM2_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_ShieldBearer";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.Abilities.AddItem('EnergyShield');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvShieldBearerM2');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvShieldBearerM3()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvShieldBearerM3');
	CharTemplate.CharacterGroupName = 'AdventShieldBearer';
	CharTemplate.DefaultLoadout='AdvShieldBearerM3_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvShieldBearer.ARC_GameUnit_AdvShieldBearerM3_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvShieldBearer.ARC_GameUnit_AdvShieldBearerM3_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvShieldBearerM3_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvShieldBearerM3_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvShieldBearerM3_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_ShieldBearer";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.Abilities.AddItem('EnergyShieldMk3');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.T_Central_AlienSightings_AdvShieldBearerM3');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvStunLancerM1()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvStunLancerM1');
	CharTemplate.CharacterGroupName = 'AdventStunLancer';
	CharTemplate.DefaultLoadout='AdvStunLancerM1_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvStunLancer.ARC_GameUnit_AdvStunLancerM1_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvStunLancer.ARC_GameUnit_AdvStunLancerM1_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvStunLancerM1_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvStunLancerM1_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvStunLancerM1_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_StunLancer";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvStunLancerM1');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvStunLancerM2()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvStunLancerM2');
	CharTemplate.CharacterGroupName = 'AdventStunLancer';
	CharTemplate.DefaultLoadout='AdvStunLancerM2_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvStunLancer.ARC_GameUnit_AdvStunLancerM2_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvStunLancer.ARC_GameUnit_AdvStunLancerM2_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvStunLancerM2_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvStunLancerM2_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvStunLancerM2_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_StunLancer";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvStunLancerM2');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvStunLancerM3()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvStunLancerM3');
	CharTemplate.CharacterGroupName = 'AdventStunLancer';
	CharTemplate.DefaultLoadout='AdvStunLancerM3_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvStunLancer.ARC_GameUnit_AdvStunLancerM3_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvStunLancer.ARC_GameUnit_AdvStunLancerM3_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvStunLancerM3_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvStunLancerM3_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvStunLancerM3_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_StunLancer";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.T_Central_AlienSightings_AdvStunLancerM3');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvTrooperM1()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvTrooperM1');
	CharTemplate.CharacterGroupName = 'AdventTrooper';
	CharTemplate.DefaultLoadout='AdvTrooperM1_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTrooper.ARC_GameUnit_AdvTrooperM1_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTrooper.ARC_GameUnit_AdvTrooperM1_F");

	// Auto-Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvTrooperM1_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvTrooperM1_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvTrooperM1_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_Trooper";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;
	
	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvTrooperM1');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvTrooperM2()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvTrooperM2');
	CharTemplate.CharacterGroupName = 'AdventTrooper';
	CharTemplate.DefaultLoadout='AdvTrooperM2_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTrooper.ARC_GameUnit_AdvTrooperM2_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTrooper.ARC_GameUnit_AdvTrooperM2_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvTrooperM2_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvTrooperM2_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvTrooperM2_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_Trooper";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;   
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvTrooperM2');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvTrooperM3()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AdvTrooperM3');
	CharTemplate.CharacterGroupName = 'AdventTrooper';
	CharTemplate.DefaultLoadout='AdvTrooperM3_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTrooper.ARC_GameUnit_AdvTrooperM3_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTrooper.ARC_GameUnit_AdvTrooperM3_F");
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvTrooperM3_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvTrooperM3_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvTrooperM3_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");
	CharTemplate.RevealMatineePrefix = "CIN_Advent_Trooper";
	CharTemplate.GetRevealMatineePrefixFn = GetAdventMatineePrefix;

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvTrooperM3');
	
	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_captain_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvTurretMk1(optional name TemplateName = 'AdvTurretM1', optional bool bShort=false)
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	CreateDefaultTurretTemplate(CharTemplate, TemplateName, bShort);

	CharTemplate.CharacterGroupName = 'AdventTurret';
	CharTemplate.DefaultLoadout='AdvTurretM1_Loadout';

	Loot.ForceLevel=0;
	Loot.LootTableName='AdvTurretM1_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	CharTemplate.bIsAdvent = true;
	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.T_Shen_AlienSightings_Turret');

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvTurretMk2(optional name TemplateName = 'AdvTurretM2', optional bool bShort=false)
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	CreateDefaultTurretTemplate(CharTemplate, TemplateName, bShort);

	CharTemplate.CharacterGroupName = 'AdventTurret';
	CharTemplate.DefaultLoadout='AdvTurretM2_Loadout';
	
	Loot.ForceLevel=0;
	Loot.LootTableName='AdvTurretM2_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	CharTemplate.bIsAdvent = true;
	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Shen_AlienSightings_Turret_MK2');

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvTurretMk3(optional name TemplateName = 'AdvTurretM3', optional bool bShort=false)
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	CreateDefaultTurretTemplate(CharTemplate, TemplateName, bShort);

	CharTemplate.CharacterGroupName = 'AdventTurret';
	CharTemplate.DefaultLoadout='AdvTurretM3_Loadout';

	Loot.ForceLevel=0;
	Loot.LootTableName='AdvTurretM3_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	CharTemplate.bIsAdvent = true;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvShortTurret()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	CreateDefaultTurretTemplate(CharTemplate, 'AdvShortTurret', true);

	CharTemplate.CharacterGroupName = 'AdventTurret';
	CharTemplate.DefaultLoadout = 'AdvShortTurretM1_Loadout';

	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvTurretM1_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);
	
	CharTemplate.bIsAdvent = true;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvShortTurretM1()
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = CreateTemplate_AdvTurretMk1( 'AdvShortTurretM1', true );
	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.T_Shen_AlienSightings_Turret');

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvShortTurretM2()
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = CreateTemplate_AdvTurretMk2( 'AdvShortTurretM2', true );
	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Shen_AlienSightings_Turret_MK2');

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AdvShortTurretM3()
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = CreateTemplate_AdvTurretMk3('AdvShortTurretM3', true);
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTurret.ARC_GameUnit_AdvTurretVan");

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Andromedon()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Andromedon');
	CharTemplate.CharacterGroupName = 'Andromedon';
	CharTemplate.DefaultLoadout='Andromedon_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Andromedon.ARC_GameUnit_Andromedon");
	//Loot.ForceLevel=0;
	//Loot.LootTableName='Andromedon_BaseLoot';
	//CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Andromedon_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Andromedon_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Andromedon");
	CharTemplate.strMatineePackages.AddItem("CIN_Muton");
	CharTemplate.strTargetingMatineePrefix = "CIN_Muton_FF_StartPos";

	CharTemplate.UnitSize = 1;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.Abilities.AddItem('SwitchToRobot');
	CharTemplate.Abilities.AddItem('AndromedonImmunities');
	CharTemplate.Abilities.AddItem('BigDamnPunch');
	CharTemplate.Abilities.AddItem('WallBreaking');
	CharTemplate.Abilities.AddItem('WallSmash');
	CharTemplate.Abilities.AddItem('RobotBattlesuit');
	//CharTemplate.Abilities.AddItem('ShellLauncher');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_Andromedon');

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_AndromedonRobot()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'AndromedonRobot');
	CharTemplate.CharacterGroupName = 'AndromedonRobot';
	CharTemplate.DefaultLoadout='AndromedonRobot_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Andromedon.ARC_GameUnit_Andromedon_Robot_Suit");
	Loot.ForceLevel=0;
	Loot.LootTableName='AndromedonRobot_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	//Loot.ForceLevel = 0;
	//Loot.LootTableName = 'AndromedonRobot_TimedLoot';
	//CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	//Loot.LootTableName = 'AndromedonRobot_VultureLoot';
	//CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Andromedon");
	CharTemplate.strMatineePackages.AddItem("CIN_Muton");
	CharTemplate.strTargetingMatineePrefix = "CIN_Muton_FF_StartPos";

	CharTemplate.UnitSize = 1;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = false;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = true;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;
	
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.Abilities.AddItem('AndromedonRobotImmunities');
	CharTemplate.Abilities.AddItem('BigDamnPunch');
	CharTemplate.Abilities.AddItem('AndromedonRobotAcidTrail');
	CharTemplate.Abilities.AddItem('WallBreaking');
	CharTemplate.Abilities.AddItem('WallSmash');
	CharTemplate.Abilities.AddItem('RobotReboot');

	CharTemplate.strScamperBT = "ScamperRoot_NoCover";

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_First_Andromedon_Battlesuit');
	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_robot_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Archon()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Archon');
	CharTemplate.CharacterGroupName = 'Archon';
	CharTemplate.DefaultLoadout='Archon_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Archon.ARC_GameUnit_Archon");
	Loot.ForceLevel=0;
	Loot.LootTableName='Archon_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Archon_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Archon_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Archon");
	CharTemplate.strMatineePackages.AddItem("CIN_AdventMEC");
	CharTemplate.strTargetingMatineePrefix = "CIN_AdventMEC_FF_StartPos";

	CharTemplate.UnitSize = 1;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanUse_eTraversal_Launch = true;
	CharTemplate.bCanUse_eTraversal_Flying = true;
	CharTemplate.bCanUse_eTraversal_Land = true;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;
	
	CharTemplate.strScamperBT = "ScamperRoot_NoCover";

	CharTemplate.Abilities.AddItem('FrenzyDamageListener');
	CharTemplate.Abilities.AddItem('BlazingPinionsStage1');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.Enemy_Sighted_Archon');

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Berserker()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Berserker');
	CharTemplate.CharacterGroupName = 'Berserker';
	CharTemplate.DefaultLoadout='Berserker_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Berserker.ARC_GameUnit_Berserker");
	Loot.ForceLevel=0;
	Loot.LootTableName='Berserker_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	//Loot.ForceLevel = 0;
	//Loot.LootTableName = 'Berserker_TimedLoot';
	//CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	//Loot.LootTableName = 'Berserker_VultureLoot';
	//CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Berserker");

	CharTemplate.UnitSize = 1;
	CharTemplate.UnitHeight = 3; //One unit taller than normal
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsMeleeOnly = true;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.bAllowSpawnFromATT = false;
	CharTemplate.bAllowRushCam = false;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;
	CharTemplate.strScamperBT = "ScamperRoot_MeleeNoCover";

	CharTemplate.Abilities.AddItem('TriggerRageDamageListener');
	CharTemplate.Abilities.AddItem('DevastatingPunch');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_Berserker');

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Chryssalid()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Chryssalid');
	CharTemplate.CharacterGroupName = 'Chryssalid';
	CharTemplate.DefaultLoadout='Chryssalid_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Chryssalid.ARC_GameUnit_Chryssalid");
	Loot.ForceLevel=0;
	Loot.LootTableName='Chryssalid_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	//Loot.ForceLevel = 0;
	//Loot.LootTableName = 'Chryssalid_TimedLoot';
	//CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	//Loot.LootTableName = 'Chryssalid_VultureLoot';
	//CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Chryssalid");

	CharTemplate.UnitSize = 1;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = true;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsMeleeOnly = true;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;
	CharTemplate.strScamperBT = "ChryssalidScamperRoot";

	CharTemplate.Abilities.AddItem('ChryssalidSlash');
	CharTemplate.Abilities.AddItem('ChryssalidBurrow');
	CharTemplate.Abilities.AddItem('ChyssalidPoison');
	CharTemplate.Abilities.AddItem('ChryssalidImmunities');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_Cryssalid');

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Cyberus()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Cyberus');
	CharTemplate.CharacterGroupName = 'Cyberus';
	CharTemplate.DefaultLoadout='Cyberus_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Cyberus.ARC_GameUnit_Cyberus");
	Loot.ForceLevel=0;
	Loot.LootTableName='Cyberus_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Cyberus_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Cyberus_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Cyberus");

	CharTemplate.UnitSize = 1;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = true;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bWeakAgainstTechLikeRobot = true;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.Abilities.AddItem('Teleport');
//  CharTemplate.Abilities.AddItem('Malfunction');
	CharTemplate.Abilities.AddItem('PsiBombStage1');
	CharTemplate.Abilities.AddItem('TriggerSuperpositionDamageListener');
//	CharTemplate.Abilities.AddItem('StunnedDeath');
	CharTemplate.Abilities.AddItem('Superposition');
//	CharTemplate.Abilities.AddItem('TechVulnerability');
	CharTemplate.Abilities.AddItem('CodexImmunities');
	
	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.goldenpath.GP_FirstCodexAppears');
	CharTemplate.SightedEvents.AddItem('CyberusSighted');
	CharTemplate.DeathEvent = 'KilledACodex';

	CharTemplate.SpawnRequirements.RequiredObjectives.AddItem('T1_M2_HackACaptain');

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_codex_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	CharTemplate.ReactionFireDeathAnim = 'HL_DeathDefaultA'; //This has the anim notify for hiding the character mesh.

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Faceless()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Faceless');
	CharTemplate.CharacterGroupName = 'Faceless';
	CharTemplate.DefaultLoadout='Faceless_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Faceless.ARC_GameUnit_Faceless");
	Loot.ForceLevel=0;
	Loot.LootTableName='Faceless_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Faceless_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Faceless_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Faceless");

	CharTemplate.UnitSize = 1;
	CharTemplate.UnitHeight = 4; //Faceless is tall

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = true;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsMeleeOnly = true;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;
	CharTemplate.strScamperBT = "ScamperRoot_NoCover";

	CharTemplate.Abilities.AddItem('FacelessInit');
	CharTemplate.Abilities.AddItem('ScythingClaws');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_Faceless');
	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Tygan_AlienSightings_Faceless');
	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Shen_AlienSightings_Faceless');

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Gatekeeper()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Gatekeeper');
	CharTemplate.CharacterGroupName = 'Gatekeeper';
	CharTemplate.DefaultLoadout='Gatekeeper_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Gatekeeper.ARC_GameUnit_Gatekeeper");
	Loot.ForceLevel=0;
	Loot.LootTableName='Gatekeeper_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Gatekeeper_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Gatekeeper_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Gatekeeper");
	CharTemplate.GetRevealMatineePrefixFn = GetGateKeeperRevealMatineePrefix;
	CharTemplate.strTargetingMatineePrefix = "CIN_Gatekeeper_FF_StartPos";	

	CharTemplate.UnitSize = 2;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = false;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanUse_eTraversal_Launch = true;
	CharTemplate.bCanUse_eTraversal_Flying = true;
	CharTemplate.bCanUse_eTraversal_Land = true;
	CharTemplate.MaxFlightPitchDegrees = 0;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = true;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bAllowRushCam = false;
	CharTemplate.bWeakAgainstTechLikeRobot = true;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strScamperBT = "ScamperRoot_NoCover";

	CharTemplate.Abilities.AddItem('GatekeeperInitialState');  // Sets initial closed effect on Gatekeeper.
	CharTemplate.Abilities.AddItem('Retract');
	CharTemplate.Abilities.AddItem('AnimaInversion');
	CharTemplate.Abilities.AddItem('AnimaConsume');
	CharTemplate.Abilities.AddItem('AnimaGate');
	CharTemplate.Abilities.AddItem('DeathExplosion');
	CharTemplate.Abilities.AddItem('KillSiredZombies');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Shen_AlienSightings_Gatekeeper');

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_robot_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

simulated function string GetGateKeeperRevealMatineePrefix(XComGameState_Unit UnitState)
{
	if(UnitState.IsUnitAffectedByEffectName(class'X2Ability_Gatekeeper'.default.ClosedEffectName))
	{
		return "CIN_Gatekeeper_Closed";
	}
	else
	{
		return "CIN_Gatekeeper_Open";
	}
}

simulated function string GetAdventMatineePrefix(XComGameState_Unit UnitState)
{
	if(UnitState.kAppearance.iGender == eGender_Male)
	{
		return UnitState.GetMyTemplate().RevealMatineePrefix $ "_Male";
	}
	else
	{
		return UnitState.GetMyTemplate().RevealMatineePrefix $ "_Female";
	}
}

static function X2CharacterTemplate CreateTemplate_Muton()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Muton');
	CharTemplate.CharacterGroupName = 'Muton';
	CharTemplate.DefaultLoadout='Muton_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Muton.ARC_GameUnit_Muton");
	Loot.ForceLevel=0;
	Loot.LootTableName='Muton_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Muton_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Muton_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Muton");
	CharTemplate.strTargetingMatineePrefix = "CIN_Muton_FF_StartPos";

	CharTemplate.UnitSize = 1;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bAllowRushCam = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.Abilities.AddItem('CounterattackPreparation');
	CharTemplate.Abilities.AddItem('CounterattackDescription');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_Muton');

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Sectoid()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Sectoid');
	CharTemplate.CharacterGroupName = 'Sectoid';
	CharTemplate.DefaultLoadout='Sectoid_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Sectoid.ARC_GameUnit_Sectoid");
	Loot.ForceLevel=0;
	Loot.LootTableName='Sectoid_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Sectoid_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Sectoid_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Sectoid");

	CharTemplate.UnitSize = 1;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = true;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.Abilities.AddItem('VulnerabilityMelee');
	CharTemplate.Abilities.AddItem('Mindspin');
	//CharTemplate.Abilities.AddItem('DelayedPsiExplosion');
	CharTemplate.Abilities.AddItem('PsiReanimation');
	CharTemplate.Abilities.AddItem('KillSiredZombies');
	//CharTemplate.Abilities.AddItem('SectoidDeathOverride');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Tygan_AlienSightings_Sectoid');

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Sectopod()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Sectopod');
	CharTemplate.CharacterGroupName = 'Sectopod';
	CharTemplate.DefaultLoadout='Sectopod_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Sectopod.ARC_GameUnit_Sectopod");
	Loot.ForceLevel=0;
	Loot.LootTableName='Sectopod_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Sectopod_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Sectopod_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Sectopod");
	CharTemplate.strTargetingMatineePrefix = "CIN_Sectopod_FF_StartPos";

	CharTemplate.UnitSize = 2;
	CharTemplate.UnitHeight = 4;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = false;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;
	CharTemplate.bSkipDefaultAbilities = true;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = true;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bAllowRushCam = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strScamperBT = "ScamperRoot_NoCover";

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Shen_AlienSightings_Sectopod');

	CharTemplate.ImmuneTypes.AddItem('Fire');

	CharTemplate.Abilities.AddItem('StandardMove');
	CharTemplate.Abilities.AddItem('SectopodHigh');
	CharTemplate.Abilities.AddItem('SectopodLow');
	CharTemplate.Abilities.AddItem('SectopodLightningField');
	CharTemplate.Abilities.AddItem('DeathExplosion');
	CharTemplate.Abilities.AddItem('SectopodInitialState');
	CharTemplate.Abilities.AddItem('SectopodNewTeamState');

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_robot_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_PrototypeSectopod()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'PrototypeSectopod');
	CharTemplate.CharacterGroupName = 'Sectopod';
	CharTemplate.DefaultLoadout='PrototypeSectopod_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Sectopod.ARC_GameUnit_Sectopod");
	Loot.ForceLevel=0;
	Loot.LootTableName='Sectopod_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Sectopod_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Sectopod_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Sectopod");
	CharTemplate.strTargetingMatineePrefix = "CIN_Sectopod_FF_StartPos";

	CharTemplate.UnitSize = 3;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = false;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;
	CharTemplate.bSkipDefaultAbilities = true;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = true;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bAllowRushCam = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strScamperBT = "ScamperRoot_NoCover";

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Shen_AlienSightings_Sectopod');

	CharTemplate.ImmuneTypes.AddItem('Fire');

	CharTemplate.Abilities.AddItem('StandardMove');
	CharTemplate.Abilities.AddItem('SectopodHigh');
	CharTemplate.Abilities.AddItem('SectopodLow');
	CharTemplate.Abilities.AddItem('SectopodLightningField');
	CharTemplate.Abilities.AddItem('DeathExplosion');
	CharTemplate.Abilities.AddItem('SectopodInitialState');
	CharTemplate.Abilities.AddItem('SectopodNewTeamState');

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_robot_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_Viper()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Viper');
	CharTemplate.CharacterGroupName = 'Viper';
	CharTemplate.DefaultLoadout='Viper_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Viper.ARC_GameUnit_Viper");
	Loot.ForceLevel=0;
	Loot.LootTableName='Viper_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'Viper_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'Viper_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Viper");
	CharTemplate.strMatineePackages.AddItem("CIN_AdventMEC");
	CharTemplate.strTargetingMatineePrefix = "CIN_AdventMEC_FF_StartPos";

	CharTemplate.UnitSize = 1;
	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;

	CharTemplate.ImmuneTypes.AddItem('Poison');

	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.Abilities.AddItem('Bind');

	CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Tygan_AlienSightings_Viper');
	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_Viper');

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_PsiZombie(Name TemplateName = 'PsiZombie')
{
	local X2CharacterTemplate CharTemplate;
	//local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);
	CharTemplate.CharacterGroupName = 'PsiZombie';
	CharTemplate.DefaultLoadout='PsiZombie_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Zombie.ARC_GameUnit_Zombie");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Zombie.ARC_GameUnit_Zombie_F");
	//Loot.ForceLevel=0;
	//Loot.LootTableName='PsiZombie_BaseLoot';
	//CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	//Loot.ForceLevel = 0;
	//Loot.LootTableName = 'PsiZombie_TimedLoot';
	//CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	//Loot.LootTableName = 'PsiZombie_VultureLoot';
	//CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Zombie");

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bSkipDefaultAbilities = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsMeleeOnly = true;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;
	
	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.strScamperBT = "ScamperRoot_NoCover";

	CharTemplate.ImmuneTypes.AddItem('Mental');
	CharTemplate.ImmuneTypes.AddItem('Poison');
	CharTemplate.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType);

	CharTemplate.Abilities.AddItem('StandardMove');
	CharTemplate.Abilities.AddItem('ZombieInitialization');

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_PsiZombie');
	
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_PsiZombieHuman()
{
	local X2CharacterTemplate CharTemplate;
	CharTemplate = CreateTemplate_PsiZombie('PsiZombieHuman');
	CharTemplate.strPawnArchetypes.Length = 0;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Zombie.ARC_GameUnit_Zombie_Human_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_Zombie.ARC_GameUnit_Zombie_Human_F");

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_TheLost()
{
	local X2CharacterTemplate CharTemplate;
	CharTemplate = CreateTemplate_PsiZombie('TheLost');
	CharTemplate.strPawnArchetypes.Length = 0;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_TheLost.ARC_GameUnit_TheLost_Light_A");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_TheLost.ARC_GameUnit_TheLost_Light_B");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_TheLost.ARC_GameUnit_TheLost_Heavy_A");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_TheLost.ARC_GameUnit_TheLost_Heavy_B");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_TheLost.ARC_GameUnit_TheLost_Heavy_C");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_TheLost.ARC_GameUnit_TheLost_F");

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_ChryssalidCocoon(Name TemplateName = 'ChryssalidCocoon')
{
	local X2CharacterTemplate CharTemplate;
	//local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);
	CharTemplate.CharacterGroupName = 'Chryssalid';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_ChryssalidCocoon.ARC_GameUnit_ChryssalidCocoon_New");

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = false;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = false;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = false;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;
	CharTemplate.bAllowSpawnFromATT = false;
	CharTemplate.bSkipDefaultAbilities = true;

	CharTemplate.Abilities.AddItem('CocoonGestationTimeStage1');

	CharTemplate.ImmuneTypes.AddItem('Mental');
	
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Alien;

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_ChryssalidCocoonHuman()
{
	local X2CharacterTemplate CharTemplate;
	CharTemplate = CreateTemplate_ChryssalidCocoon('ChryssalidCocoonHuman');
	CharTemplate.strPawnArchetypes.Length = 0;
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_ChryssalidCocoon.ARC_GameUnit_ChryssalidCocoonHuman_New");

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_MimicBeacon()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'MimicBeacon');

	CharTemplate.strPawnArchetypes.AddItem("GameUnit_MimicBeacon.ARC_MimicBeacon_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_MimicBeacon.ARC_MimicBeacon_F");

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = false;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bSkipDefaultAbilities = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsMeleeOnly = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;
	
	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.bDisplayUIUnitFlag = false;
	CharTemplate.bNeverSelectable = true;

	CharTemplate.Abilities.AddItem('MimicBeaconInitialize');
	CharTemplate.Abilities.AddItem('GuaranteedToHit');

	return CharTemplate;
}

static function X2CharacterTemplate CreateTemplate_TestDummyPanic()
{
	local X2CharacterTemplate CharTemplate;
	local LootReference Loot;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'TestDummyPanic');
	CharTemplate.CharacterGroupName = 'AdventTrooper';
	CharTemplate.DefaultLoadout='AdvCaptainM1_Loadout';
	CharTemplate.BehaviorClass=class'XGAIBehavior';
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTrooper.ARC_GameUnit_AdvTrooperM1_M");

	// Auto-Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvTrooperM1_BaseLoot';
	CharTemplate.Loot.LootReferences.AddItem(Loot);

	// Timed Loot
	Loot.ForceLevel = 0;
	Loot.LootTableName = 'AdvTrooperM1_TimedLoot';
	CharTemplate.TimedLoot.LootReferences.AddItem(Loot);
	Loot.LootTableName = 'AdvTrooperM1_VultureLoot';
	CharTemplate.VultureLoot.LootReferences.AddItem(Loot);

	CharTemplate.strMatineePackages.AddItem("CIN_Advent");

	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;    
	CharTemplate.bCanTakeCover = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = true;
	
	CharTemplate.strBehaviorTree = "PanickedRoot";

	CharTemplate.SightedNarrativeMoments.AddItem(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.AlienSitings.T_Central_AlienSightings_AdvTrooperM1');

	//CharTemplate.AddTemplateAvailablility(CharTemplate.BITFIELD_GAMEAREA_Multiplayer); // Allow in MP!
	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;

	return CharTemplate;
}

static function X2CharacterTemplate CreateSpeakerTemplate(Name CharacterName, optional string CharacterSpeakerName = "", optional string CharacterSpeakerPortrait = "")
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, CharacterName);
	CharTemplate.CharacterGroupName = 'Speaker';
	if( CharTemplate.strCharacterName == "" )
	{
		CharTemplate.strCharacterName = CharacterSpeakerName;
	}
	CharTemplate.SpeakerPortrait = CharacterSpeakerPortrait;

	CharTemplate.bShouldCreateDifficultyVariants = false;

	return CharTemplate;
}