//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGTacticalGameCoreData extends Actor
	native(Core)
	dependson(XGGameData)
	abstract;

//-----------------------------------------------------------
// 08/09/2011 - MHU - Notes regarding enum changes as per Ryan
//   WARNING:
//     We are now heading into Alpha. With profile data (SP/MP team loadouts, mouse settings) now saved out
//     in a platform specific manner (1. PC (Steam) 2. Xbox (Live) 3. PS3 (NP)), it's critical that if the game
//     enums change in any way, please remember to bump the XComOnlineProfileSettings version number!
//
//-----------------------------------------------------------
// 06/09/2011 - MHU - Notes regarding enum changes as per Casey/JBos
//   WARNING:
//     Enum changes ideally should be done at the end of the list due
//     to the serialization that's done when saving objects.
//     Changes to the middle of an enum will result in an incorrect
//     (outdated) enum selection for players with older savedata.
//     This is especially true for PIE users (Level Designers) where
//     savedata isn't resaved like it does in the regular game.
//   SOLUTION: 
//     If readability takes priority when altering enums, please request
//     LDs and other users to delete their old savedata.
//
//-----------------------------------------------------------

enum EItemCard
{
	eItemCard_NONE,
	eItemCard_Armor,
	eItemCard_SoldierWeapon,
	eItemCard_ShipWeapon,
	eItemCard_EquippableItem,
	eItemCard_SHIV,
	eItemCard_Interceptor,
	eItemCard_InterceptorConsumable,
	eItemCard_Satellite,
	eItemCard_MPCharacter,
	EItemCard_MAX,
};

struct TItemCard
{
	// name of associated object highlighted
	var string m_strName;

	// flavor text of associated object highlighted
	var string m_strFlavorText;


	//ship weapon related values
	var int m_shipWpnRange; 
	var int m_shipWpnArmorPen;
	var int m_shipWpnHitChance;
	var int m_shipWpnFireRate;

	//SHIV values
	var string m_strShivWeapon;

	// MP Character Specific Data
	var name m_CharacterTemplateName;
	var int m_iHealth;
	var int m_iWill;
	var int m_iAim;
	var int m_iDefense;

	// armor hp
	var int m_iArmorHPBonus;

	// "hand" / soldier weapons
	var int m_iBaseCritChance;
	var int m_iBaseDamage;
	var int m_iBaseDamageMax;
	var int m_iCritDamage;
	var int m_iCritDamageMax;
	var float m_fireRate;

	// the type of item card
	var EItemCard m_type;

	// the associated EItemType index
	var EItemType m_item;

	// consumable item charges (medikit, grenades, etc)
	var int m_iCharges;

	// associated perks this object has
	var array<int> m_perkTypes;

	structdefaultproperties
	{
		m_type = eItemCard_NONE
		m_strName = "UNDEFINED"
	}
	
};

enum EMPTemplate
{
	eMPT_None,
	eMPT_AssaultCaptainOffense,
	eMPT_SniperCaptainAim,
	eMPT_SniperCaptainMobile,
	eMPT_HeavyCaptainBullets,
	eMPT_HeavyCaptainExplosive,
	eMPT_SupportCaptainSuppression,
	eMPT_SupportCaptainHealing,
	eMPT_SupportSquaddie,
	eMPT_AssaultSquaddie,
	eMPT_HeavySquaddie,
	eMPT_SniperSquaddie,
	eMPT_SupportColonel,
	eMPT_AssaultColonel,
	eMPT_HeavyColonel,
	eMPT_SniperColonel,
	eMPT_PsiSniperMajor,
	eMPT_PsiSupportMajor,
	eMPT_PsiAssaultMajor,
	eMPT_MECTemplate1,
	eMPT_MECTemplate2,
	eMPT_MECTemplate3,
	eMPT_MECTemplate4,
	eMPT_MECTemplate5,
	eMPT_MECTemplate6,
	eMPT_MECTemplate7,
	eMPT_MECTemplate8,
	EMPTemplate_MAX,
};

enum EMPGeneModTemplateType
{
	EMPGMTT_None,
	EMPGMTT_GeneModTemplate1,
	EMPGMTT_GeneModTemplate2,
	EMPGMTT_GeneModTemplate3,
	EMPGMTT_GeneModTemplate4,
	EMPGMTT_GeneModTemplate5,
	EMPGMTT_GeneModTemplate6,
	EMPGMTT_MAX,
};

enum EMPMECSuitTemplateType
{
	eMPMECSTT_None,
	eMPMECSTT_MECSuitTemplate1,
	eMPMECSTT_MECSuitTemplate2,
	eMPMECSTT_MECSuitTemplate3,
	eMPMECSTT_MECSuitTemplate4,
	eMPMECSTT_MECSuitTemplate5,
	eMPMECSTT_MECSuitTemplate6,
	eMPMECSTT_MECSuitTemplate7,
	eMPMECSTT_MECSuitTemplate8,
	eMPMECSTT_MAX,
};

/////////////////////////////////////////
// MHU - GameCore specific Enums
/////////////////////////////////////////

enum EVolumeType
{
	eVolume_Suppression,
	eVolume_Smoke,
	eVolume_CombatDrugs,
	eVolume_Fire,
	eVolume_Proximity,
	eVolume_Spy,
	eVolume_FlashBang_DEPRECATED,
	eVolume_Poison,
	eVolume_Telekinetic,
	eVolume_Rift,
};

// The specific effect that this volume has on anyone who enters it
enum EVolumeEffect
{
	eVolumeEffect_None,
	eVolumeEffect_BlocksSight,
	eVolumeEffect_Suppression,
	eVolumeEffect_Burn,
	eVolumeEffect_AddSight,
	eVolumeEffect_ApplyAbility,
	eVolumeEffect_Poison,
	eVolumeEffect_TelekineticField,
	eVolumeEffect_Rift,
};

enum EXComPawnUpdateBuildingVisibilityType
{
	EPUBVT_None,
	EPUBVT_Unit,
	EPUBVT_Cursor,
	EPUBVT_LevelTrace,
	EPUBVT_POI
};

enum EUnitPawn_OpenCloseState
{
	eUP_None,
	eUP_Open,
	eUP_Close
};

defaultproperties
{

}	
