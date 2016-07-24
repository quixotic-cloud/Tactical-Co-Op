//---------------------------------------------------------------------------------------
//  FILE:    XComAnimNodeIdle.uc
//  AUTHOR:  Ryan McFall  --  11/08/2012
//  PURPOSE: This animation node blends between the various animation sequences that can
//           play while a unit's active action is XGAction_Idle.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComAnimNodeIdle extends AnimNodeBlendList native;

enum EAnimIdle
{
	eAnimIdle_Peek,
	eAnimIdle_Flinch,
	eAnimIdle_Fire,
	eAnimIdle_Idle,		
	eAnimIdle_Panic, 
	eAnimIdle_HunkerDown
};

DefaultProperties
{
	Children(eAnimIdle_Peek)=(Name="Peek")
	Children(eAnimIdle_Flinch)=(Name="Flinch")
	Children(eAnimIdle_Fire)=(Name="Fire")
	Children(eAnimIdle_Idle)=(Name="Idle")
	Children(eAnimIdle_Panic)=(Name="Panic")
	Children(eAnimIdle_HunkerDown)=(Name="Hunker Down")

	bFixNumChildren=true
	bPlayActiveChild=true
}
