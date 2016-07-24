//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMPData.uc
//  AUTHOR:  Todd Smith  --  3/15/2011
//  PURPOSE: Class for common MP game data.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComMPData extends Object 
	dependson(XGTacticalGameCoreNativeBase)
	dependson(XGBattleDesc)
	dependson(X2MPData_Common)
	config(MPGame)
	native(MP);

const MAX_PERKS_PER_TEMPLATE = 10;
const MAX_GENE_MODS_PER_TEMPLATE = 5;
const MAX_MEC_SUIT_ITEMS_PER_TEMPLATE = 5;

struct native TMPClassLoadoutData
{
	var int             m_eClassType;
	var string          m_strClassName;
	var int             m_iClassCost;
};
var config array<TMPClassLoadoutData>    m_arrClassLoadouts;

struct native TMPClassPerkTemplate
{
	var EMPTemplate     m_eTemplate;
	var int             m_eClassType;
	var string          m_strClassName;                     // NOTE: localized when these structs are filled out -tsmith 
	var int             m_iTemplateCost;
	var string          m_iPerks[MAX_PERKS_PER_TEMPLATE];
	var int             m_eRank;
};
var config array<TMPClassPerkTemplate>    m_arrPerkTemplate;

struct native TMPGeneModTemplate
{
	var EMPGeneModTemplateType  m_eGeneModTemplateType;
	var string                  m_strGeneModTemplateName;   // NOTE: localized when these structs are filled out -tsmith 
	var int                     m_iGeneModTemplateCost;
	var string                  m_iGeneMods[MAX_GENE_MODS_PER_TEMPLATE];
};
var config array<TMPGeneModTemplate>    m_arrGeneModTemplates;

struct native TMPMECSuitTemplate
{
	var EMPMECSuitTemplateType      m_eMECSuitTemplateType;
	var string                      m_strMECSuitTemplateName;   // NOTE: localized when these structs are filled out -tsmith 
	var int                         m_iMECSuitTemplateCost;
	var EItemType                   m_eMECSuitArmorType;
	var EItemType                   m_eMECSuitItemTypes[MAX_MEC_SUIT_ITEMS_PER_TEMPLATE];
};
var config array<TMPMECSuitTemplate>    m_arrMECSuitTemplates;

struct native TMPArmorLoadoutData
{
	var EItemType   m_eArmorType;
	var string      m_strArmorName;     // NOTE: localized when these structs are filled out -tsmith 
	var int         m_iArmorCost;
};
var config array<TMPArmorLoadoutData>     m_arrArmorLoadouts;

struct native TMPPistolLoadoutData
{
	var EItemType   m_ePistolType;
	var string      m_strPistolName;
	var int         m_iPistolCost;
};
var config array<TMPPistolLoadoutData>    m_arrPistolLoadouts;

struct native TMPWeaponLoadoutData
{
	var EItemType   m_eWeaponType;
	var string      m_strWeaponName;    // NOTE: localized when these structs are filled out -tsmith        
	var int         m_iWeaponCost;
};
var config array<TMPWeaponLoadoutData>    m_arrWeaponLoadouts;

struct native TMPItemLoadoutData
{
	var EItemType   m_eItemType;
	var string      m_strItemName;      // NOTE: localized when the array of structs below are initalized -tsmith
	var int         m_iItemCost;
};
var config array<TMPItemLoadoutData>      m_arrItemLoadouts;

struct native TMPCharacterLoadoutData
{
	var name        m_TemplateName;
	var string      m_strCharacterName;
	var int         m_iCharacterCost;
};
var config array<TMPCharacterLoadoutData> m_arrCharacterLoadouts;

struct native TMPMapData
{
	var name                                    m_nmMapName;
	var string                                  m_strMapDisplayName;
	var int                                     m_iMapNameIndex;
	var EMPGameType                             m_eGameType;
	var bool                                    m_bDebugOnly;
};
var config array<TMPMapData>              m_arrMaps;

struct native TMPPatientZeroData
{
	var string	    m_strPatientName;
	var int	        m_iPlatform;
};
var array<TMPPatientZeroData>      m_arrPatientZero;

struct native TMPUnitLoadoutReplicationInfo
{
	var string                                  m_strUnitName;
	var name                                    m_CharacterTemplateName;
	var EGender                                 m_eCharacterGender;
	var int                                     m_eSoldierClass;
	var EMPTemplate                             m_eTemplate;
	var EMPGeneModTemplateType                  m_eGeneModTemplateType;
	var EMPMECSuitTemplateType                  m_eMECSuitTemplateType;
	var int                                     m_eRank;
	var EItemType                               m_eArmorType;
	var EItemType                               m_ePistolType;
	var EItemType                               m_eWeaponType;
	var EItemType                               m_ePrimaryItemType;
	var EItemType                               m_eSecondaryItemType;
	var int                                     m_iTotalUnitCost;
	var int                                     m_iUnitLoadoutID;   // used to map the loadout to the unit spawned by this loadout -tsmith

	//bsg lmordarski (5/16/2012) if we customized this characters name
	var bool                                    m_bCustomizedName;
	//bsg lmordarski (5/16/2012) end

	structdefaultproperties
	{
		m_strUnitName = "";
		m_CharacterTemplateName=None;
		m_eCharacterGender=eGender_None;
		m_eSoldierClass = 0;
		m_eTemplate = eMPT_None;
		m_eGeneModTemplateType = EMPGMTT_None;
		m_eMECSuitTemplateType = eMPMECSTT_None;
		m_eRank = 0; 
		m_eArmorType=eItem_NONE;
		m_ePistolType=eItem_NONE;
		m_eWeaponType=eItem_NONE;
		m_ePrimaryItemType=eItem_NONE;
		m_eSecondaryItemType=eItem_NONE;
		m_iTotalUnitCost=0;
		m_iUnitLoadoutID=INDEX_NONE;
	}
};

struct native TMPPingRanges
{
	var string  m_strUITag;
	var int     m_iPing;
};

struct native TMPPlayerData
{
	var string m_strPlayerLanguage;
	var bool   m_bSoldiersUseOwnLanguage;
};

var config array<int>                           m_arrMaxSquadCosts;
var config array<int>                           m_arrTurnTimers;
var config array<TMPPingRanges>                 m_arrPingRanges;

var private localized string                    m_arrNetworkTypeNamesXbox[EMPNetworkType.EnumCount];
var private localized array<string>             m_arrLocalizedMapDisplayNames;

var privatewrite    bool                        m_bInitialized;

/** 
 *  the version of the INI that is being used. when read from the MCP it is updated in memory (no disk write). 
 *  this is then used to check in online game searches to prevent the rare case where one players MCP read fails.
 */
var config const    int                         m_iINIVersion;
var        const string                         m_strINIFilename;

var config const bool                           m_bAllowGlamCams;

static final function bool IsPatientZero(string kName, int kPlatform)
{
	local TMPPatientZeroData PatientZero;

	foreach class'XComMPData'.default.m_arrPatientZero(PatientZero)
	{
		if (PatientZero.m_strPatientName == kName && PatientZero.m_iPlatform == kPlatform)
		{
			return true;
		}
	}

	return false;
}

static final function string GetNetworkTypeName(EMPNetworkType NetworkType)
{
	if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		return default.m_arrNetworkTypeNamesXbox[NetworkType];
	}
	else
	{
		return class'X2MPData_Shell'.default.m_arrNetworkTypeNames[NetworkType];
	}
}

///////////////////////////////////////////
// ToString functions
///////////////////////////////////////////

static final function string TMPUnitLoadoutReplicationInfo_ToString(const out TMPUnitLoadoutReplicationInfo kInfo, optional string strDelimiter=", ")
{
	local string strRep;

	strRep =  "Name=" $ kInfo.m_strUnitName;
	strRep $= strDelimiter $ "CharacterType=" $ kInfo.m_CharacterTemplateName;
	strRep $= strDelimiter $ "CharacterGender=" $ kInfo.m_eCharacterGender;
	strRep $= strDelimiter $ "TemplateType=" $ kInfo.m_eTemplate;
	strRep $= strDelimiter $ "GeneModTemplateType=" $ kInfo.m_eGeneModTemplateType;
	strRep $= strDelimiter $ "MECSuitTemplateType=" $ kInfo.m_eMECSuitTemplateType;
	strRep $= strDelimiter $ "SoldierClassType=" $ kInfo.m_eSoldierClass;
	strRep $= strDelimiter $ "Rank=" $ kInfo.m_eRank;
	strRep $= strDelimiter $ "PistolType=" $ kInfo.m_ePistolType;
	strRep $= strDelimiter $ "WeaponType=" $ kInfo.m_eWeaponType;
	strRep $= strDelimiter $ "ArmorType=" $ kInfo.m_eArmorType;
	strRep $= strDelimiter $ "PrimaryItemType=" $ kInfo.m_ePrimaryItemType;
	strRep $= strDelimiter $ "SecondaryItemType=" $ kInfo.m_eSecondaryItemType;
	strRep $= strDelimiter $ "Cost=" $ kInfo.m_iTotalUnitCost;
	strRep $= strDelimiter $ "LoadoutID=" $ kInfo.m_iUnitLoadoutID;

	return strRep;
}


static final function string TMPClassPerkTemplate_ToString(TMPClassPerkTemplate kTemplate)
{
	local string strRep;
	local int i;

	strRep = "Type=" $ kTemplate.m_eTemplate;
	strRep $= ", SoldierClass=" $ kTemplate.m_eClassType;
	strRep $= ", SoldierClassName=" $ kTemplate.m_strClassName;
	strRep $= ", Rank=" $ kTemplate.m_eRank;
	for(i = 0; i < MAX_PERKS_PER_TEMPLATE; i++)
	{
		strRep $= ", Perk[" $ i $ "]=" $ kTemplate.m_iPerks[i];
	}
	strRep $= ", Cost=" $ kTemplate.m_iTemplateCost;

	return strRep;
}

static final function string TMPGeneModTemplate_ToString(TMPGeneModTemplate kTemplate)
{
	local string strRep;
	local int i;

	strRep = "Type=" $ kTemplate.m_eGeneModTemplateType;
	strRep $= ", Name=" $ kTemplate.m_strGeneModTemplateName;
	strRep $= ", Cost=" $ kTemplate.m_iGeneModTemplateCost;
	for(i = 0; i < MAX_GENE_MODS_PER_TEMPLATE; i++)
	{
		strRep $= ", GeneMod[" $ i $ "]=" $ kTemplate.m_iGeneMods[i];
	}

	return strRep;
}

static final function string TMPMECSuitTemplate_ToString(TMPMECSuitTemplate kTemplate)
{
	local string strRep;
	local int i;

	strRep = "Type=" $ kTemplate.m_eMECSuitTemplateType;
	strRep $= ", Name=" $ kTemplate.m_strMECSuitTemplateName;
	strRep $= ", Cost=" $ kTemplate.m_iMECSuitTemplateCost;
	for(i = 0; i < MAX_MEC_SUIT_ITEMS_PER_TEMPLATE; i++)
	{
		strRep $= ", MECSuitItem[" $ i $ "]=" $ kTemplate.m_eMECSuitItemTypes[i];
	}

	return strRep;
}

///////////////////////////////////////////

final event Init()
{
	local int i;
	//local TCharacter kCharacter;
	//local OnlineSubsystem OnlineSub;


	m_bInitialized=false;

	if(`GAMECORE != none && `GAMECORE.m_bInitialized)
	{
		// jboswell: This should not be necessary anymore, but I've left it here just in case for debugging.
		// Just uncomment this block and OnReadTitleFileComplete to test.
		//OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
		//if (OnlineSub != none && OnlineSub.Patcher != none)
		//{
		//	OnlineSub.Patcher.AddReadFileDelegate(OnReadTitleFileComplete);
		//	OnlineSub.Patcher.AddFileToDownload(m_strINIFilename);
		//}
		//return;

		/*  jbouscher - this is old soldier class stuff, commenting out for now
		for(i = 0; i < m_arrClassLoadouts.Length; i++)
		{
			m_arrClassLoadouts[i].m_strClassName = `GAMECORE.GetSoldierClassName(m_arrClassLoadouts[i].m_eClassType);
			default.m_arrClassLoadouts[i].m_strClassName = m_arrClassLoadouts[i].m_strClassName;
		}
		*/
		for (i = 0; i < m_arrPerkTemplate.Length; i++)
		{
			m_arrPerkTemplate[i].m_strClassName = `GAMECORE.GetMPTemplateName(i);
			default.m_arrPerkTemplate[i].m_strClassName = m_arrPerkTemplate[i].m_strClassName;
		}
		for (i = 0; i < m_arrGeneModTemplates.Length; i++)
		{
			m_arrGeneModTemplates[i].m_strGeneModTemplateName = `GAMECORE.GetMPGeneModTemplateName(i);
			default.m_arrGeneModTemplates[i].m_strGeneModTemplateName = m_arrGeneModTemplates[i].m_strGeneModTemplateName;
		}
		for (i = 0; i < m_arrMECSuitTemplates.Length; i++)
		{
			m_arrMECSuitTemplates[i].m_strMECSuitTemplateName = `GAMECORE.GetMPMECSuitTemplateName(i);
			default.m_arrMECSuitTemplates[i].m_strMECSuitTemplateName = m_arrMECSuitTemplates[i].m_strMECSuitTemplateName;
		}
		for(i = 0; i < m_arrArmorLoadouts.Length; i++)
		{
			m_arrArmorLoadouts[i].m_strArmorName = `GAMECORE.GetLocalizedItemName(m_arrArmorLoadouts[i].m_eArmorType);
			default.m_arrArmorLoadouts[i].m_strArmorName = m_arrArmorLoadouts[i].m_strArmorName;
		}
		for(i = 0; i < m_arrPistolLoadouts.Length; i++)
		{
			m_arrPistolLoadouts[i].m_strPistolName = `GAMECORE.GetLocalizedItemName(m_arrPistolLoadouts[i].m_ePistolType);
			default.m_arrPistolLoadouts[i].m_strPistolName = m_arrPistolLoadouts[i].m_strPistolName;
		}
		for(i = 0; i < m_arrWeaponLoadouts.Length; i++)
		{
			m_arrWeaponLoadouts[i].m_strWeaponName = `GAMECORE.GetLocalizedItemName(m_arrWeaponLoadouts[i].m_eWeaponType);
			default.m_arrWeaponLoadouts[i].m_strWeaponName = m_arrWeaponLoadouts[i].m_strWeaponName;
		}
		for(i = 0; i < m_arrItemLoadouts.Length; i++)
		{		
			m_arrItemLoadouts[i].m_strItemName = `GAMECORE.GetLocalizedItemName(m_arrItemLoadouts[i].m_eItemType);
			default.m_arrItemLoadouts[i].m_strItemName = m_arrItemLoadouts[i].m_strItemName;
		}
		//for(i = 0; i < m_arrCharacterLoadouts.Length; i++)
		//{
		//	kCharacter = `GAMECORE.GetTCharacter(m_arrCharacterLoadouts[i].m_TemplateName);
		//	m_arrCharacterLoadouts[i].m_strCharacterName = kCharacter.strName;
		//	default.m_arrCharacterLoadouts[i].m_strCharacterName = m_arrCharacterLoadouts[i].m_strCharacterName;
		//}
		for(i = 0; i < m_arrLocalizedMapDisplayNames.Length; i++)
		{
			m_arrMaps[i].m_strMapDisplayName = m_arrLocalizedMapDisplayNames[i];
			default.m_arrMaps[i].m_strMapDisplayName = m_arrMaps[i].m_strMapDisplayName;
		}
		`if(`isdefined(FINAL_RELEASE))
			RemoveDebugMaps();
		`endif
		for(i = 0; i < m_arrMaps.Length; i++)
		{
			m_arrMaps[i].m_iMapNameIndex = i;
			default.m_arrMaps[i].m_iMapNameIndex = m_arrMaps[i].m_iMapNameIndex;
		}
		
		m_bInitialized = true;

`if(`notdefined(FINAL_RELEASE))
		if(class'Engine'.static.GetCurrentWorldInfo().NetMode != NM_Standalone)
		{
			DebugPrintData();
		}
`endif
	}
	else
	{
		class'WorldInfo'.static.GetWorldInfo().SetTimer(0.1, true, nameof(WaitForGameCoreInit), self);
	}
}

// Called from INILocPatcher when it's done downloading a file
//function OnReadTitleFileComplete(bool bWasSuccessful,string FileName)
//{
//	local OnlineSubsystem OnlineSub;

//	if (FileName == m_strINIFilename)
//	{
//		`log(self $ "::" $ GetFuncName() @ `ShowVar(bWasSuccessful) @ `ShowVar(FileName), true, 'XCom_Net');
//		OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
//		if (OnlineSub != none && OnlineSub.Patcher != none)
//		{
//			OnlineSub.Patcher.ClearReadFileDelegate(OnReadTitleFileComplete);
//		}

//		if (!bWasSuccessful)
//		{
//			Init();
//		}
//	}
//}

function WaitForGameCoreInit()
{
	if(`GAMECORE != none && `GAMECORE.m_bInitialized)
	{
		Init();
		class'WorldInfo'.static.GetWorldInfo().ClearTimer(nameof(WaitForGameCoreInit), self);
	}
}

private function RemoveDebugMaps()
{
	local array<TMPMapData> arrDebugMapsToRemove;
	local int i;

	for(i = 0; i < m_arrMaps.Length; i++)
	{
		if(m_arrMaps[i].m_bDebugOnly)
		{
			arrDebugMapsToRemove.AddItem(m_arrMaps[i]);
		}
	}

	for(i = 0; i < arrDebugMapsToRemove.Length; i++)
	{
		default.m_arrMaps.RemoveItem(arrDebugMapsToRemove[i]);
		m_arrMaps.RemoveItem(arrDebugMapsToRemove[i]);
	}
}

final function string MapPistolTypeToName(EItemType _ePistolType)
{
	local int i;

	for(i = 0; i < m_arrPistolLoadouts.Length; i++)
	{
		if(m_arrPistolLoadouts[i].m_ePistolType == _ePistolType)
		{
			return m_arrPistolLoadouts[i].m_strPistolName;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Pistol type '" $ _ePistolType $ "' not in map");
	return "INVALID TYPE";
}

final function string MapMPTemplateTypeToName(EMPTemplate eTemplate)
{
	local int i;

	for(i = 0; i < m_arrPerkTemplate.Length; i++)
	{
		if(m_arrPerkTemplate[i].m_eTemplate == eTemplate)
		{
			return m_arrPerkTemplate[i].m_strClassName;
		}
	}

	return "INVALID TYPE";
}

//  @TODO - MP: stop using this or rework it for new system
final function int MapMPTemplateTypeToRank(EMPTemplate eTemplate)
{
	return 0;
}

final function string MapWeaponTypeToName(EItemType _eWeaponType)
{
	local int i;

	for(i = 0; i < m_arrWeaponLoadouts.Length; i++)
	{
		if(m_arrWeaponLoadouts[i].m_eWeaponType == _eWeaponType)
		{
			return m_arrWeaponLoadouts[i].m_strWeaponName;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Weapon type '" $ _eWeaponType $ "' not in map");
	return "INVALID TYPE";
}

final function string MapClassTypeToName(int _eClassType)
{
	local int i;

	for(i = 0; i < m_arrClassLoadouts.Length; i++)
	{
		if(m_arrClassLoadouts[i].m_eClassType == _eClassType)
		{
			return m_arrClassLoadouts[i].m_strClassName;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Armor type '" $ _eArmorType $ "' not in map");
	return "INVALID TYPE";
}

final function string MapArmorTypeToName(EItemType _eArmorType)
{
	local int i;

	for(i = 0; i < m_arrArmorLoadouts.Length; i++)
	{
		if(m_arrArmorLoadouts[i].m_eArmorType == _eArmorType)
		{
			return m_arrArmorLoadouts[i].m_strArmorName;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Armor type '" $ _eArmorType $ "' not in map");
	return "INVALID TYPE";
}
	
final function string MapItemTypeToName(EItemType _eItemType)
{
	local int i;

	for(i = 0; i < m_arrItemLoadouts.Length; i++)
	{
		if(m_arrItemLoadouts[i].m_eItemType == _eItemType)
		{
			return m_arrItemLoadouts[i].m_strItemName;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Item type '" $ _eItemType $ "' not in map");
	return "INVALID TYPE";
}

final function string MapCharacterTypeToName(name _CharacterTemplateName)
{
	local int i;

	for(i = 0; i < m_arrCharacterLoadouts.Length; i++)
	{
		if(m_arrCharacterLoadouts[i].m_TemplateName == _CharacterTemplateName)
		{
			return m_arrCharacterLoadouts[i].m_strCharacterName;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Character type '" $ _CharacterTemplateName $ "' not in map");
	return "INVALID TYPE";
}

final function int MapPistolTypeToCost(EItemType _ePistolType)
{
	local int i;

	for(i = 0; i < m_arrPistolLoadouts.Length; i++)
	{
		if(m_arrPistolLoadouts[i].m_ePistolType == _ePistolType)
		{
			return m_arrPistolLoadouts[i].m_iPistolCost;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Pistol type '" $ _ePistolType $ "' not in map");
	return 0;
}

final function int MapWeaponTypeToCost(EItemType _eWeaponType)
{
	local int i;

	for(i = 0; i < m_arrWeaponLoadouts.Length; i++)
	{
		if(m_arrWeaponLoadouts[i].m_eWeaponType == _eWeaponType)
		{
			return m_arrWeaponLoadouts[i].m_iWeaponCost;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Weapon type '" $ _eWeaponType $ "' not in map");
	return 0;
}

final function int MapClassTypeToCost(int _eClassType)
{
	local int i;

	for(i = 0; i < m_arrClassLoadouts.Length; i++)
	{
		if(m_arrClassLoadouts[i].m_eClassType == _eClassType)
		{
			return m_arrClassLoadouts[i].m_iClassCost;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Armor type '" $ _eArmorType $ "' not in map");
	return 0;
}

final function int MapArmorTypeToCost(EItemType _eArmorType)
{
	local int i;

	for(i = 0; i < m_arrArmorLoadouts.Length; i++)
	{
		if(m_arrArmorLoadouts[i].m_eArmorType == _eArmorType)
		{
			return m_arrArmorLoadouts[i].m_iArmorCost;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Armor type '" $ _eArmorType $ "' not in map");
	return 0;
}

final function int MapItemTypeToCost(EItemType _eItemType)
{
	local int i;

	for(i = 0; i < m_arrItemLoadouts.Length; i++)
	{
		if(m_arrItemLoadouts[i].m_eItemType == _eItemType)
		{
			return m_arrItemLoadouts[i].m_iItemCost;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Item type '" $ _eItemType $ "' not in map");
	return 0;
}

final function int MapCharacterTypeToCost(name _CharacterTemplateName)
{
	local int i;

	for(i = 0; i < m_arrCharacterLoadouts.Length; i++)
	{
		if(m_arrCharacterLoadouts[i].m_TemplateName == _CharacterTemplateName)
		{
			return m_arrCharacterLoadouts[i].m_iCharacterCost;
		}
	}

	//`warn(self $ "::" $ GetFuncName() @ "Character type '" $ _CharacterTemplateName $ "' not in map");
	return 0;
}

final function int MapTemplateToCost(int _eTemplate)
{
	local int i;

	for(i = 0; i < m_arrPerkTemplate.Length; i++)
	{
		if(m_arrPerkTemplate[i].m_eTemplate == _eTemplate)
		{
			return m_arrPerkTemplate[i].m_iTemplateCost;
		}
	}

	//`warn(`location @ "Template type '" $ _eTemplate $ "' not in map");
	return 0;
}

final function int MapGeneModTemplateToCost(EMPGeneModTemplateType eGeneModTemplateType)
{
	local int i;

	for(i = 0; i < m_arrGeneModTemplates.Length; i++)
	{
		if(m_arrGeneModTemplates[i].m_eGeneModTemplateType == eGeneModTemplateType)
		{
			return m_arrGeneModTemplates[i].m_iGeneModTemplateCost;
		}
	}

	//`warn(`location @ "Template type '" $ _eTemplate $ "' not in map");
	return 0;
}

final function string MapGeneModTemplateToName(EMPGeneModTemplateType eGeneModTemplateType)
{
	local int i;

	for(i = 0; i < m_arrGeneModTemplates.Length; i++)
	{
		if(m_arrGeneModTemplates[i].m_eGeneModTemplateType == eGeneModTemplateType)
		{
			return m_arrGeneModTemplates[i].m_strGeneModTemplateName;
		}
	}

	//`warn(`location @ "Template type '" $ _eTemplate $ "' not in map");
	return "INVAILD TYPE";
}

final function int MapMECSuitTemplateToCost(EMPMECSuitTemplateType eMECSuitTemplateType)
{
	local int i;

	for(i = 0; i < m_arrMECSuitTemplates.Length; i++)
	{
		if(m_arrMECSuitTemplates[i].m_eMECSuitTemplateType == eMECSuitTemplateType)
		{
			return m_arrMECSuitTemplates[i].m_iMECSuitTemplateCost;
		}
	}

	//`warn(`location @ "Template type '" $ _eTemplate $ "' not in map");
	return 0;
}

final function string MapMECSuitTemplateToName(EMPMECSuitTemplateType eMECSuitTemplateType)
{
	local int i;

	for(i = 0; i < m_arrMECSuitTemplates.Length; i++)
	{
		if(m_arrMECSuitTemplates[i].m_eMECSuitTemplateType == eMECSuitTemplateType)
		{
			return m_arrMECSuitTemplates[i].m_strMECSuitTemplateName;
		}
	}

	//`warn(`location @ "Template type '" $ _eTemplate $ "' not in map");
	return "INVAILD TYPE";
}

final function EItemType MapMECSuitTemplateToArmorType(EMPMECSuitTemplateType eMECSuitTemplateType)
{
	local int i;

	for(i = 0; i < m_arrMECSuitTemplates.Length; i++)
	{
		if(m_arrMECSuitTemplates[i].m_eMECSuitTemplateType == eMECSuitTemplateType)
		{
			return m_arrMECSuitTemplates[i].m_eMECSuitArmorType;
		}
	}

	//`warn(`location @ "Template type '" $ _eTemplate $ "' not in map");
	return 0;
}

final function int SumUnitCost( name _CharacterTemplateName, EItemType _ePistolType, EItemType _eWeaponType, EItemType _eArmorType, EItemType _ePrimaryItemType, EItemType _eSecondaryItemType, int _eTemplate, EMPGeneModTemplateType _eGeneModTemplate, EMPMECSuitTemplateType _eMECSuitTemplate)
{
	return  MapCharacterTypeToCost(_CharacterTemplateName) +
			MapPistolTypeToCost(_ePistolType) +
			MapWeaponTypeToCost(_eWeaponType) +
			MapArmorTypeToCost(_eArmorType) +
			MapItemTypeToCost(_ePrimaryItemType) + 
			MapItemTypeToCost(_eSecondaryItemType) + 
			MapTemplateToCost(_eTemplate) + 
			MapGeneModTemplateToCost(_eGeneModTemplate) + 
			MapMECSuitTemplateToCost(_eMECSuitTemplate);
}

final function bool IsValidUnitLoadout(const out TMPUnitLoadoutReplicationInfo kUnitLoadout)
{
	local bool bIsValidUnitLoadout;
	
	bIsValidUnitLoadout = false;
	if(kUnitLoadout.m_CharacterTemplateName == 'Soldier')
	{
		switch(kUnitLoadout.m_eSoldierClass)
		{
		default:
			// soldiers must have a pistol, weapon, and armor -tsmith 
			if(kUnitLoadout.m_ePistolType == eItem_NONE || kUnitLoadout.m_eWeaponType == eItem_NONE || kUnitLoadout.m_eArmorType == eItem_NONE)
			{
				bIsValidUnitLoadout = false;
			}
			else
			{
				bIsValidUnitLoadout = true;
			}
			break;
		}
	}
	else
	{
		// aliens can't specifiy pistol, weapon, armor, item -tsmith 
		if(kUnitLoadout.m_eWeaponType != eItem_NONE && kUnitLoadout.m_eArmorType != eItem_NONE && kUnitLoadout.m_ePrimaryItemType != eItem_NONE)
		{
			bIsValidUnitLoadout = false;
		}
		else
		{
			bIsValidUnitLoadout = true;
		}
	}

	`log(self $ "::" $ GetFuncName() @ "bIsValidUnitLoadout=" $ bIsValidUnitLoadout @ "Loadout=" $ TMPUnitLoadoutReplicationInfo_ToString(kUnitLoadout), true, 'XCom_Net');

	return bIsValidUnitLoadout;
}

final function DebugPrintData()
{
	local int i;

	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: INI Version: " $ m_iINIVersion, true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');

	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: Class Loadout Data", true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');
	for(i = 0; i < m_arrClassLoadouts.Length; i++)
	{
		`log("      Type=" $ m_arrClassLoadouts[i].m_eClassType $ ", Name=" $ m_arrClassLoadouts[i].m_strClassName $ ", Cost=" $ m_arrClassLoadouts[i].m_iClassCost, true, 'XCom_Net');
	}
	`log("*********************************", true, 'XCom_Net');
	`log("XComMPData: Template Loadout Data", true, 'XCom_Net');
	`log("*********************************", true, 'XCom_Net');
	for(i = 0; i < m_arrPerkTemplate.Length; i++)
	{
		`log("      Template=" $ TMPClassPerkTemplate_ToString(m_arrPerkTemplate[i]), true, 'XCom_Net');
	}
	`log("******************************************", true, 'XCom_Net');
	`log("XComMPData: Gene Mod Template Loadout Data", true, 'XCom_Net');
	`log("******************************************", true, 'XCom_Net');
	for(i = 0; i < m_arrGeneModTemplates.Length; i++)
	{
		`log("      GeneModTemplate=" $ TMPGeneModTemplate_ToString(m_arrGeneModTemplates[i]), true, 'XCom_Net');
	}
	`log("******************************************", true, 'XCom_Net');
	`log("XComMPData: MEC Suit Template Loadout Data", true, 'XCom_Net');
	`log("******************************************", true, 'XCom_Net');
	for(i = 0; i < m_arrMECSuitTemplates.Length; i++)
	{
		`log("      MECSuitTemplate=" $ TMPMECSuitTemplate_ToString(m_arrMECSuitTemplates[i]), true, 'XCom_Net');
	}
	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: Pistol Loadout Data", true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');
	for(i = 0; i < m_arrPistolLoadouts.Length; i++)
	{
		`log("      Type=" $ m_arrPistolLoadouts[i].m_ePistolType $ ", Name=" $ m_arrPistolLoadouts[i].m_strPistolName $ ", Cost=" $ m_arrPistolLoadouts[i].m_iPistolCost, true, 'XCom_Net');
	}
	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: Weapon Loadout Data", true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');
	for(i = 0; i < m_arrWeaponLoadouts.Length; i++)
	{
		`log("      Type=" $ m_arrWeaponLoadouts[i].m_eWeaponType $ ", Name=" $ m_arrWeaponLoadouts[i].m_strWeaponName $ ", Cost=" $ m_arrWeaponLoadouts[i].m_iWeaponCost, true, 'XCom_Net');
	}
	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: Armor Loadout Data", true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');
	for(i = 0; i < m_arrArmorLoadouts.Length; i++)
	{
		`log("      Type=" $ m_arrArmorLoadouts[i].m_eArmorType $ ", Name=" $ m_arrArmorLoadouts[i].m_strArmorName $ ", Cost=" $ m_arrArmorLoadouts[i].m_iArmorCost, true, 'XCom_Net');
	}
	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: Item Loadout Data", true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');
	for(i = 0; i < m_arrItemLoadouts.Length; i++)
	{
		`log("      Type=" $ m_arrItemLoadouts[i].m_eItemType $ ", Name=" $ m_arrItemLoadouts[i].m_strItemName $ ", Cost=" $ m_arrItemLoadouts[i].m_iItemCost, true, 'XCom_Net');
	}
	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: Character Loadout Data", true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');
	for(i = 0; i < m_arrCharacterLoadouts.Length; i++)
	{
		`log("      Type=" $ m_arrCharacterLoadouts[i].m_TemplateName $ ", Name=" $ m_arrCharacterLoadouts[i].m_strCharacterName $ ", Cost=" $ m_arrCharacterLoadouts[i].m_iCharacterCost, true, 'XCom_Net');
	}
	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: Max Squad Costs", true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');
	for(i = 0; i < m_arrMaxSquadCosts.Length; i++)
	{
		`log("      Cost=" $ m_arrMaxSquadCosts[i], true, 'XCom_Net');
	}
	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: Turn Timers", true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');
	for(i = 0; i < m_arrTurnTimers.Length; i++)
	{
		`log("      " $ m_arrTurnTimers[i] @ "seconds", true, 'XCom_Net');
	}
	`log("*******************************", true, 'XCom_Net');
	`log("XComMPData: Map Data", true, 'XCom_Net');
	`log("*******************************", true, 'XCom_Net');
	for(i = 0; i < m_arrMaps.Length; i++)
	{
		`log("      MapName=" $ m_arrMaps[i].m_nmMapName $ ", MapIndex=" $ m_arrMaps[i].m_iMapNameIndex $ ", LocalizedName=" $ m_arrMaps[i].m_strMapDisplayName $ ", GameType=" $ m_arrMaps[i].m_eGameType $ ", DebugOnly=" $ m_arrMaps[i].m_bDebugOnly, true, 'XCom_Net');
	}
	`log("*******************************", true, 'XCom_Net');
}

/////////////////////////////////////////////////////////

defaultproperties
{
	m_bInitialized=false;
	m_strINIFilename="XComMPGame.ini"

	m_arrPatientZero(0)=(m_strPatientName="InhumanTorch",m_iPlatform=4)         // Xbox (Jake)
	m_arrPatientZero(1)=(m_strPatientName="FXS_Shaka",m_iPlatform=64)           // Windows Console
	m_arrPatientZero(2)=(m_strPatientName="FXS_Shaka",m_iPlatform=1)            // Windows
	m_arrPatientZero(3)=(m_strPatientName="mrgxeuacv1",m_iPlatform=4)           // Xbox (QA, PartnerNet)
	m_arrPatientZero(4)=(m_strPatientName="mrgxeuacv2",m_iPlatform=4)           // Xbox (QA, PartnerNet)
	m_arrPatientZero(5)=(m_strPatientName="cbubonic789",m_iPlatform=4)          // Xbox (QA, PartnerNet)
	m_arrPatientZero(6)=(m_strPatientName="Tools Tag",m_iPlatform=4)            // Xbox (Casey)
	m_arrPatientZero(7)=(m_strPatientName="Kilguren",m_iPlatform=4)             // Xbox (Garrett)
}
