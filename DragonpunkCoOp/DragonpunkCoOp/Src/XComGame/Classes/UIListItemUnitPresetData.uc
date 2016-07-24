//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIListItemUnitPresetData.uc
//  AUTHOR:  Todd Smith  --  10/6/2015
//  PURPOSE: Item in a UI list that contains a reference to a unit preset
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIListItemUnitPresetData extends UIListItemString
	dependson(X2MPData_Native);

var TX2UnitPresetData   m_kUnitPresetData;