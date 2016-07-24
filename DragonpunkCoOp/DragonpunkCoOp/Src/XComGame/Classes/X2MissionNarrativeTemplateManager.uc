//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MissionNarrativeTemplateManager.uc
//  AUTHOR:  David Burchanowski  --  1/29/2015
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MissionNarrativeTemplateManager extends X2DataTemplateManager
	native(Core);

native static function X2MissionNarrativeTemplateManager GetMissionNarrativeTemplateManager();

function bool AddMissionNarrativeTemplate(X2MissionNarrativeTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

/// <summary>
/// Finds the most suitable mission narrative template for the given mission type and quest item template
/// </summary>
native function X2MissionNarrativeTemplate FindMissionNarrativeTemplate(string MissionType, optional Name QuestItemTemplate = '');

defaultproperties
{
	TemplateDefinitionClass=class'X2MissionNarrative'
}