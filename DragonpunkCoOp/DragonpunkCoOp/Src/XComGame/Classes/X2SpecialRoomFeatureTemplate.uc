//---------------------------------------------------------------------------------------
//  FILE:    X2SpecialRoomFeatureTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2SpecialRoomFeatureTemplate extends X2StrategyElementTemplate;

// Text
var localized string		  UnclearedDisplayName;
var localized string		  ClearedDisplayName;
var localized string		  ClearText;
var localized string		  ClearingInProgressText;
var localized string		  ClearingCompletedText;
var localized string		  ClearingHaltedText;
var localized string		  TooltipText;

// Map Data
var array<string>			  UnclearedMapNames;
var array<string>			  ClearedMapNames;
var string					  UnclearedLightingMapName_Pristine;
var string					  UnclearedLightingMapName_Damaged;
var string					  UnclearedLightingMapName_Disabled;
var string					  ClearedLightingMapName_Pristine;
var string					  ClearedLightingMapName_Damaged;
var string					  ClearedLightingMapName_Disabled;
var string					  strImage; // UI image for the special room feature

var array<StrategyNames>	  LootCarrierNames;
var config int				  PointsToComplete;
var int						  LowestRowAllowed; // The minimum Avenger grid row this feature is allowed to be placed on. Start at 1, not 0 to allow for default value of 0 when not specified.
var int						  HighestRowAllowed; // The maximum Avenger grid row this feature is allowed to be placed on. Start at 1, not 0 to allow for default value of 0 when not specified.
var config int				  MinTotalAllowed; // The minimum number of times this feature should appear in the Avenger
var config int				  MaxTotalAllowed; // The maximum number of times this feature should appear in the Avenger
var array<int>				  ExclusiveRoomIndices; // Only one of this special feature type is allowed among these room indices
var config int				  CostIncreasePerDepth; // The amount the cost of clearing this special feature will increase per depth level past its lowest allowed row
var bool					  bRemoveOnClear;
var bool					  bHasLoot;
var bool					  bBlocksConstruction;
var bool					  bAddsBuildSlot; // If this feature adds an additional build slot to the room
var bool					  bFillAvenger;
var string					  StartProjectAkEvent;
var string					  RoomAmbientAkEvent;

// Requirements and Cost
var StrategyRequirement Requirements;
var StrategyCost		Cost;

var Delegate<GetDepthBasedLootTableNameDelegate> GetDepthBasedLootTableNameFn;
var Delegate<GetDepthBasedNumBuildSlotsDelegate> GetDepthBasedNumBuildSlotsFn;
var Delegate<GetDepthBasedCostDelegate> GetDepthBasedCostFn;
var Delegate<OnClearDelegate> OnClearFn;

delegate name GetDepthBasedLootTableNameDelegate(XComGameState_HeadquartersRoom RoomState);
delegate int GetDepthBasedNumBuildSlotsDelegate(XComGameState_HeadquartersRoom RoomState);
delegate StrategyCost GetDepthBasedCostDelegate(XComGameState_HeadquartersRoom RoomState);
delegate OnClearDelegate(XComGameState NewGameState, XComGameState_HeadquartersRoom RoomState);

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bShouldCreateDifficultyVariants = true
}