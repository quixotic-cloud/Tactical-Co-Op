//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_InitFOW extends X2Action;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function bool CheckInterrupted()
{
	return false;
}

function InitFOW()
{
	//RAM - the interface for the world data could perhaps be simpler...

	`XWORLD.bEnableFOW = true; // JMS - always start out with FOW on
	`XWORLD.bDebugEnableFOW = true;
	`XWORLD.bEnableFOWUpdate = true;
	`BATTLE.m_kLevel.SetupXComFOW(true);	
	`XWORLD.bFOWTextureBufferIsDirty = true;// Make the FOW Texture update as sometimes the client doesn't catch that it's units have moved
	`XWORLD.bDisableVisibilityUpdates = false;
}

simulated state Executing
{
Begin:
	InitFOW();

	CompleteAction();
}

DefaultProperties
{
}
