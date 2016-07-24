//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2AmbientNarrativeCriteriaTemplate.uc
//  AUTHOR:  Brian Whitman --  7/28/2015
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2AmbientNarrativeCriteriaTemplate extends X2DataTemplate 
	native(Core);

simulated function bool IsAmbientPlayCriteriaMet(XComNarrativeMoment MomentContext)
{
	local XComHQPresentationLayer HQPresLayer;
	local float CurrentTime;

	HQPresLayer = `HQPRES;

	if( MomentContext.AmbientMaxPlayCount > 0 && HQPresLayer.GetTimesPlayed(MomentContext) >= MomentContext.AmbientMaxPlayCount )
		return false;

	CurrentTime = class'WorldInfo'.static.GetWorldInfo().TimeSeconds;
	if( MomentContext.AmbientMaxPlayFrequency > 0 && MomentContext.LastAmbientPlayTime > 0 && (MomentContext.LastAmbientPlayTime + MomentContext.AmbientMaxPlayFrequency) > CurrentTime )
		return false;

	if( MomentContext.AmbientMinDelaySinceLastNarrativeVO > 0 && (HQPresLayer.m_kNarrativeUIMgr.GetLastVOTime() + MomentContext.AmbientMinDelaySinceLastNarrativeVO) > CurrentTime )
		return false;
	
	return true;
}