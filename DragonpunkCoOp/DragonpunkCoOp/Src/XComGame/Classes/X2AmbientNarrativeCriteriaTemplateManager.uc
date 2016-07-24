//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2AmbientNarrativeCriteriaTemplateManager.uc
//  AUTHOR:  Brian Whitman --  7/2/2015
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2AmbientNarrativeCriteriaTemplateManager extends X2DataTemplateManager
	native(Core);

native static function X2AmbientNarrativeCriteriaTemplateManager GetAmbientNarrativeCriteriaTemplateManager();

function bool AddAmbientNarrativeCriteriaTemplate(X2AmbientNarrativeCriteriaTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2AmbientNarrativeCriteriaTemplate FindAmbientCriteriaTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2AmbientNarrativeCriteriaTemplate(kTemplate);
	return none;
}

defaultproperties
{
	TemplateDefinitionClass=class'X2AmbientNarrativeCriteria'
}