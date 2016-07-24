//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SKULLJACK extends X2Action_Hack;


defaultproperties
{
	Begin Object Name=MeshComp
		StaticMesh=StaticMesh'SKULLJACK.Meshes.SM_Skulljack_Screen'
	end object
	GremlinLCD=MeshComp
		
	ScreenSocketName = "Screen"

	SourceBeginAnim = "FF_SkulljackerStartA"
	SourceLoopAnim = "FF_SkulljackerLoopA"
	SourceEndAnim = "FF_SkulljackerStopA"

	TargetBeginAnim = "FF_SkulljackedStartA"
	TargetLoopAnim = "FF_SkulljackedLoopA"
	TargetEndAnim = "FF_SkulljackedStopA"

	ShouldFixup = true
}

