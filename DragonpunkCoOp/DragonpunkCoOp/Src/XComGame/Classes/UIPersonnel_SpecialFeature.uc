//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPersonnel_SpecialFeature
//  AUTHOR:  Sam Batista
//  PURPOSE: Provides custom behavior for personnel selection screen
//           when clearing a special feature from a room.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIPersonnel_SpecialFeature extends UIPersonnel;

defaultproperties
{
	m_eListType = eUIPersonnel_Engineers;
	m_bRemoveWhenUnitSelected = true;
}