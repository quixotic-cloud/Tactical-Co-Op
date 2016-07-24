//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_CommanderHUD.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Container for commander ability buttons.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITacticalHUD_CommanderHUD extends UIPanel; 

var array<UIButton> Buttons; 
var array<AvailableAction> Abilities;

//----------------------------------------------------------------------------
// METHODS
//

simulated function UITacticalHUD_CommanderHUD InitCommanderHUD( optional int InitX = 0, optional int InitY = 0)  
{
	InitPanel();

	AnchorTopRight();

	//DEBUG: 
	//Spawn(class'UIPanel', self).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(10, 80);

	return self; 
}


simulated function RefreshCommanderAbilities( array<AvailableAction> arrAbilities )
{
	local AvailableAction SelectedUIAction;
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local UIButton Button, PreviousButton; 
	local int i; 

	Abilities = arrAbilities; 

	for( i = 0; i < Abilities.Length; i++ )
	{
		// Build new items if we need to. 
		if( i > Buttons.Length-1 )
		{
			Button = Spawn(class'UIButton', self); 
			Button.InitButton('', , OnButtonClicked, eUIButtonStyle_BUTTON_WHEN_MOUSE);

			if( Buttons.length == 0 )
			{
				Button.SetPosition( -180, 10 );
			}
			else
			{ 
				PreviousButton = Buttons[Buttons.length-1]; 
				Button.SetPosition( PreviousButton.X - 150, 0 );
			}

			Buttons.AddItem(Button); 
		}

		// Grab our target item
		Button = Buttons[i]; 

		//Update Data 
		SelectedUIAction = Abilities[i];
		SelectedAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SelectedUIAction.AbilityObjectRef.ObjectID));
		SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();
		Button.SetText( SelectedAbilityTemplate.LocFriendlyName ); 

		Button.Show();
	}


	// Hide any excess list items if we didn't use them. 
	for( i = Abilities.Length; i < Buttons.Length; i++ )
	{
		Buttons[i].Hide();
	}
}

simulated function OnButtonClicked( UIButton Button )
{
	local int iIndex, AbilityHudIndex; 

	iIndex = Buttons.Find( Button ); 

	if( iIndex == -1 ) 
		return; // You dun messed up. 

	AbilityHudIndex = UITacticalHUD(screen).m_kAbilityHUD.GetAbilityIndex(Abilities[iIndex]);
	
	UITacticalHUD(screen).m_kAbilityHUD.SelectAbility( AbilityHudIndex );
}


// --------------------------------------
defaultproperties
{
	bAnimateOnInit = false;
}
