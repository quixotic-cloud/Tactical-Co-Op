class X2ExperienceConfig extends Object
	native(Core)
	config(GameData_XpData);


///////////////////////////////
// XP 

struct native DifficultyXPSet
{
	var() array<int>				  RequiredKills;    //  number of kills needed for each rank
};

var protected config array<DifficultyXPSet>	PerDifficultyConfig;

var const bool                        bUseFullXpSystem; //  If true, RequiredXp and all XpEvents, BaseMissionXp, etc. are all used as designed. Otherwise, only RequiredKills matter.
var protected config array<int>       RequiredXp;       //  defines total XP needed for each rank
var protected localized array<string> RankNames;        //  there should be one name for each rank; e.g. Rookie, Squaddie, etc.
var protected localized array<string> ShortNames;       //  the abbreviated rank name; e.g. Rk., Sq., etc.
var protected localized array<string> PsiRankNames;     //  deprecated
var protected localized array<string> PsiShortNames;    //  deprecated
var config array<XpEventDef>          XpEvents;         //  defines the name, shares, pool amount, and restrictions of all known XP-granting events
var protected config array<int>       BaseMissionXp;    //  configured by force level
var protected config array<int>       BonusMissionXp;   //  configured by force level
var protected config array<int>       MaxKillscore;     //  configured by force level
var protected config float            KillMissionXpCap; //  percentage modifier against the BonusMissionXp which determines the cap on kill xp
var const config float                KillXpBonusMult;  //  if the kill xp OTS unlock has been purchased, this is the bonus amount at the end of battle
var const config float                NumKillsBonus;    //  if the kill xP OTS unlock has been purchased, a soldier's number of kills gets this bonus multiplier when considering rank up

///////////////////////////////
// Squad Cohesion

var config int                        SquadmateScore_MedikitHeal;
var config int                        SquadmateScore_CarrySoldier;
var config int                        SquadmateScore_KillFlankingEnemy;
var config int                        SquadmateScore_Stabilize;

///////////////////////////////
// Alert Level

struct native AlertEventDef
{
	// The gameplay event which triggers this Alert Level modification.
	var name EventID;

	// The amount of value to be added to the current Alert Level when this event is triggered.
	var int AlertLevelBonus;

	// The friendly display string for this event in the post-mission completion UI.
	var localized string DisplayString;
};

// All of the Events for which there will be an Alert Level modification when triggered.
var private config array<AlertEventDef> AlertEvents;


///////////////////////////////
// Popular Support

struct native PopularSupportEventDef
{
	// The gameplay event which triggers this pop support modification.
	var name EventID;

	// The amount of value to be added to the current pop support when this event is triggered.
	var int PopularSupportBonus;

	// The friendly display string for this event in the post-mission completion UI.
	var localized string DisplayString;
};

// All of the Events for which there will be an pop support modification when triggered.
var private config array<PopularSupportEventDef> PopularSupportEvents;



///////////////////////////////
// XP 

static native function int GetBaseMissionXp(int ForceLevel);
static native function int GetBonusMissionXp(int ForceLevel);
static native function int GetMaxKillscore(int ForceLevel);

static function string GetRankName(const int Rank, name ClassName)
{
	local X2SoldierClassTemplate ClassTemplate;

	CheckRank(Rank);
	
	ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(ClassName);
	
	if (ClassTemplate != none && ClassTemplate.RankNames.Length > 0)
		return ClassTemplate.RankNames[Rank];
	else
		return default.RankNames[Rank];
}

static function string GetShortRankName(const int Rank, name ClassName)
{
	local X2SoldierClassTemplate ClassTemplate;

	CheckRank(Rank);

	ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(ClassName);

	if (ClassTemplate != none && ClassTemplate.ShortNames.Length > 0)
		return ClassTemplate.ShortNames[Rank];
	else
		return default.ShortNames[Rank];
}

static function int GetRequiredXp(const int Rank)
{
	CheckRank(Rank);
	return default.RequiredXp[Rank];
}

static function int GetRequiredKills(const int Rank)
{
	CheckRank(Rank);
	return default.PerDifficultyConfig[`DIFFICULTYSETTING].RequiredKills[Rank];
}

static function int GetMaxRank()
{
	return default.RequiredXp.Length;
}

static function bool CheckRank(const int Rank)
{
	if (Rank < 0 || Rank >= default.RequiredXp.Length)
	{
		`RedScreen("Rank" @ Rank @ "is out of bounds for configured XP (" $ default.RequiredXp.Length $ ")\n" $ GetScriptTrace());
		return false;
	}
	return true;
}

static function bool FindXpEvent(name EventID, out XpEventDef EventDef)
{
	local int i;

	for (i = 0; i < default.XpEvents.Length; ++i)
	{
		if (default.XpEvents[i].EventID == EventID)
		{
			EventDef = default.XpEvents[i];
			return true;
		}
	}
	return false;
}


///////////////////////////////
// Squad Cohesion

static function int GetSquadCohesionValue(array<XComGameState_Unit> Units)
{
	local int TotalCohesion, i, j;
	local SquadmateScore Score;

	TotalCohesion = 0;

	for (i = 0; i < Units.Length; ++i)
	{
		for (j = i + 1; j < Units.Length; ++j)
		{
			if (Units[i].GetSquadmateScore(Units[j].ObjectID, Score))
			{
				TotalCohesion += Score.Score;
			}
		}
	}
	return TotalCohesion;
}


///////////////////////////////
// Alert Level

static function int GetAlertLevelBonusForEvent( Name InEvent )
{
	local int i;

	for( i = 0; i < default.AlertEvents.length; ++i )
	{
		if( InEvent == default.AlertEvents[i].EventID )
		{
			return default.AlertEvents[i].AlertLevelBonus;
		}
	}

	return 0;
}

static function int GetAlertLevelDataForEvent( Name InEvent, out string OutDisplayString )
{
	local int i;

	for( i = 0; i < default.AlertEvents.length; ++i )
	{
		if( InEvent == default.AlertEvents[i].EventID )
		{
			OutDisplayString = default.AlertEvents[i].DisplayString;
			return default.AlertEvents[i].AlertLevelBonus;
		}
	}

	return 0;
}


///////////////////////////////
// Popular Support

static function int GetPopularSupportBonusForEvent( Name InEvent )
{
	local int i;

	for( i = 0; i < default.PopularSupportEvents.length; ++i )
	{
		if( InEvent == default.PopularSupportEvents[i].EventID )
		{
			return default.PopularSupportEvents[i].PopularSupportBonus;
		}
	}

	return 0;
}

static function int GetPopularSupportDataForEvent( Name InEvent, out string OutDisplayString )
{
	local int i;

	for( i = 0; i < default.PopularSupportEvents.length; ++i )
	{
		if( InEvent == default.PopularSupportEvents[i].EventID )
		{
			OutDisplayString = default.PopularSupportEvents[i].DisplayString;
			return default.PopularSupportEvents[i].PopularSupportBonus;
		}
	}

	return 0;
}
