//---------------------------------------------------------------------------------------
//  FILE:    X2CardManager_SerializeDataMP.uc
//  AUTHOR:  Ryan McFall  --  3/16/2015
//  PURPOSE: Simple container object used to sync the card manager state for MP games
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2CardManager_SerializeDataMP extends Object native(Core);

var array<SavedCardDeck> SavedCardDecks; // Save data for the X2CardManager

defaultproperties
{
}
