//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2AmbientNarrativeCriteria_Defaults.uc
//  AUTHOR:  Brian Whitman --  7/2/2015
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2AmbientNarrativeCriteria_Defaults extends X2AmbientNarrativeCriteria;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2AmbientNarrativeCriteriaTemplate> Templates;
	local array<X2StrategyElementTemplate> OtherTemplates;
	local X2StrategyElementTemplate Template;

    Templates.AddItem(AddBasicAmbientNarrativeCriteriaTemplate());

	OtherTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2FacilityTemplate');
    foreach OtherTemplates(Template)
	{
		Templates.AddItem(AddRoomSpecificAmbientNarrativeCriteriaTemplate(string(Template.DataName)));
	}

	OtherTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2ObjectiveTemplate');
    foreach OtherTemplates(Template)
	{
		Templates.AddItem(AddGoldenPathAmbientNarrativeCriteriaTemplate(string(Template.DataName)));
	}

    return Templates;
}

static function X2AmbientNarrativeCriteriaTemplate AddBasicAmbientNarrativeCriteriaTemplate()
{
    local X2AmbientNarrativeCriteriaTemplate Template;
	`CREATE_X2TEMPLATE(class'X2AmbientNarrativeCriteriaTemplate', Template, 'Basic');
	return Template;
}

static function X2AmbientNarrativeCriteriaTemplate AddGoldenPathAmbientNarrativeCriteriaTemplate(string ObjectiveTemplateName)
{
    local X2AmbientNarrativeCriteria_GoldenPath Template;
	`CREATE_X2TEMPLATE(class'X2AmbientNarrativeCriteria_GoldenPath', Template, name("GoldenPath_"$ObjectiveTemplateName));
	Template.ObjectiveTemplateName = name(ObjectiveTemplateName);
	return Template;
}

static function X2AmbientNarrativeCriteriaTemplate AddRoomSpecificAmbientNarrativeCriteriaTemplate(string FacilityTemplateName)
{
    local X2AmbientNarrativeCriteria_RoomSpecific Template;
	`CREATE_X2TEMPLATE(class'X2AmbientNarrativeCriteria_RoomSpecific', Template, name("RoomSpecific_"$FacilityTemplateName));
	Template.RoomTemplateName = name(FacilityTemplateName);
	return Template;
}
