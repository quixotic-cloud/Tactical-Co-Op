//---------------------------------------------------------------------------------------
//  FILE:    X2Encyclopedia.uc
//  AUTHOR:  Dan Kaplan  --  10/1/2015
//  PURPOSE: Interface for adding new Encyclopedia entries to X-Com 2.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Encyclopedia extends X2DataSet
	config(Encyclopedia);

var config array<name> EncyclopediaNames;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2EncyclopediaTemplate Template;
	local name TemplateName;
	
	foreach default.EncyclopediaNames(TemplateName)
	{
		`CREATE_X2TEMPLATE(class'X2EncyclopediaTemplate', Template, TemplateName);
		Templates.AddItem(Template);
	}

	return Templates;
}

