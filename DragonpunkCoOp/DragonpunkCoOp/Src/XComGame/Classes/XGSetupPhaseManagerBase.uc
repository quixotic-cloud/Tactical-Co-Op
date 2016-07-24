/**
 * Directs the Setup Phase in the Strategy Layer
 */
class XGSetupPhaseManagerBase extends Actor;

//-----------------------------------------------------------
// Data Members
//-----------------------------------------------------------
struct CheckpointRecord
{
	var name m_CurrentState;
};

// Saved Data Members

/** Only relevant for the checkpoint record. */
var name m_CurrentState;

// Kismet event called PhaseManagerEndSequence so that we know the narrative moments are over.
event OnFinishSequence();

simulated function bool AllowedToSave()
{
	return true;
}

// Called before a save
function CreateCheckpointRecord()
{
	if (GetStateName() != 'WaitForHQOnLoad')
		m_CurrentState = GetStateName();
}

// Called after a load
function ApplyCheckpointRecord()
{
	GotoState(m_CurrentState);
}

defaultproperties
{
}