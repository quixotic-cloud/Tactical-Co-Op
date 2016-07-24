//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    IScreenMgrInterface
//  AUTHOR:  Brit Steiner       -- 7/15/11
//  PURPOSE: Interface class for any element which interacts with a UI data manager. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

interface IScreenMgrInterface
	dependson(XGNarrative);

// Implemented in XGScreenManager.uc - sbatista
//function Narrative( TNarrativeMoment kNarrative );
//function UnlockItem( TItemUnlock kUnlock );
function GoToView( int iView );

//Already shared by both FxsPanel and Proto Screens, but necessary here for manager access. 
simulated function bool IsVisible();
simulated function Hide();
simulated function Show();
