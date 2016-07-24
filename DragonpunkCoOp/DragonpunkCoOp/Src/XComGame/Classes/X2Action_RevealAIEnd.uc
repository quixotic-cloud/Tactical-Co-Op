class X2Action_RevealAIEnd extends X2Action;

var XComGameStateContext_RevealAI RevealContext;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
	
	RevealContext = XComGameStateContext_RevealAI(StateChangeContext);	
}

function bool CheckInterrupted()
{
	return false;
}

function ResumeFromInterrupt(int HistoryIndex)
{
	`assert(false);
}

simulated state Executing
{
	function UpdateUnitVisuals()
	{
		local int Index;
		local XGUnit Visualizer;

		//Iterate all the unit states that are part of the reflex action state. If they are not the
		//reflexing unit, they are enemy units that must be shown to the player. These vis states will
		//be cleaned up / reset by the visibility observer in subsequent frames
		for(Index = 0; Index < RevealContext.RevealedUnitObjectIDs.Length; ++Index)
		{
			Visualizer = XGUnit(`XCOMHISTORY.GetVisualizer(RevealContext.RevealedUnitObjectIDs[Index]));

			if(Visualizer != none)
			{
				Visualizer.SetForceVisibility(eForceNone);
				Visualizer.GetPawn().UpdatePawnVisibility();
			}
		}
	}

	function ReleaseLookAtCamera()
	{	
		local XGBattle_SP Battle;

		Battle = XGBattle_SP(`BATTLE);
		Battle.GetAIPlayer().SetAssociatedCamera(none);
	}

	function RestoreFOW()
	{
		local XGBattle_SP Battle;

		Battle = XGBattle_SP(`BATTLE);
		if( Battle.GetAIPlayer().FOWViewer != None )
		{
			`XWORLD.DestroyFOWViewer(Battle.GetAIPlayer().FOWViewer);
		}		
	}

Begin:

	RestoreFOW();

	ReleaseLookAtCamera();

	UpdateUnitVisuals();

	CompleteAction();
}

DefaultProperties
{	
}