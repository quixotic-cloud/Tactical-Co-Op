//---------------------------------------------------------------------------------------
//  FILE:    X2DataTemplate.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2DataTemplate extends Object
	abstract
	PerObjectConfig
	Config(XComGame)
	native(Core);

//--- Game Areas
const BITFIELD_GAMEAREA_None				= 0;    // WARNING: Do NOT edit this value!
const BITFIELD_GAMEAREA_Internal			= 1;    // WARNING: Do NOT edit this value!
const BITFIELD_GAMEAREA_Strategy			= 2;    // WARNING: Do NOT edit this value!
const BITFIELD_GAMEAREA_Tactical			= 4;    // WARNING: Do NOT edit this value!
const BITFIELD_GAMEAREA_Multiplayer			= 8;    // WARNING: Do NOT edit this value!
const BITFIELD_GAMEAREA_Challenge			= 16;   // WARNING: Do NOT edit this value!
const BITFIELD_GAMEAREA_Easy				= 32;   // WARNING: Do NOT edit this value!
const BITFIELD_GAMEAREA_Normal				= 64;   // WARNING: Do NOT edit this value!
const BITFIELD_GAMEAREA_Classic				= 128;   // WARNING: Do NOT edit this value!
const BITFIELD_GAMEAREA_Impossible			= 256;   // WARNING: Do NOT edit this value!
//--- Combined Fields
const BITFIELD_GAMEAREA_ALL_DIFFICULTIES	= 480;
const BITFIELD_GAMEAREA_Singleplayer		= 502;   // BITFIELD_GAMEAREA_Strategy | BITFIELD_GAMEAREA_Tactical | BITFIELD_GAMEAREA_Challenge
const BITFIELD_GAMEAREA_Online				= 504;   // BITFIELD_GAMEAREA_Multiplayer | BITFIELD_GAMEAREA_Challenge
const BITFIELD_GAMEAREA_ALL					= 510;   // NOTE: Update this if another Game Area is added (Last Game Area Value * 2) - 1 - Internal



var(BaseTemplate) protectedwrite name       DataName;
var(BaseTemplate) protectedwrite int        TemplateAvailability;  // Bitfield: Template is available to the specified areas
var bool bIsScript;

// If true, this template type should construct variants of each data template for each difficulty setting
var(BaseTemplate) bool bShouldCreateDifficultyVariants;

function SetTemplateName(name NewName)
{
	DataName = NewName;
}

function bool ValidateTemplate(out string strError)
{
	return true;
}


/// <summary>
/// Overrides the current availability with the specified areas.
/// </summary>
/// <param name="GameAreas">Bitfield: Any BITFIELD_GAMEAREA_ constant will provide a suitable value.</param>
event SetTemplateAvailablility(int GameAreas)
{
	TemplateAvailability = GameAreas;
}

/// <summary>
/// Includes the specified availability with the current.
/// </summary>
/// <param name="GameAreas">Bitfield: Any BITFIELD_GAMEAREA_ constant will provide a suitable value.</param>
event AddTemplateAvailablility(int GameAreas)
{
	TemplateAvailability = TemplateAvailability | GameAreas;
}

/// <summary>
/// Excludes the specified areas from the availability list.
/// </summary>
/// <param name="GameAreas">Bitfield: Any BITFIELD_GAMEAREA_ constant will provide a suitable value.</param>
event RemoveTemplateAvailablility(int GameAreas)
{
	TemplateAvailability = TemplateAvailability & (~GameAreas);
}

/// <summary>
/// Checks to make sure that the template belongs to any one of the specified areas.
/// </summary>
/// <param name="GameAreas">Bitfield: Any BITFIELD_GAMEAREA_ constant will provide a suitable value.</param>
event bool IsTemplateAvailableToAnyArea(int GameAreas)
{
	return ((TemplateAvailability & GameAreas) != 0);
}

/// <summary>
/// Checks to make sure that the template belongs to any one of the specified areas.
/// </summary>
/// <param name="GameAreas">Bitfield: Any BITFIELD_GAMEAREA_ constant will provide a suitable value.</param>
event bool IsTemplateAvailableToAllAreas(int GameAreas)
{
	return ((TemplateAvailability & GameAreas) == GameAreas);
}

function SetDifficulty(int DifficultyIndex)
{
	`assert(DifficultyIndex >= `MIN_DIFFICULTY_INDEX);
	`assert(DifficultyIndex <= `MAX_DIFFICULTY_INDEX);

	RemoveTemplateAvailablility(BITFIELD_GAMEAREA_ALL_DIFFICULTIES);
	AddTemplateAvailablility(BITFIELD_GAMEAREA_Easy * (1 << DifficultyIndex));
}

cpptext
{
	virtual UBOOL ShouldExportLoc() const
	{
		// export loc only for templates that are relevant to all difficulties
		return ((TemplateAvailability & UCONST_BITFIELD_GAMEAREA_ALL_DIFFICULTIES) == UCONST_BITFIELD_GAMEAREA_ALL_DIFFICULTIES);
	}

#if WITH_EDITOR
	virtual void CheckForErrors();
#endif
};

defaultproperties
{
	bIsScript=true
	TemplateAvailability=BITFIELD_GAMEAREA_ALL
}