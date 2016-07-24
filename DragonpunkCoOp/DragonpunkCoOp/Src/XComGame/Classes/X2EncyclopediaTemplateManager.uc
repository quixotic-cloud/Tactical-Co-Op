//---------------------------------------------------------------------------------------
//  FILE:    X2EncyclopediaTemplateManager.uc
//  AUTHOR:  Dan Kaplan - 10/1/2015
//  PURPOSE: Template manager for Encyclopedia entries in X-Com 2.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2EncyclopediaTemplateManager extends X2DataTemplateManager
	native(Core) config(Encyclopedia);


native static function X2EncyclopediaTemplateManager GetEncyclopediaTemplateManager();

function bool AddEncyclopediaTemplate(X2EncyclopediaTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2EncyclopediaTemplate FindEncyclopediaTemplate(Name DataName)
{
	local X2DataTemplate EncyclopediaTemplate;

	EncyclopediaTemplate = FindDataTemplate(DataName);

	if( EncyclopediaTemplate != None )
	{
		return X2EncyclopediaTemplate(EncyclopediaTemplate);
	}

	return None;
}

DefaultProperties
{
	TemplateDefinitionClass = class'X2Encyclopedia'
}