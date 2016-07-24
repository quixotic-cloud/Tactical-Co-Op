//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComSpawnSalvagePoint.uc    
//  AUTHOR:  Jesse Smith  --  3/3/2010
//  PURPOSE: Allows the LD's to place spawn locations for the salvage. These are randomly selected
//           to determine where the actual salvage will be spawned
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComSpawnSalvagePoint extends Actor
	placeable;

var()   ESalvageType m_eSalvageType;
var()   EItemType m_eItemType;

defaultproperties
{
	m_eItemType = eItem_NONE
	m_eSalvageType = eSalvage_NONE

	Begin Object Class=ArrowComponent Name=Arrow
		ArrowColor=(R=150,G=200,B=255)
		ArrowSize=0.5
		bTreatAsASprite=True
		HiddenGame=true
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Arrow)

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_Thruster'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Sprite)
	
	bMovable=false

	// original.
	bStatic=FALSE
	bNoDelete=FALSE

	// navpoint
	bHidden=FALSE

	bCollideWhenPlacing=true
	bCollideActors=false
}
