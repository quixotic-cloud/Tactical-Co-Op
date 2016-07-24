//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_IntrusionProtocol extends X2Action_Hack;

//------------------------------------------------------------------------------------------------

defaultproperties
{
	DelayAfterHackCompletes=2.0
	ScreenSocketName = "LCD_Panel"

	SourceBeginAnim = "NO_HackIntrusionProtocol_StartA"
	SourceLoopAnim = "NO_HackIntrusionProtocol_LoopA"
	SourceEndAnim = "NO_HackIntrusionProtocol_StopA"

	TargetBeginAnim = ""
	TargetLoopAnim = ""
	TargetEndAnim = ""
}
