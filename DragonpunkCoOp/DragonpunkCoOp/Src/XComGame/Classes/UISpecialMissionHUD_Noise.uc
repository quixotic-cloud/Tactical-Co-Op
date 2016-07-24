//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISpecialMissionHUD_Noise.uc
//  AUTHORS: Brit Steiner
//
//  PURPOSE: Container for edge of screen noise indicators.  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISpecialMissionHUD_Noise extends UIPanel;

struct UINoiseIndicator
{
	var string		id;
	var vector      loc;
	var int         indicatorCounter;
	structdefaultproperties
	{
		indicatorCounter = -1;
	}
};

var array<UINoiseIndicator>	arrNoiseIndicators;

//=====================================================================
// 		GENERAL FUNCTIONS:
//=====================================================================

// Pseudo-Ctor
simulated function UISpecialMissionHUD_Noise InitNoise()
{
	InitPanel();
	return self;
}

simulated function OnInit()
{
	super.OnInit();
	Show();
	XComPresentationLayer(screen.Owner).SubscribeToUIUpdate( Update );
}

simulated function string GetIdFromLocation(vector loc)
{
	return int(loc.x) $ "_" $ int(loc.y) $ "_" $ int(loc.z);
}

// Adds a new indicator pointing at a location, or updates it if it already exists
// distanceAlpha goes from [0.0, 1.0]. 0.0 is the nearest (and largest) the indicator can be
// 1.0 is farthest and smallest.
simulated function AddNoiseIndicatorPointingAtLocation( vector loc, optional float distanceAlpha = 0.0, optional int indicatorCount = -1 )
{
	local int index;
	local UINoiseIndicator actorIndicator; 

	index = arrNoiseIndicators.Find('loc', loc);
	if(index != -1)
	{
		// Update data on indicator
		arrNoiseIndicators[index].indicatorCounter = indicatorCount;
	}
	else
	{
		actorIndicator.id = GetIdFromLocation(loc);
		actorIndicator.loc = loc;
		actorIndicator.indicatorCounter = ++indicatorCount;
		arrNoiseIndicators.AddItem( actorIndicator );
	}
}

simulated function RemoveindicatorPointingAtLocation( vector loc )
{
	local int index; 
	
	index = arrNoiseIndicators.Find('loc', loc);

	if( index != -1) 
	{
		//delete from arrTargetedindicators
		RemoveIndicator( GetIdFromLocation(loc) );
		arrNoiseIndicators.Remove( index, 1 );
	}
}

simulated function Update()
{
	UpdateTargetedIndicators();
}

simulated function UpdateTargetedIndicators()
{
	local UINoiseIndicator kTarget;
	local vector        targetLocation;
	local vector2D      v2ScreenCoords;
	local int           iConsoleSafeframeBuffer; 

	// Leave if Flash side isn't up.
	if( !bIsInited )
		return;
	
	//return if no update is needed
	if( arrNoiseIndicators.length == 0)
	{
		return;
	}

	foreach arrNoiseIndicators( kTarget )
	{
		targetLocation = kTarget.loc;

		class'UIUtilities'.static.IsOnscreen( targetLocation, v2ScreenCoords, 0.075 );

		v2ScreenCoords = Movie.ConvertNormalizedScreenCoordsToUICoords(v2ScreenCoords.X, v2ScreenCoords.Y);

		iConsoleSafeframeBuffer = 58; 

		if( v2ScreenCoords.y < iConsoleSafeframeBuffer ) 
			v2ScreenCoords.y = iConsoleSafeframeBuffer;
		else if( v2ScreenCoords.y > Movie.m_v2ScaledDimension.Y - iConsoleSafeframeBuffer ) 
			v2ScreenCoords.y = Movie.m_v2ScaledDimension.Y - iConsoleSafeframeBuffer;


		if( v2ScreenCoords.x < iConsoleSafeframeBuffer ) 
			v2ScreenCoords.x = iConsoleSafeframeBuffer;
		else if( v2ScreenCoords.x > Movie.m_v2ScaledDimension.X - iConsoleSafeframeBuffer ) 
			v2ScreenCoords.x = Movie.m_v2ScaledDimension.X - iConsoleSafeframeBuffer;

		SetIndicator( GetIdFromLocation(targetLocation), v2ScreenCoords.x, v2ScreenCoords.y);
	}
}

// Send individual Indicator update information over to flash
simulated function SetIndicator( string id, float xloc,  float yloc )
{
	Movie.ActionScriptVoid(MCPath$".SetIndicator");
}

simulated function OnCommand( string cmd, string arg )
{
	//local int index;
	return; // turning off animation-triggered removal 
	/*
	if( cmd == "AnimationComplete" )
	{
		index = arrNoiseIndicators.Find('id',arg );

		if( index != -1) 
		{
			//delete from arrTargetedindicators
			RemoveIndicator( arg );
			arrNoiseIndicators.Remove( index, 1 );
		}
	}*/
}
simulated function RemoveIndicator( string id )
{
	Movie.ActionScriptVoid(MCPath$".RemoveIndicator");
}

simulated function int GetNumIndicators()
{
	return arrNoiseIndicators.Length;
}

event Destroyed()
{
	Movie.Pres.UnsubscribeToUIUpdate( Update );
	super.Destroyed();
}

//=====================================================================
//		DEFAULTS:
//=====================================================================

defaultproperties
{
	MCName      = "noiseIndicatorContainer";
	bAnimateOnInit = false;
}
