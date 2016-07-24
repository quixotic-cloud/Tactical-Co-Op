//---------------------------------------------------------------------------------------
//  FILE:    X2Action_UpdateScanningProtocolOutline.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_UpdateScanningProtocolOutline extends X2Action;

var bool bEnableOutline;

simulated state Executing
{
Begin:
	UnitPawn.bScanningProtocolOutline = bEnableOutline;
	UnitPawn.MarkAuxParametersAsDirty(UnitPawn.m_bAuxParamNeedsPrimary,UnitPawn.m_bAuxParamNeedsSecondary,UnitPawn.m_bAuxParamUse3POutline);

	CompleteAction();
}