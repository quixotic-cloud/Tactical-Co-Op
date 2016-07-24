class X2Action_RevealAIBegin extends X2Action_PlayMatinee
	config(Camera);

// How long to pause after kicking off the first sighted NM before continuing with the reveal
var const config float FirstSightedDelay;

var XComGameStateContext_RevealAI RevealContext;
var float RevealFOWRadius;  //A radius in units for how much FOW should be revealed

var private XGUnit MatineeFocusUnitVisualizer;              //Visualizer of the target of the cinematic
var private XComGameState_Unit MatineeFocusUnitState;

var private X2CharacterTemplate MatineeFocusUnitTemplate;	//Character template of the character being revealed
var private XGUnit EnemyUnitVisualizer;                     //The enemy that caused this reveal to happen
var private AnimNodeSequence PointAnim;
var private array<XComUnitPawn> RevealedUnitVisualizers;
var private XComUnitPawn FocusUnitPawn;
var private int FocusUnitIndex;
var private X2Camera_MidpointTimed InitialLookAtCam;

var localized string SurprisedText;

function Init(const out VisualizationTrack InTrack)
{	
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local X2CharacterTemplate FirstRevealTemplate;
	local XGUnit UnitActor;
	local int Index;

	super.Init(InTrack);
	
	RevealContext = XComGameStateContext_RevealAI(StateChangeContext);	

	History = `XCOMHISTORY;

	FirstRevealTemplate = RevealContext.FirstEncounterCharacterTemplate;

	//First make sure that there are units to be revealed
	if(RevealContext.RevealedUnitObjectIDs.Length > 0)
	{		
		for(Index = 0; Index < RevealContext.RevealedUnitObjectIDs.Length; ++Index)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RevealContext.RevealedUnitObjectIDs[Index], eReturnType_Reference, RevealContext.AssociatedState.HistoryIndex));
			if( UnitState.IsAbleToAct() ) //Only focus on still living enemies
			{
				UnitActor = XGUnit(History.GetVisualizer(UnitState.ObjectID));
				if(MatineeFocusUnitVisualizer == none 
					|| (FirstRevealTemplate != none && FirstRevealTemplate.DataName != MatineeFocusUnitVisualizer.GetVisualizedGameState().GetMyTemplateName()))
				{
					// If this is a first encounter, then favor playing the reveal on a unit of that template type. Otherwise 
					// take the first one available. Since the pod leader is always at index 0, this will focus him if possible.
					MatineeFocusUnitVisualizer = UnitActor;		
					MatineeFocusUnitState = UnitState;
				}

				RevealedUnitVisualizers.AddItem(UnitActor.GetPawn());
			}
		}

		//We can still end up with an empty RevealedUnitVisualizers if the player killed this entire group with AOE or something before the reveal could take place, so account for that 
	}
	else
	{
		`redscreen("Attempted to plan AI reveal action with no AIs!");
	}
	
	EnemyUnitVisualizer = XGUnit(History.GetVisualizer(RevealContext.CausedRevealUnit_ObjectID));
}

function bool CheckInterrupted()
{
	return false;
}

function ResumeFromInterrupt(int HistoryIndex)
{
	`assert(false);
}

function ResetTimeDilation()
{
	local int Index;
	local X2VisualizerInterface VisualizerInterface;

	for (Index = 0; Index < RevealedUnitVisualizers.Length; Index++)
	{
		VisualizerInterface = X2VisualizerInterface(RevealedUnitVisualizers[Index].GetGameUnit());
		if (VisualizerInterface != None)
		{
			VisualizerInterface.SetTimeDilation(1.0f);
		}
	}
}

function vector GetLookatLocation()
{
	return MatineeFocusUnitVisualizer.GetPawn().GetFeetLocation();
}	

function ShowSurprisedFlyover()
{
	local XGUnitNativeBase Scamperer;
	local XComGameState_Unit ScampererUnitState;
	local int SurprisedUnitID;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach RevealContext.SurprisedScamperUnitIDs(SurprisedUnitID)
	{
		Scamperer = XGUnitNativeBase(History.GetVisualizer(SurprisedUnitID));

		//The surprised unit may have been killed already in blocks visualized earlier.
		ScampererUnitState = XComGameState_Unit(History.GetGameStateForObjectID(SurprisedUnitID, eReturnType_Reference, CurrentHistoryIndex));
		if (ScampererUnitState != None && Scamperer != None && ScampererUnitState.IsAlive() && !ScampererUnitState.IsIncapacitated())
			`PRES.GetWorldMessenger().Message(SurprisedText, Scamperer.GetLocation(), Scamperer.GetVisualizedStateReference(), eColor_Alien, , , Scamperer.m_eTeamVisibilityFlags, , , , class'XComUIBroadcastWorldMessage_UnexpandedLocalizedString');
	}
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
		for( Index = 0; Index < RevealContext.RevealedUnitObjectIDs.Length; ++Index )
		{
			Visualizer = XGUnit(`XCOMHISTORY.GetVisualizer(RevealContext.RevealedUnitObjectIDs[Index]));

			if( Visualizer != none )
			{
				Visualizer.SetForceVisibility(eForceVisible);
				Visualizer.GetPawn().UpdatePawnVisibility();
			}
		}
	}

	function RequestInitialLookAtCamera()
	{			
		local XComUnitPawn FocusActor;
		
		InitialLookAtCam = new class'X2Camera_MidpointTimed';
		foreach RevealedUnitVisualizers(FocusActor)
		{
			InitialLookAtCam.AddFocusActor(FocusActor);
		}
		InitialLookAtCam.Priority = eCameraPriority_CharacterMovementAndFraming;
		InitialLookAtCam.LookAtDuration = 100.0f; // we'll manually pop it
		InitialLookAtCam.UpdateWhenInactive = true;
		`CAMERASTACK.AddCamera(InitialLookAtCam);
	}

	function RequestLookAtCamera()
	{	
		local XComGameStateHistory History;
		local XComGameState_Unit UnitState;
		local X2Camera_MidpointTimed LookAtCam;
		local XGBattle_SP Battle;
		local XComUnitPawn FocusActor;
		local XGUnit FocusUnit;			
		local Vector MoveToPoint;

		History = `XCOMHISTORY;

		LookAtCam = new class'X2Camera_MidpointTimed';
		foreach RevealedUnitVisualizers(FocusActor)
		{
			//Add the destination points for the moving AIs to the look at camera, as well as their current locations
			FocusUnit = XGUnit(FocusActor.GetGameUnit());
			if(FocusUnit != none)
			{
				LookAtCam.AddFocusPoint(FocusActor.Location);
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(FocusUnit.ObjectID));
				MoveToPoint = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);
				LookAtCam.AddFocusPoint(MoveToPoint);
			}
		}
		LookAtCam.LookAtDuration = 10.0f; //This camera will be manually removed in the end reveal
		LookAtCam.Priority = eCameraPriority_CharacterMovementAndFraming;
		LookAtCam.UpdateWhenInactive = true;
		`CAMERASTACK.AddCamera(LookAtCam);

		Battle = XGBattle_SP(`BATTLE);
		Battle.GetAIPlayer().SetAssociatedCamera(LookAtCam);
	}

	function bool HasLookAtCameraArrived()
	{
		local X2Camera_MidpointTimed LookAtCam;
		local XGBattle_SP Battle;		

		Battle = XGBattle_SP(`BATTLE);
		LookAtCam = X2Camera_MidpointTimed(Battle.GetAIPlayer().AssociatedCamera);

		return LookAtCam == none || LookAtCam.HasArrived;
	}

	function FaceRevealUnitsTowardsEnemy()
	{
		local Vector FaceVector;

		foreach RevealedUnitVisualizers(FocusUnitPawn)
		{

			FaceVector = EnemyUnitVisualizer.GetLocation() - FocusUnitPawn.Location;
			FaceVector.Z = 0;
			FaceVector = Normal(FaceVector);

			FocusUnitPawn.m_kGameUnit.IdleStateMachine.ForceHeading(FaceVector);
		}
	}

	private function bool ShouldPlayLookatCamera()
	{
		local XComGameStateHistory History;
		local XComGameStateContext_CinematicSpawn CinematicContext;
		local XComGameState_Unit UnitState;

		History = `XCOMHISTORY;

		// if this unit was cinematically spawned, then we don't need to do another reveal animation
		foreach History.IterateContextsByClassType(class'XComGameStateContext_CinematicSpawn', CinematicContext,, true)
		{
			foreach CinematicContext.AssociatedState.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				if(UnitState.ObjectID == MatineeFocusUnitState.ObjectID)
				{
					return false;
				}
			}
		}

		return true;
	}

	function bool ShouldPlayRevealMatinee()
	{
		local XComGameStateHistory History;
		local XComGameStateContext_ChangeContainer Context;
		local XComGameState_AIReinforcementSpawner SpawnState;
		local XComGameState_AIUnitData AIUnitData;
		local UnitValue ImmobilizeValue;

		// not if glam cams are turned off in the options screen
		if(!`Battle.ProfileSettingsGlamCam())
		{
			return false;
		}

		if(!ShouldPlayLookatCamera())
		{
			return false;
		}

		// not if the reveal focus unit is currently immobilized
		if(MatineeFocusUnitState.GetUnitValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, ImmobilizeValue))
		{
			if(ImmobilizeValue.fValue != 0)
			{
				return false;
			}
		}

		History = `XCOMHISTORY;

		// Determine if this reveal is happening immediately after a spawn. If so, then we don't want to play a further
		// reveal matinee. The spawn animations are considered the reveal matinee in this case.
		foreach History.IterateContextsByClassType(class'XComGameStateContext_ChangeContainer', Context,, true)
		{
			if(Context.AssociatedState.HistoryIndex <= RevealContext.AssociatedState.HistoryIndex // only look in the past
				&& Context.EventChainStartIndex == RevealContext.EventChainStartIndex // only within this chain of action
				&& Context.ChangeInfo == class'XComGameState_AIReinforcementSpawner'.default.SpawnReinforcementsCompleteChangeDesc)
			{
				// check if this change spawned our units
				foreach Context.AssociatedState.IterateByClassType(class'XComGameState_AIUnitData', AIUnitData)
				{
					if(RevealContext.RevealedUnitObjectIDs.Find(AIUnitData.m_iUnitObjectID) != INDEX_NONE)
					{
						foreach Context.AssociatedState.IterateByClassType(class'XComGameState_AIReinforcementSpawner', SpawnState)
						{
							// allow reveals for psi gates
							return SpawnState.UsingPsiGates;
						}

						// no reinforcement game state, so just allow it by default
						return true;
					}
				}
			}

			// we are iterating into the past, so abort as soon as we pass the start of our event chain
			if(Context.AssociatedState.HistoryIndex < RevealContext.EventChainStartIndex)
			{
				break;
			}
		}

		return true;
	}

	function SelectAndPlayMatinee()
	{											
		local X2Camera_Matinee MatineeSelectingCamera;
		local name MatineeBaseName;
		local string MatineePrefix;
		local X2CharacterTemplate Template;
		local Rotator MatineeOrientation;
		local Object MapPackage;
		
		Template = MatineeFocusUnitState.GetMyTemplate();
	
		if(Template.GetRevealMatineePrefixFn != none)
		{
			// function takes priority over specified matinee prefix
			MatineePrefix = Template.GetRevealMatineePrefixFn(MatineeFocusUnitState);
		}
		else if(Template.RevealMatineePrefix != "")
		{
			// we have a matinee prefix specified, use that
			MatineePrefix = Template.RevealMatineePrefix;
		}
		else
		{
			// if no explicit matinee prefix specified, just use the first package name as a default
			MatineePrefix = Template.strMatineePackages[0];
		}
		
		// add a camera for the cam matinee
		MatineeSelectingCamera = new class'X2Camera_MatineePodReveal';

		if(!MatineeSelectingCamera.SetMatineeByComment(MatineePrefix $ "_Reveal", MatineeFocusUnitVisualizer, true))
		{
			return;
		}

		Matinees.AddItem(MatineeSelectingCamera.MatineeInfo.Matinee);

		// find the base for the selected matinee. By convention, it's the package name with "_Base" appended to it
		MapPackage = MatineeSelectingCamera.MatineeInfo.Matinee.Outer;
		while(MapPackage.Outer != none) // the map will be the outermost (GetOutermost() is not script accessible)
		{
			MapPackage = MapPackage.Outer;
		}
		MatineeBaseName = name(string(MapPackage.Name) $ "_Base");
		SetMatineeBase(MatineeBaseName);

		// while the reveal unit *should* be facing XCom by now, to be super robust, orient the matinee towards XCom explicitly
		MatineeOrientation = Rotator(EnemyUnitVisualizer.GetLocation() - MatineeFocusUnitVisualizer.GetLocation());
		MatineeOrientation.Pitch = 0;
		MatineeOrientation.Roll = 0;
		SetMatineeLocation(MatineeFocusUnitVisualizer.GetPawn().GetFeetLocation(), MatineeOrientation);

		AddUnitToMatinee('Char1', MatineeFocusUnitState);
		PlayMatinee();
	}

	function DoSoldierVOForSpottingUnit()
	{
		local int Index;
		local XComGameStateHistory History;
		local XComGameState_Unit UnitState;
		local bool bAdvent;

		History = `XCOMHISTORY;

		for (Index = 0; Index < RevealContext.RevealedUnitObjectIDs.Length; ++Index)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RevealContext.RevealedUnitObjectIDs[Index], eReturnType_Reference, RevealContext.AssociatedState.HistoryIndex));
			if (UnitState.IsAdvent() && !UnitState.GetMyTemplate().bIsTurret)
			{
				bAdvent = true;
				break;
			}
		}

		if (bAdvent)
		{
			EnemyUnitVisualizer.UnitSpeak('ADVENTsighting');
		}
	}

Begin:

	if( RevealedUnitVisualizers.Length > 0 )
	{
		// Ensure that revealed units have time dilation reset, necessary when they are moving and are revealed as a result of seeing you.
		ResetTimeDilation();

		//Clear the FOW around the alerted enemies	
		UpdateUnitVisuals();
		`Pres.m_kUIMouseCursor.HideMouseCursor();

		//Instruct the enemies to face towards the enemy that encountered them
		FaceRevealUnitsTowardsEnemy();

		//Pan over to the revealing AI group
		if( !bNewUnitSelected && ShouldPlayLookatCamera() )
		{
			RequestInitialLookAtCamera();
		}

		if( RevealContext.FirstSightingMoment == none && RevealContext.bDoSoldierVO )
		{
			// We only do soldier VO if we arent doing first sighting narrative
			DoSoldierVOForSpottingUnit();
		}

		// wait for he camera to get over there
		while( InitialLookAtCam != None && !InitialLookAtCam.HasArrived && InitialLookAtCam.IsLookAtValid() )
		{
			Sleep(0.0f);
		}

		// do the normal framing delay so it's consistent with the flow of ability activation
		Sleep(class'X2Action_CameraFrameAbility'.default.FrameDuration * GetDelayModifier());

		// Wait for the reveal units to finish turning. They should already be done due to the camera movement and
		// delay, but just in case
		for( FocusUnitIndex = 0; FocusUnitIndex < RevealedUnitVisualizers.Length; ++FocusUnitIndex )
		{
			FocusUnitPawn = RevealedUnitVisualizers[FocusUnitIndex];

			while( FocusUnitPawn.m_kGameUnit.IdleStateMachine.IsEvaluatingStance() )
			{
				Sleep(0.0f);
			}

			// Jwats: Some Units are locked down after the pod idle to prevent turning
			FocusUnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		}

		//Select and play a reveal matinee, wait for it to finish
		if( ShouldPlayRevealMatinee() )
		{
			SelectAndPlayMatinee();

			// the base class will modify the timeout after starting the matinee to be the same length as the matinee. So we need
			// to put the timeout back here, since we will be doing other things afterwards
			TimeoutSeconds += default.TimeoutSeconds;

			while( Matinees.Length > 0 )
			{
				Sleep(0.0f);
			}

			EndMatinee();
		}

		if( RevealContext.SurprisedScamperUnitIDs.Length > 0 )
		{
			ShowSurprisedFlyover();
		}

		if( RevealContext.FirstSightingMoment != none )
		{
			`PRESBASE.UINarrative(RevealContext.FirstSightingMoment);
			Sleep(FirstSightedDelay * GetDelayModifier());
		}

		//Play a narrative moment for sighting this type of enemy
		// 	if( MatineeFocusUnitTemplate != None )
		// 	{
		// 		`PRES.DoNarrativeByCharacterTemplate(MatineeFocusUnitTemplate);
		// 	}

		// Don't remove this camera until after the matinee is done, sometimes the matinee camera finishes before 
		// the matinee animation and we want to ensure we don't go to the look at cursor camera
		if( InitialLookAtCam != None )
		{
			`CAMERASTACK.RemoveCamera(InitialLookAtCam);
			InitialLookAtCam = None;
		}

		// Create a lookat camera for the AI moves that will frame their current locations as well as all their destinations.
		// The initial lookat camera only did their origin locations, which is why we need a new camera.
		if( !bNewUnitSelected )
		{
			RequestLookAtCamera();
			while( !HasLookAtCameraArrived() )
			{
				Sleep(0.0f);
			}
		}
	}

	CompleteAction();
}

function CompleteAction()
{
	super.CompleteAction();

	// if we are stopped for whatever reason before the action can finish normally, 
	// make sure the initial lookup cam gets removed
	if( InitialLookAtCam != None )
	{
		`CAMERASTACK.RemoveCamera(InitialLookAtCam);
		InitialLookAtCam = None;
	}
}

event HandleNewUnitSelection()
{
	if( InitialLookAtCam != None )
	{
		`CAMERASTACK.RemoveCamera(InitialLookAtCam);
		InitialLookAtCam = None;
	}
}

DefaultProperties
{	
	RevealFOWRadius = 768.0; //8 tiles
}
