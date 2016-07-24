/**
 * Clears any visibility holds on all pods
 */
class SeqAct_ReleaseAllPodHolds extends SequenceAction;

event Activated()
{
}

defaultproperties
{
	ObjName="Release All Pod Holds"
	ObjCategory="DELETE ME"
	bCallHandler=false
}
