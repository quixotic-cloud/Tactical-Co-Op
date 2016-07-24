//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUtilities_Sound.uc
//  AUTHOR:  bsteiner
//  PURPOSE: Container of static helper functions for the UI sounds. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUtilities_Sound extends Object;

// ==========================================================================

public static  function PlayOpenSound()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuOpen");
}
public static  function PlayCloseSound()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClose");
}
public static  function PlayNegativeSound()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
}
public static  function PlayPositiveSound()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}