//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveTeleport extends X2Action_Move;

var vector  Destination;
var float   Distance;
var bool	SnapToGround;

//Path data set from ParsePath. Normally these are set by Move_Begin but the teleport action sequence does not include that action
var private PathingInputData		CurrentMoveData;
var private PathingResultData		CurrentMoveResultData;

var private bool bAllowInterrupt;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	bAllowInterrupt = false;

	Unit.CurrentMoveData = CurrentMoveData;
	Unit.CurrentMoveResultData = CurrentMoveResultData;

	PathTileIndex = FindPathTileIndex();
}

function bool CheckInterrupted()
{
	return bAllowInterrupt;
}

function ResumeFromInterrupt(int HistoryIndex)
{
	super.ResumeFromInterrupt(HistoryIndex);
	bAllowInterrupt = false;
}

function ParsePathSetParameters(int InPathIndex, const out vector InDestination, float InDistance, const out PathingInputData InputData, const out PathingResultData ResultData)
{
	CurrentMoveData = InputData;
	CurrentMoveResultData = ResultData;
	PathIndex = InPathIndex;	
	Destination = InDestination;
	Distance = InDistance;
}

simulated state Executing
{
	//Normally interactive level actors are interacted with via the PlayAnimation movement action. If we are teleporting
	//then we need to just fire off all our associated interactive level actor actions
	function NotifyInteractiveObjects()
	{
		local Actor InteractWithActor;
		local StateObjectReference InteractiveObjectReference;
		local int Index;
		
		for(Index = 0; Index < Unit.CurrentMoveData.MovementData.Length; ++Index)
		{
			if(Unit.CurrentMoveData.MovementData[Index].ActorId.ActorName != '')
			{
				FindActorByIdentifier(Unit.CurrentMoveData.MovementData[Index].ActorId, InteractWithActor);
				if( XComInteractiveLevelActor(InteractWithActor) != none )
				{
//					`Log("MOVETELEPORT::NOTIFYINTERACTIVEOBJECTS-Searching for "$Unit.CurrentMoveData.MovementData[Index].ActorId.ActorName@"..Found"@InteractWithActor@"(#"$XComInteractiveLevelActor(InteractWithActor).ObjectID$")");
					InteractiveObjectReference = `XCOMHISTORY.GetGameStateForObjectID(XComInteractiveLevelActor(InteractWithActor).ObjectID).GetReference();
					if( InteractiveObjectReference.ObjectID > 0 )
					{
						VisualizationMgr.SendInterTrackMessage(InteractiveObjectReference);
					}
				}
			}
		}	
		
	}

	function TeleportNotifyEnvironmentDamage()
	{
		local XComGameState_EnvironmentDamage EnvironmentDamage;	
		local StateObjectReference DmgObjectRef;		

		foreach LastInGameStateChain.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamage)
		{
			if (EnvironmentDamage.DamageCause.ObjectID != Unit.ObjectID)
				continue;

			DmgObjectRef = EnvironmentDamage.GetReference();
			VisualizationMgr.SendInterTrackMessage( DmgObjectRef );
		}
	}

Begin:	
	NotifyInteractiveObjects();
	TeleportNotifyEnvironmentDamage();

	if (SnapToGround)
	{
		Destination.Z = `XWORLD.GetFloorZForPosition(Destination, true) + UnitPawn.CollisionHeight + class'XComWorldData'.const.Cover_BufferDistance;	
	}
	UnitPawn.SetLocation(Destination);		
	Unit.ProcessNewPosition( );

	CompleteAction();	
}

DefaultProperties
{
	SnapToGround = true;
}
