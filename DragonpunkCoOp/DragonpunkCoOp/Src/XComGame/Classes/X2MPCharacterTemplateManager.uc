//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPCharacterTemplateManager.uc
//  AUTHOR:  Todd Smith  --  10/13/2015
//  PURPOSE: Manager for character templates for multiplayer units
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPCharacterTemplateManager extends X2DataTemplateManager
	native(MP) 
	config(MPCharacterData);

struct native TemplateMapping
{
	var name OldTemplateName;
	var name TemplateName;
};

var config array<TemplateMapping> CharacterTemplateMapping;

native static function X2MPCharacterTemplateManager GetMPCharacterTemplateManager();

protected event ValidateTemplatesEvent()
{
	super.ValidateTemplatesEvent();
}

function X2MPCharacterTemplate FindMPCharacterTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2MPCharacterTemplate(kTemplate);
	return none;
}

function name FindCharacterTemplateMapOldToNew(name OldTemplateName)
{
	local int i;
	for( i = 0; i < CharacterTemplateMapping.Length; ++i )
	{
		if( CharacterTemplateMapping[i].OldTemplateName == OldTemplateName )
		{
			return CharacterTemplateMapping[i].TemplateName;
		}
	}
	return OldTemplateName;
}

function name FindCharacterTemplateMapNewToOld(name TemplateName)
{
	local int i;
	for( i = 0; i < CharacterTemplateMapping.Length; ++i )
	{
		if( CharacterTemplateMapping[i].TemplateName == TemplateName )
		{
			return CharacterTemplateMapping[i].OldTemplateName;
		}
	}
	return TemplateName;
}

defaultproperties
{
	TemplateDefinitionClass=class'X2MPCharacter';
}