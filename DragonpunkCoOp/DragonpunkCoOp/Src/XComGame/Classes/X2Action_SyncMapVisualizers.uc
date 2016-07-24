//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SyncMapVisualizers extends X2Action;

var bool Syncing;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function bool CheckInterrupted()
{
	return false;
}

function SyncVisualizer()
{
	if (!Syncing)
	{
		//This sequence of events should be replace with something more sane. For now we are just making it work...
		`BATTLE.InitLevel();
		`BATTLE.m_kLevel.Init();
		`BATTLE.m_kLevel.OnStreamingFinished();
		`BATTLE.m_kLevel.SetupXComVis();
		`BATTLE.m_kLevel.LoadInit();

		`BATTLE.InitDescription();
	}

	`XWORLD.SyncVisualizers(StateChangeContext.AssociatedState.HistoryIndex);

	if (!Syncing)
	{
		`TACTICALMISSIONMGR.HideOSPActors();
	}
}

simulated state Executing
{
Begin:
	SyncVisualizer();    

	CompleteAction();
}

DefaultProperties
{
	Syncing = false;
}
