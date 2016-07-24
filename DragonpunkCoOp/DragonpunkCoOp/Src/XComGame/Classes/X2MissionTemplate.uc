//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MissionTemplate.uc
//  AUTHOR:  Brian Whitman --  4/3/2015
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MissionTemplate extends X2DataTemplate
	native(Core);

var() privatewrite localized string DisplayName;				// The primary Objective for this mission before it is completed
var() privatewrite localized string PostMissionType;			// The primary Objective for this mission after it is completed
var() privatewrite localized string BriefingImage;
var() privatewrite localized string Briefing;					// The primary Objective for this mission, as displayed on the Dropship loading screen
var() privatewrite localized array<string> ObjectiveTextPools; // List of text lines to display in the objectives list in the drop ship mission start screen
var() privatewrite localized array<string> PreMissionNarratives; // Narrative moment to play on the pre mission dropship

function int GetNumObjectives()
{
	return ObjectiveTextPools.Length;
}

function string GetObjectiveText(int TextLine, optional name QuestItemTemplateName)
{
	local XGParamTag ParamTag;
	local X2QuestItemTemplate QuestItem;

	if(TextLine < 0 || TextLine >= ObjectiveTextPools.Length)
	{
		return "Error: Invalid objective text line requested.";
	}
	else
	{
		if(QuestItemTemplateName != '')
		{
			ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			QuestItem = X2QuestItemTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(QuestItemTemplateName));

			if(QuestItem != none)
			{
				ParamTag.StrValue0 = QuestItem.GetItemFriendlyName();
				return `XEXPAND.ExpandString(ObjectiveTextPools[TextLine]);
			}
		}
		
		return ObjectiveTextPools[TextLine];
	}
}