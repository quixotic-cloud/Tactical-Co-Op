//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MissionTemplateManager.uc
//  AUTHOR:  Brian Whitman --  4/3/2015
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MissionTemplateManager extends X2DataTemplateManager
	native(Core);

native static function X2MissionTemplateManager GetMissionTemplateManager();

function bool AddMissionTemplate(X2MissionTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

/// <summary>
/// Finds the most suitable mission template and returns the displayname for it
/// </summary>
simulated function string GetMissionDisplayName(Name MissionName)
{
	local X2MissionTemplate MissionTemplate;
	MissionTemplate = FindMissionTemplate(MissionName);
	if (MissionTemplate != none)
	{
		return MissionTemplate.DisplayName;
	}
	else
	{
		return "UNLOCALIZED:"@MissionName;
	}
}

/// <summary>
/// Finds the most suitable mission template for the given mission name
/// </summary>
native function X2MissionTemplate FindMissionTemplate(Name MissionName);

defaultproperties
{
	TemplateDefinitionClass=class'X2Mission'
}