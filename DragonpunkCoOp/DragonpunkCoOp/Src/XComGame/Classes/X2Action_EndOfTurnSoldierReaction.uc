//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_EndOfTurnSoldierReaction extends X2Action
	config(Camera);

enum EndOfTurnReactionType
{
	EndOfTurnReactionType_None,
	EndOfTurnReactionType_Rally,
	EndOfTurnReactionType_Victory,
	EndOfTurnReactionType_Sad,
	EndOfTurnReactionType_Hush,
};

struct EndOfTurnReaction
{
	var EndOfTurnReactionType ReactionType;
	var string MatineePrefix;   // prefix of the matinee to use with this reaction
	var name Animation;         // name of the animation to play when doing the reaction
	var float Weight;           // relative weight for reaction selection. Default is 1, weight of 2 is twice as likely to be picked as weight of 1, etc
	var bool LowCover;          // If true, for use with units that are in low cover

	structdefaultproperties
	{
		Weight=1
	}
};

var private const config array<EndOfTurnReaction> Reactions;

var private X2Camera_Matinee MatineeCamera;
var private AnimNodeSequence PlayingAnim;
var private EndOfTurnReaction ReactionToPlay; 

static function bool AddReactionToBlock(XComGameStateContext_TacticalGameRule Context, out array<VisualizationTrack> VisualizationTracks)
{
	local XComGameState_Player TurnEndingPlayer;
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	local X2Action_EndOfTurnSoldierReaction Action;
	local EndOfTurnReactionType ReactionType;
	local EndOfTurnReaction Reaction;
	local array<XComGameState_Unit> HumanUnits;
	local XComGameState_Unit UnitIterator;
	local XComGameState_Unit SelectedUnit;

	History = `XCOMHistory;

	// Inspect the game state to see what kind of reaction we want him to do
	ReactionType = DetermineReactionType(Context);
	if(ReactionType == EndofTurnReactionType_None) return false;

	// get the player whose turn is ending. 
	TurnEndingPlayer = XComGameState_Player(History.GetGameStateForObjectID(Context.PlayerRef.ObjectID));
	if(TurnEndingPlayer == none || TurnEndingPlayer.GetTeam() != eTeam_Alien) return false;

	// find all living units
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitIterator)
	{
		if(UnitIterator.GetTeam() == eTeam_XCom && UnitIterator.IsAlive() && !SelectedUnit.IsBleedingOut() )
		HumanUnits.AddItem(UnitIterator);
	}
	if(HumanUnits.Length == 0) return false;

	// pick a unit to perform the reaction
	SelectedUnit = HumanUnits[`SYNC_RAND_STATIC(HumanUnits.Length)];

	// Select a reaction for the type we decided on that is valid for the selected unit
	Reaction = SelectReaction(ReactionType, SelectedUnit);
	if(Reaction.ReactionType == EndofTurnReactionType_None) return false;

	// and add the reaction track to the unit
	BuildTrack.StateObject_OldState = SelectedUnit;
	BuildTrack.StateObject_NewState = SelectedUnit;
	BuildTrack.TrackActor = SelectedUnit.GetVisualizer();
	Action = X2Action_EndOfTurnSoldierReaction(class'X2Action_EndOfTurnSoldierReaction'.static.AddToVisualizationTrack(BuildTrack, Context));
	Action.ReactionToPlay = Reaction;
	VisualizationTracks.AddItem(BuildTrack);	

	return true;
}

static private function EndOfTurnReactionType DetermineReactionType(XComGameStateContext_TacticalGameRule InContext)
{
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule RuleContext;
	local XComGameState_Unit UnitIterator;
	local XComGameState_Unit StartOfTurnUnitState;
	local XComGameState_Unit EndOfTurnUnitState;

	// bools to keep track of things that happened this turn
	local bool XComUnitDiedThisTurn;

	History = `XCOMHISTORY;

	// find the start state of the past turn
	foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', RuleContext,, true)
	{
		// Check to see if this the start of the last turn
		if( RuleContext.AssociatedState.HistoryIndex < InContext.AssociatedState.HistoryIndex
			&& RuleContext.GameRuleType == eGameRule_PlayerTurnBegin 
			&& RuleContext.PlayerRef == InContext.PlayerRef)
		{
			break; // we want this one
		}
	}

	// now that we found the start of the turn, check to see if the the units have undergone any
	// state changes that we should react to.
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitIterator)
	{
		StartOfTurnUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitIterator.ObjectID,, RuleContext.AssociatedState.HistoryIndex));
		EndOfTurnUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitIterator.ObjectID,, InContext.AssociatedState.HistoryIndex));

		if(UnitIterator.GetTeam() == eTeam_XCom)
		{
			XComUnitDiedThisTurn = XComUnitDiedThisTurn || (!StartOfTurnUnitState.IsDead() && EndOfTurnUnitState.IsDead());
		}
	}

	if(XComUnitDiedThisTurn)
	{
		return EndOfTurnReactionType_Sad;
	}
	
	return EndOfTurnReactionType_None; // no reaction
}

private static function EndOfTurnReaction SelectReaction(EndOfTurnReactionType ReactionType, XComGameState_Unit UnitState)
{
	local float TotalWeight;
	local EndOfTurnReaction Reaction;
	local EndOfTurnReaction SelectedReaction;
	local bool IsUnitInLowCover;

	TotalWeight = 0;
	IsUnitInLowCover = UnitState.GetCoverTypeFromLocation() == CT_MidLevel;

	foreach default.Reactions(Reaction)
	{
		if(Reaction.ReactionType == ReactionType && IsUnitInLowCover == Reaction.LowCover)
		{
			TotalWeight += Reaction.Weight;
			if(TotalWeight > 0 && (`SYNC_FRAND_STATIC() < (Reaction.Weight / TotalWeight)))
			{
				SelectedReaction = Reaction;
			}
		}
	}
	
	return SelectedReaction;
}

function PlayReaction()
{
	local CustomAnimParams AnimParams;

	AnimParams.AnimName = ReactionToPlay.Animation;
	AnimParams.Looping = false;
	PlayingAnim = Unit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
}

function bool IsTimedOut()
{
	return ExecutingTime >= TimeoutSeconds;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	if( !bNewUnitSelected )
	{
		MatineeCamera = new class'X2Camera_Matinee';
		MatineeCamera.SetMatineeByComment(ReactionToPlay.MatineePrefix, Unit);
		`CAMERASTACK.AddCamera(MatineeCamera);
	}

	// give the camera a moment to settle
	//Sleep(1.5);

	// play the animation and wait for it to finish
	PlayReaction();
	FinishAnim(PlayingAnim);

	// keep the camera looking this way for a few moments
	Sleep(1.0 * GetDelayModifier());

	if( MatineeCamera != None )
	{
		`CAMERASTACK.RemoveCamera(MatineeCamera);
		MatineeCamera = None;
	}

	CompleteAction();
}

event HandleNewUnitSelection()
{
	if( MatineeCamera != None )
	{
		`CAMERASTACK.RemoveCamera(MatineeCamera);
		MatineeCamera = None;
	}
}

defaultproperties
{
	TimeoutSeconds = 10.0
}

