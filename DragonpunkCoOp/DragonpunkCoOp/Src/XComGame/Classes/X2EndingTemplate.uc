//---------------------------------------------------------------------------------------
//  FILE:    X2EndingTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2EndingTemplate extends X2StrategyElementTemplate
	dependson(X2StrategyGameRulesetDataStructures, XGNarrative);

// ID Mission
var() EndingMissionData				IDMissionData;
var() XComNarrativeMoment			IDAvailableComm;

// TentPole 1
var() XComNarrativeMoment			TentPole1Cinematic;
var() array<EndingMissionData>		TentPole1MissionsData;

// TentPole 2
var() XComNarrativeMoment			TentPole2Cinematic;
var() array<EndingMissionData>		TentPole2MissionsData;

// TentPole 3
var() XComNarrativeMoment			TentPole3Cinematic;

// Final Mission
var() name							WinObjective;
var() EndingMissionData				FinalMissionData;
var() XComNarrativeMoment			FinalMissionAvailableComm;
var() string						VictoryCinematic; // data type string for now, may change
var() string						FailureCinematic; // data type string for now, may change

// Ambient VO
var() array<AmbientEndingComm>		AmbientComms;

// Nag VO
var() NagComm						IDNagComm; // Nag for waiting too long to do ID Mission
var() NagComm						CoupletAvailableNagComm; // Nag for waiting too long with both couplet missions available
var() NagComm						CoupletHalfDoneNagComm; // Nag for waiting too long with one couplet mission remaining
var() NagComm						ResearchNagComm; // Nag for waiting too long to do research on a priority tech
var() NagComm						EngineeringNagComm; // Nag for waiting too long to do a priority engineering project
var() NagComm						POINagComm; // Nag for waiting too long on visiting a priority POI

//---------------------------------------------------------------------------------------
DefaultProperties
{
}