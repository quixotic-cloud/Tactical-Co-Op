class XComGameStateContext_ArchiveHistory extends XComGameStateContext native(Core);

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	// this class is not used to build a game state, the history handles it internally
	`assert(false);
	return none;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	//No visualization
}

function string SummaryString()
{
	return "XComGameStateContext_ArchiveHistory";
}

defaultproperties
{
	bVisualizationOrderIndependent=true
}