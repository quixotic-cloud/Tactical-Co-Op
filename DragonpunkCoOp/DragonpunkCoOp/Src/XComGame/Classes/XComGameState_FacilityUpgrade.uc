//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_FacilityUpgrade.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_FacilityUpgrade extends XComGameState_BaseObject native(Core);

var() protected name                   m_TemplateName;
var() protected X2FacilityUpgradeTemplate     m_Template;

var() StateObjectReference             Facility;

static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

simulated function X2FacilityUpgradeTemplate GetMyTemplate()
{
	if (m_Template == none)
	{
		m_Template = X2FacilityUpgradeTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

function OnCreation(X2FacilityUpgradeTemplate Template)
{
	m_Template = Template;
	m_TemplateName = Template.DataName;
}

// Assign to the facility first
function OnUpgradeAdded(XComGameState NewGameState, XComGameState_FacilityXCom FacilityState)
{	
	GetMyTemplate().OnUpgradeAddedFn(NewGameState, self, FacilityState);
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}