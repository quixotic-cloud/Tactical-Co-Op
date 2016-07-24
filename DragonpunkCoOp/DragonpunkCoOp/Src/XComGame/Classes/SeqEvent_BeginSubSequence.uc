/**
 * Sent when a Sub Sequence has been enabled by a Directed Tactical
 * Experience. May be used as the entry point for this Sub Sequence.
 */
class SeqEvent_BeginSubSequence extends SequenceEvent
	native(Level);

defaultproperties
{
	ObjName="Begin DTE Sequence"
	ObjCategory="Tutorial"
	bPlayerOnly=FALSE;
}
