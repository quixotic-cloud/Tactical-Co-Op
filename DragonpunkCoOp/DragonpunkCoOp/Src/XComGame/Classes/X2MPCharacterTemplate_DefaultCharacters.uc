//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPCharacterTemplate_DefaultCharacters.uc
//  AUTHOR:  Todd Smith  --  10/13/2015
//  PURPOSE: Initialization of the X2MPCharacterTemplates
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPCharacterTemplate_DefaultCharacters extends X2MPCharacter
	config(MPCharacterData);

var config array<name> MPCharacters;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2MPCharacterTemplate Template;
	local name MPCharacterName;

	Templates.Length = 0;
	foreach default.MPCharacters(MPCharacterName)
	{
		`CREATE_X2TEMPLATE(class'X2MPCharacterTemplate', Template, MPCharacterName);
		`log("X2MPCharacterTemplate_DefaultCharacters::" $ GetFuncName() @ `ShowVar(MPCharacterName) @ `ShowVar(Template.Cost) @ `ShowVar(Template.DisplayName),, 'XCom_Net');
		Templates.AddItem(Template);
	}
	
	return Templates;
}