//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_UnitCostPanel.uc
//  AUTHOR:  Todd Smith  --  7/7/2015
//  PURPOSE: Displays info about a units total cost
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_UnitCostPanel extends UIPanel;

var localized string m_strUnitCostText;

var UIText UnitText;
var UIText UnitCostText;

var int m_iUnitCost;

function InitUnitCostPanel(int iUnitCost, optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	m_iUnitCost = iUnitCost;

	UnitText = Spawn(class'UIText', self).InitText(, m_strUnitCostText);
	UnitText.SetPosition(0, 0);

	UnitCostText = Spawn(class'UIText', self).InitText(, string(m_iUnitCost));
	UnitCostText.SetPosition(0, 30);
}

function SetUnitCost(int iUnitCost)
{
	m_iUnitCost = iUnitCost;
	UnitCostText.SetText(string(m_iUnitCost));
}

defaultproperties
{
}