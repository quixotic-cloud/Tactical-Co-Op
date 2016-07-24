//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_TradingPost.uc
//  AUTHOR:  Mark Nauta  --  08/21/2014
//  PURPOSE: This object represents the instance data for the Trading Posts on the 
//           X-Com 2 strategy game map
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_TradingPost extends XComGameState_GeoscapeEntity native(Core);

// State vars
var() int                     SupplyReserve;
var() X2ItemTemplate          SpecialDemandItem;
var() TDateTime               SupplyStartTime;
var() TDateTime               MaxSupplyTime;

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function SetUpTradingPosts(XComGameState StartState)
{

}


//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_TradingPost';
}

function string GetUIWidgetFlashLibraryName()
{
	return "MI_outpost";
}

function string GetUIPinImagePath()
{
	return "img:///UILibrary_StrategyImages.X2StrategyMap.MapPin_Resistance";
}

function bool ShouldBeVisible()
{
	return false;
}


function DestinationReached()
{

}

function OpenMarket()
{

}

// After closing the trading screen, send the Skyranger home
function FinishedShopping()
{
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}