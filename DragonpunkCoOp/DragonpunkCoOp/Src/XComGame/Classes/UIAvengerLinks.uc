//---------------------------------------------------------------------------------------
//  FILE:    UIAvengerShortcuts.uc
//  AUTHOR:  Brit Steiner --  12/22/2014
//  PURPOSE:Soldier category options list. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIAvengerLinks extends UIPanel;

//----------------------------------------------------------------------------
// MEMBERS

var localized string LabelBridgeButton;

var UIButton BridgeButton;

//----------------------------------------------------------------------------
// FUNCTIONS


simulated function UIAvengerLinks InitLinks(optional name InitName)
{
	InitPanel(InitName); 
	SetY(10);
	AnchorTopCenter();

	// TODO: Commenting this out per Jake on 4/16/2015. Not deleting this, because I suspect we will need this 
	// container soon for bridge and potential shadow chamber etc. special button links. 

	//TODO: this will be replaced with cool flashy art. With glow. And BLOOM. And sparkles. -bsteiner 
	/*BridgeButton = Spawn(class'UIButton', self).InitButton('BridgeButton', LabelBridgeButton, OnClickBridge);
	BridgeButton.SetPosition(-75, 0).SetWidth(150);
	BridgeButton.SetStyle(eUIButtonStyle_HOTLINK_BUTTON, , false);*/

	return self; 
}

function OnClickBridge(UIButton Button)
{
	/*local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersXCom HQ;

	HQ = class'UIUtilities_Strategy'.static.GetXComHQ(); 

	FacilityState = HQ.GetFacilityByName('CIC'); 

	if( FacilityState != none )
	{
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
	}*/
}

//==============================================================================

defaultproperties
{
	MCName          = "Links";	
	bIsNavigable	= true; 
}
