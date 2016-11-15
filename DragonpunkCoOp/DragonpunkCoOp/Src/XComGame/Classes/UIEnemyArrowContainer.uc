class UIEnemyArrowContainer extends UIScreen dependson(X2GameRuleset);

var bool bActive;
var array<XGUnit> arrCurrent;

var XGUnit m_kNextTarget;
var XGUnit m_kPrevTarget;

//=====================================================================
// 		GENERAL FUNCTIONS:
//=====================================================================
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
}


simulated function OnInit()
{
	// TODO:TARGETING
	//local XGUnit        kUnit;

	super.OnInit();
	Show();

	//kUnit = XComTacticalController(PC).GetActiveUnit();
	UpdateAdjacentUnits();
	
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( kTargetingAction, 'm_kTargetedEnemy', self, UpdateAdjacentUnits);	
}

simulated function Update()
{
	if( XComPresentationLayer(Movie.Pres).m_bAllowEnemyArrowSystem )
		UpdateVisibleEnemies();
}

simulated function UpdateVisibleEnemies()
{
	local XGUnit        kEnemy;
	local vector2D      v2ScreenCoords;
	local vector        vArrow;
	local float         xloc;
	local float         yloc;
	local float         yaw;
	local bool          bIsOnscreen;
	local string        sHelp;
	local array<XGUnit> arrEnemies;
	local bool          bIsInRange; 
	
	local XGUnit        kUnitTarget;

	local AvailableAction       kDisplayedAbility; 
	local AvailableTarget       TargetInfo;
	local XComGameState_Unit    TargetUnitState;

	// Leave if Flash side isn't up.
	if( !bIsInited )
		return;
	
	//Get list of targets for the ability
	if (PC != none && XComTacticalController(PC) != none && XComTacticalController(PC).GetActiveUnit() != None)
	{
		kDisplayedAbility = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetSelectedAction();		
		foreach kDisplayedAbility.AvailableTargets(TargetInfo)
		{
			if( TargetInfo.PrimaryTarget.ObjectID > 0 )
			{
				TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetInfo.PrimaryTarget.ObjectID));
				arrEnemies.AddItem(XGUnit(TargetUnitState.GetVisualizer()));
			}
		}
	}

	//return if no update is needed
	if( arrEnemies.length == 0)
	{
		//delete any dangling arrows
		if( arrCurrent.length != 0)
		{
			//delete all remaining in arrCurrent
			foreach arrCurrent( kEnemy )
			{
				RemoveArrow( string(kEnemy.name) );
			}
		}

		return;
	}

	// look for arrows that need tt be removed
	foreach arrCurrent( kEnemy )
	{
		//old enemy is no longer there
		if( arrEnemies.Find(kEnemy) == -1) 
		{
			//delete from arrCurrent
			RemoveArrow( string(kEnemy.name) );
		}
	}

	foreach arrEnemies( kEnemy )
	{
		// TODO: Determine user unit
		kUnitTarget = none;

		//skip drawing the arrow for the currently targeted alien
		if( kEnemy == kUnitTarget ) 
		{
			//remove the current target's arrow, if it's still floating around.
			if( arrEnemies.Find(kEnemy) != -1 ) 
			{
				//delete from arrCurrent
				RemoveArrow( string(kEnemy.name) );
			}
		}
		else
		{

			if( arrCurrent.Find(kEnemy) == -1 )
			{
				arrCurrent.AddItem(kEnemy);
			}
			
			if( kEnemy == m_kNextTarget )
			{
				if( Movie.IsMouseActive() )
					sHelp = class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_KEY_TAB;
				else 
					sHelp = class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RB_R1;
			}
			else if( kEnemy == m_kPrevTarget )
			{
				if( Movie.IsMouseActive() )
					sHelp = "";
				else
					sHelp = class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LB_L1;
			}
			else
			{
				sHelp = "";
			}

			bIsOnscreen = class'UIUtilities'.static.IsOnscreen( kEnemy.GetPawn().GetHeadshotLocation(), v2ScreenCoords, 0.075 );

			vArrow.x = v2ScreenCoords.x;
			vArrow.y = v2ScreenCoords.y;
			vArrow = Normal( vArrow );

			if( bIsOnscreen ) 
			{
				//set the arrows to vertical, pointing down to the target
				yaw = 180; 
			}
			else
			{
				/**
				To get the degree rotation in 2D:
				- cast the vector to rotator
				- divide by unreal units (65536.0f)
				- multiply by 360 degrees
				- add 90 degrees to align properly
				*/
				yaw = ( rotator(-vArrow).Yaw / 65536.0f ) * 360.0f + 90.0f;
			}
			
			v2ScreenCoords = Movie.ConvertNormalizedScreenCoordsToUICoords(v2ScreenCoords.X, v2ScreenCoords.Y);
			xloc = v2ScreenCoords.X;
			yloc = v2ScreenCoords.Y;

			bIsInRange = true;

			SetArrow( string(kEnemy.name), xloc, yloc - 30, yaw, bIsInRange, sHelp);
		}
	}
}
//Used to identify which units should display the button help for next/prev. 
simulated function UpdateAdjacentUnits()
{
	// TODO:TARGETING
	/*
	local XGUnit kUnit;
	local X2TargetingMethod TargetingMethod;
	local int iIndex;		

	kUnit =  XComTacticalController(PC).GetActiveUnit();
	TargetingMethod = XComTacticalInput(PC.PlayerInput).TargetingMethod;

	iIndex = TargetingMethod.GetTargetIndex();
	if (iIndex >= 0 && iIndex < kTargetingAction.SelectedUIAction.AvailableTargets.Length && iIndex != kTargetingAction.SelectedTargetIndex)
		m_kNextTarget = XGUnit(`XCOMHISTORY.GetVisualizer(kTargetingAction.SelectedUIAction.AvailableTargets[iIndex].PrimaryTarget.ObjectID));
	else
		m_kNextTarget = none;

	iIndex = kTargetingAction.GetIndexOfPrevTarget();
	if (iIndex >= 0 && iIndex < kTargetingAction.SelectedUIAction.AvailableTargets.Length && iIndex != kTargetingAction.SelectedTargetIndex)
		m_kPrevTarget = XGUnit(`XCOMHISTORY.GetVisualizer(kTargetingAction.SelectedUIAction.AvailableTargets[iIndex].PrimaryTarget.ObjectID));
	else
		m_kPrevTarget = none;
	*/
}

// Send individual arrow update information over to flash
simulated function SetArrow( string id, float xloc,  float yloc, float yaw, bool bIsInRange, string sHelp )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( xloc == 0.0 && yloc == 0.0 )
	{
		if( bActive )
		{
			//	`log("??? location is marked at: " @xloc @ yloc);
			RemoveArrow( id );
			bActive = false;
		}
		return;
	}

	bActive = true;

	//`log("=================");
	//`log("??? SetArrow making the update :" @ id @ xloc @ yloc @ yaw);
	//UICache.PrintCache();

	myValue.Type = AS_String;
	myValue.s = id;
	myArray.AddItem( myValue );

	myValue.Type = AS_Number;
	myValue.n = xloc;
	myArray.AddItem( myValue );

	myValue.n = yloc;
	myArray.AddItem( myValue );

	myValue.n = yaw;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
	myValue.b = bIsInRange;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = sHelp;
	myArray.AddItem( myValue );

	Invoke( "SetArrow", myArray );
	myArray.length = 0;
}

simulated function RemoveArrow( string id )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_String;
	myValue.s = id;
	myArray.AddItem( myValue );

	Invoke( "RemoveArrow", myArray );
	myArray.length = 0;

}

//=====================================================================
//		DEFAULTS:
//=====================================================================

defaultproperties
{
	Package = "/ package/gfxEnemyArrows/EnemyArrows";
	MCName = "theArrowContainer";
}
