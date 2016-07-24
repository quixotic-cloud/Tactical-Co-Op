//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_SetDestructibleActorToughness.uc
//  AUTHOR:  Liam Collins --  10/25/2013
//  PURPOSE: This sequence action changes the toughness setting on a 
//           destructible actor.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_SetDestructibleActorToughness extends SequenceAction
	deprecated;

var Actor   TargetActor;
var() XComDestructibleActor_Toughness TargetToughness;

event Activated()
{
	local XComDestructibleActor TargetDestructible;	
	local float fHealthPercentage;

	TargetDestructible = XComDestructibleActor(TargetActor);
	fHealthPercentage = TargetDestructible.Health / float(TargetDestructible.TotalHealth);

	if( TargetDestructible != none )
	{
		TargetDestructible.Toughness = TargetToughness;		
		TargetDestructible.TotalHealth = TargetToughness.Health;

		if(TargetDestructible.IsInState('_Pristine'))
		{
			TargetDestructible.Health = TargetDestructible.TotalHealth;
		}
		else
		{
			TargetDestructible.Health = int(TargetToughness.Health * fHealthPercentage);
		}
	}
	else
	{
		`warn("SeqAct_SetDestructibleToughness called on non destructible actor:"@TargetActor@" This sequence action requires a destructible actor input.");
	}

}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Set DestructibleActor Toughness"
	bCallHandler=false

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Actor",PropertyName=TargetActor)
}
