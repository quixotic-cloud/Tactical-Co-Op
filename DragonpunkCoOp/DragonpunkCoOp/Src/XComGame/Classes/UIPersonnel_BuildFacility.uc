//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPersonnel_BuildFacility
//  AUTHOR:  Sam Batista
//  PURPOSE: Provides custom behavior for personnel selection screen
//           when building a facility.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIPersonnel_BuildFacility extends UIPersonnel;

defaultproperties
{
	m_eListType = eUIPersonnel_Engineers;
	m_bRemoveWhenUnitSelected = true;
}