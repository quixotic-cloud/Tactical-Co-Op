//---------------------------------------------------------------------------------------
//  FILE:    X2Action_UnstreamDropshipIntro.uc
//  AUTHOR:  David Burchanowski  --  4/9/2015
//  PURPOSE: Unloads the maps for the dropship intro. This exists in a separate action so that any cleanup nodes on the 
//           matinee's completed event have a chance to execute before we unstream the map.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_UnstreamDropshipIntro extends X2Action_PlayMatinee config(GameData);

simulated state Executing
{
	function UnstreamIntroMaps()
	{
		local XComTacticalMissionManager MissionManager;	
		local MissionIntroDefinition MissionIntro;
		local AdditionalMissionIntroPackageMapping AdditionalIntroPackage;

		// unload the base matinee package
		MissionManager = `TACTICALMISSIONMGR;
		MissionIntro = MissionManager.GetActiveMissionIntroDefinition();
		class'XComMapManager'.static.RemoveStreamingMapByName(MissionIntro.MatineePackage, false);

		// unload any additional maps that were added by mods
		foreach MissionManager.AdditionalMissionIntroPackages(AdditionalIntroPackage)
		{
			if(AdditionalIntroPackage.OriginalIntroMatineePackage == MissionIntro.MatineePackage)
			{
				class'XComMapManager'.static.RemoveStreamingMapByName(AdditionalIntroPackage.AdditionalIntroMatineePackage, false);
			}
		}
	}

Begin:
	UnstreamIntroMaps();

	CompleteAction();
}

DefaultProperties
{
}
