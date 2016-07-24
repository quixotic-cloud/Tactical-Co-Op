//---------------------------------------------------------------------------------------
//  FILE:    X2Action.uc
//  AUTHOR:  Ryan McFall  --  11/16/2013
//  PURPOSE: Used by the visualizer system to control a Visualization Actor. This class
//           is the base class from which all other X2Action classes should derive and
//           holds basic information, helper methods, pure virtual methods for message
//           handling, and static methods to help with the creation of new X2Action actors
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action extends Actor abstract native(Core) dependson(XComGameStateVisualizationMgr, XComGameStateContext);

var privatewrite bool                            bCompleted;         //If this flag is set to true, it indicates to the visualizer that the action is done
var protectedwrite XComGameStateContext     StateChangeContext; //This context is set by the code creating this action. Can be set to anything, but most
																//often will point to the game state that this action is showing.
var protectedwrite int						CurrentHistoryIndex;//Cached history index from StateChangeContext. To get the history index of the vis block
																//this action is part of, it can be found in the VisualizationTrack
var protected XComGameStateContext_Ability  VisualizationBlockContext;  //Points to the context that this action is a part of when Init is called ( ie. when this action starts running ).
var protectedwrite VisualizationTrack       Track;              //Track data for the track we are a part of
var protectedwrite float                    ExecutingTime;      //Keeps track of the time that this action has been in the 'Executing' state
var protectedwrite float                    TimeoutSeconds;     //Expected run-time of the action
var protectedwrite bool						bInterrupted;		//TRUE if this X2Action is currently interrupted

var private bool							bForceImmediateTimeout;
var protected bool							bNewUnitSelected;

var protected XGUnit						Unit;
var protected XComUnitPawn					UnitPawn;

var protected XComGameStateVisualizationMgr VisualizationMgr;

var privatewrite bool	                    bNotifiedTargets;
var privatewrite bool						bNotifiedEnv;
var privatewrite bool						bCauseTimeDilationWhenInterrupting;

static function X2Action CreateVisualizationActionClass(class<X2Action> SpawnClass, XComGamestateContext Context, optional actor SpawnOwner )
{
	local X2Action AddAction;

	AddAction = class'WorldInfo'.static.GetWorldInfo( ).Spawn( SpawnClass, SpawnOwner );

	AddAction.StateChangeContext = Context;
	AddAction.CurrentHistoryIndex = Context.AssociatedState.HistoryIndex;

	return AddAction;
}

static function X2Action CreateVisualizationAction( XComGamestateContext Context, optional actor SpawnOwner )
{
	return CreateVisualizationActionClass( default.Class, Context, SpawnOwner );
}

/// <summary>
/// Static method that should be used to create new X2Action objects and add them to a visualization track
/// </summary>
/// <param name="InAbilityContext">The ablity context associated with this action</param>
/// <param name="InTrack">The visualization track that the new X2Action should be added to</param>
static function X2Action AddToVisualizationTrack(out VisualizationTrack InTrack, XComGameStateContext Context)
{
	local X2Action AddAction;
		
	AddAction = CreateVisualizationActionClass( default.Class, Context, InTrack.TrackActor );

	InTrack.TrackActions.AddItem( AddAction );

	return AddAction;
}

/// <summary>
/// Static method used to setup and added an X2Action to the visualization track.
/// </summar>
/// <param name="AddAction">The action that will be added to the track</param>
/// <param name="InTrack">The visualization track that the new X2Action should be added to</param>
/// <param name="Context">The ablity context associated with this action</param>
static function X2Action AddActionToVisualizationTrack(X2Action AddAction, out VisualizationTrack InTrack, XComGameStateContext Context)
{
	AddAction.StateChangeContext = Context;
	AddAction.CurrentHistoryIndex = Context.AssociatedState.HistoryIndex;

	InTrack.TrackActions.AddItem(AddAction);

	return AddAction;
}

static function bool AllowOverrideActionDeath(const out VisualizationTrack BuildTrack, XComGameStateContext Context)
{
	return false;
}

/// <summary>
/// Sets basic cache variables that all X2Actions will likely need to use during their operation. Called by the visualization mgr
/// immediately prior to the X2Action entering the 'executing' state
/// </summary>
/// <param name="InAbilityContext">The ablity context associated with this action</param>
/// <param name="InTrack">The visualization track that the new X2Action should be added to</param>
function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateContext Context;
	local XComGameState GameState;
	bCompleted = false;
	Track = InTrack;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	GameState = `XCOMHISTORY.GetGameStateFromHistory(Track.BlockHistoryIndex);
	if( GameState != None )
	{
		Context = GameState.GetContext();
		if(Context != None && VisualizationBlockContext == none) //VisualizationBlockContext may be non-null if this action has been passed to a resume block already
		{
			VisualizationBlockContext = XComGameStateContext_Ability(Context);
		}
	}

	if( Track.TrackActor != None )
	{
		Unit = XGUnit(Track.TrackActor);
		if( Unit != None )
		{
			UnitPawn = Unit.GetPawn();
			if( UnitPawn != None )
			{
				UnitPawn.SetUpdateSkelWhenNotRendered(true);
			}
		}
	}

	`assert( StateChangeContext != none );
}

function EInterruptionStatus GetContextInterruptionStatus()
{
	return StateChangeContext.InterruptionStatus;
}

/// <summary>
/// IsNextActionTypeOf is a helper method that X2Actions can utilize to interact with and gather information
/// about the next action that will be run. Returns TRUE if the next action is of the type specified by the
/// CheckType parameter.
/// </summary>
/// <param name="CheckType">The class we want the next action to be</param>
/// <param name="OutActionActor">Optional return parameter that will be filled out with a matching action actor</param>
function bool IsNextActionTypeOf(class CheckType, optional out X2Action OutActionActor)
{
	local X2Action TrackAction;
	local bool bCheckNext;
	local bool bNextIsCheckType;

	`assert(Track.TrackActions.Length > 0); //This method needs to be called after Init()

	bNextIsCheckType = false;
	bCheckNext = false;
	foreach Track.TrackActions(TrackAction)
	{
		if( bCheckNext )
		{
			bNextIsCheckType = TrackAction.Class == CheckType;
			OutActionActor = TrackAction;
			break;
		}

		if( TrackAction == self )
		{
			bCheckNext = true;
		}
	}

	return bNextIsCheckType;
}

/// <summary>
/// IsPreviousActionTypeOf operates in a similar fasion to IsNextActionTypeOf except that it checks the previous 
/// action instead of the next.
/// </summary>
/// <param name="CheckType">The class we want the next action to be</param>
/// <param name="OutActionActor">Optional return parameter that will be filled out with a matching action actor</param>
function bool IsPreviousActionTypeOf(class CheckType, optional out X2Action OutActionActor)
{
	local X2Action PreviousTrackAction;
	local X2Action TrackAction;	
	local bool bPreviousIsCheckType;

	`assert(Track.TrackActions.Length > 0); //This method needs to be called after Init()

	PreviousTrackAction = none;
	bPreviousIsCheckType = false;	
	foreach Track.TrackActions(TrackAction)
	{
		if( TrackAction == self )
		{
			bPreviousIsCheckType = PreviousTrackAction != none ? PreviousTrackAction.Class == CheckType : false;
			OutActionActor = PreviousTrackAction;			
			break;
		}

		PreviousTrackAction = TrackAction;
	}

	return bPreviousIsCheckType;
}

/// <summary>
/// Native event source of track messages. Originate from 'SendInterTrackMessage'
/// </summary>
event OnReceiveTrackMessage()
{
	HandleTrackMessage();
}

/// <summary>
/// Override and handle in derived classes to handle notifies coming in from animations that occur on the visualizer / actor associated with this action
/// </summary>
event OnAnimNotify(AnimNotify ReceiveNotify)
{
}

/// <summary>
/// Default behavior for X2Actions, where if the action is not performed within some reasonable time frame we assume that 
/// something terrible has happened and terminate it.
/// </summary>
function UpdateExecutingTime(float fDeltaT)
{
	ExecutingTime += fDeltaT;

	//Mark the action as completed if it has timed out. Actions must override IsTimedOut to use this behavior.
	if( IsTimedOut() )
	{
		if (!IsImmediateMode())
		{
			`RedScreen(Class $ " Timed Out, ExecutingTime:"@ExecutingTime@" TimoutTime:"@TimeoutSeconds@" notify gameplay team - "@self);
		}

		CompleteAction();
	}
}


/// <summary>
/// Change how long the action waits before auto-completing, if the default isn't good enough.
/// </summary>
function SetCustomTimeOutSeconds(float fSeconds)
{
	TimeoutSeconds = fSeconds;
}

/// <summary>
/// X2Actions may override this method to indicate to the tactical system that something they are doing should prevent 
/// the user from activating a new ability (or not). For example: when watching the result of a weapon shot we do not
/// want player inputs to result in actions happening off camera. Conversely, when the player puts a unit into over watch
/// the sound and flyover action should not block additional inputs
/// </summary>
event bool BlocksAbilityActivation()
{
	return class'X2TacticalGameRuleset'.default.ActionsBlockAbilityActivation;
}

/// <summary>
/// X2Actions may override this method to indicate to the XComGameStateVisualizationMgr that something has gone wrong and the action has taken longer
/// than expected to complete.
/// </summary>
function bool IsTimedOut()
{
	local bool HasTimeOut;

	HasTimeOut = TimeoutSeconds >= 0.0f;
	return (HasTimeOut && (ExecutingTime >= TimeoutSeconds)) || bForceImmediateTimeout;
}

/// <summary>
/// X2Actions may override this method to perform handling of incoming track messages
/// </summary>
function HandleTrackMessage();

/// <summary>
/// X2Actions must override this to correctly handle being interrupted. See documentation on MarkVisualizationBlockInterrupted in the visualization mgr
/// for more information on how interruptions are handled by the visualizer.
/// </summary>
function bool CheckInterrupted();

/// <summary>
/// Called when an X2Action becomes interrupted
/// </summary>
function BeginInterruption()
{
	bInterrupted = true;
}

/// <summary>
/// Called to force action to run in a non-latent way
/// </summary>
function ForceImmediateTimeout()
{
	bForceImmediateTimeout = true;
}

function bool IsImmediateMode()
{
	return bForceImmediateTimeout;
}

/// <summary>
/// This function allows individual X2Actions to indicate whether they should cause time dilation if they are part of a visualization block that is interrupting another. For instance:
/// A moving character alerts some enemies to their presence, which triggers changes to the unit flags on the enemies. The visualization block that changes the unit flags should not cause the
/// character to go into slow motion (Time Dilation), so the action that changes the unit flags should return FALSE.
///
/// We default to returning TRUE, since in general X2Actions that interrupt do something we want the player to see as an interrupt which necessitates slowing down / pausing the interruptee.
///
/// To decide whether a visualization block that is interrupting should cause time dilation, the visualization manager will scan all tracks of the visualization block. If any of the track
/// actions for any of the tracks want to cause time dilation then the system will time dilate for the interruptee.
/// </summary>
event bool GetShouldCauseTimeDilationIfInterrupting()
{	
	return bCauseTimeDilationWhenInterrupting;
}

//Allows visualization setup code to indicate whether the visualization should cause time dilation
function SetShouldCauseTimeDilationIfInterrupting(bool bSetting)
{
	bCauseTimeDilationWhenInterrupting = bSetting;
}

event HandleNewUnitSelection()
{
	// do nothing by default
}

/// <summary>
/// Called when an X2Action resumes from being interrupted. The passed in history index can be used to gather / update information in the action and is the index for the resuming history frame
/// </summary>
function ResumeFromInterrupt(int HistoryIndex)
{
	local XComGameState HistoryFrame;

	//Update the VisualizationBlockContext so that it matches where we are now
	HistoryFrame = `XCOMHISTORY.GetGameStateFromHistory(HistoryIndex);
	VisualizationBlockContext = XComGameStateContext_Ability(HistoryFrame.GetContext());	
	CurrentHistoryIndex = HistoryIndex;
	bInterrupted = false;
}

/// <summary>
/// Called by the visualization mgr when it needs to shut an action down, such as an when an interrupt block completes that has no resume.
/// </summary>
event ForceComplete()
{
	CompleteAction();
}

/// <summary>
/// X2Actions call this at the conclusion of their behavior to signal to the visualization mgr that they are done
/// </summary>
function CompleteAction()
{
	if( !bCompleted )
	{
		bCompleted = true;
		GotoState('Finished');
		if( UnitPawn != None )
		{
			UnitPawn.SetUpdateSkelWhenNotRendered(false);
		}

		VisualizationMgr.BeginNextTrackAction(Track, self);
	}
	else
	{
		GotoState('Finished');
	}
}   

/// <summary>
/// Alternate version of CompleteAction() which does not automatically goto the 'Finished' state
/// </summary>
function CompleteActionWithoutExitingExecution()
{
	if( !bCompleted )
	{
		bCompleted = true;

		if( UnitPawn != None )
		{
			UnitPawn.SetUpdateSkelWhenNotRendered(false);
		}

		VisualizationMgr.BeginNextTrackAction(Track, self);
	}
}

function DoNotifyTargetsAbilityAppliedWithMultipleHitLocations(XComGameState NotifyVisualizeGameState, XComGameStateContext_Ability NotifyAbilityContext,
									   int HistoryIndex, Vector HitLocation, array<Vector> allHitLocations, int PrimaryTargetID = 0, bool bNotifyMultiTargetsAtOnce = true )
{
	local StateObjectReference Target;
	local XComGameState_Unit TargetUnit;
	local Vector TargetUnitPos;
	local Vector HitLocationsIter;
	local float shortestDistSq;
	local float currDistSq;
	local int HitLocationIndex;
	local bool bSingleHitLocation;
	local bool TargetNotified;
	local bool bIsClosestTarget;
	
	if(!bNotifiedTargets)
	{
		if(allHitLocations.length <= 1)
		{
			bSingleHitLocation = true;
		}

		if (bNotifyMultiTargetsAtOnce && !bSingleHitLocation)
		{
			for(HitLocationIndex = 0; HitLocationIndex < NotifyAbilityContext.InputContext.MultiTargets.length; ++HitLocationIndex)
			{
				Target = NotifyAbilityContext.InputContext.MultiTargets[HitLocationIndex];
				TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.ObjectID));
				TargetUnitPos = `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation);
				//initialize shortestDistance to be the slightly more than the distance of the first element
				shortestDistSq = VSizeSq(allHitLocations[0] - TargetUnitPos) + 1.0f;

				foreach allHitLocations(HitLocationsIter)
				{
					//checking if this explosion is the closest hitlocations to the unit, if it is, we go ahead and notify the unit
					currDistSq = VSizeSq(HitLocationsIter - TargetUnitPos);
					if( currDistSq < shortestDistSq )
					{
						shortestDistSq = currDistSq;
						//HitLocationsIter == HitLocation check
						if( abs(HitLocationsIter.X - HitLocation.X) < EPSILON_ZERO &&  abs(HitLocationsIter.Y - HitLocation.Y) < EPSILON_ZERO && abs(HitLocationsIter.Z - HitLocation.Z) < EPSILON_ZERO )
						{
							bIsClosestTarget = true;
						}
						else
						{
							bIsClosestTarget = false;
						}
					}
				}
				if(bIsClosestTarget)
				{
					//notify the unit, and mark that we have notified the unit
					VisualizationMgr.SendInterTrackMessage(Target, HistoryIndex);
					NotifyAbilityContext.InputContext.MultiTargetsNotified[HitLocationIndex] = true;
				}
			}
		}

		if(!bNotifiedEnv) //for now we immediately notify all environment of the damage on the first projectile hit
		{
			DoNotifyTargetsAbilityApplied(NotifyVisualizeGameState, NotifyAbilityContext, HistoryIndex, PrimaryTargetID, bNotifyMultiTargetsAtOnce, bSingleHitLocation);
			bNotifiedEnv = true;
		}
		
		//check if all units have been notified
		bNotifiedTargets = true;
		foreach NotifyAbilityContext.InputContext.MultiTargetsNotified(TargetNotified)
		{
			if( !TargetNotified )
			{
				bNotifiedTargets = false;
			}
		}
	}
}

function DoNotifyTargetsAbilityApplied(XComGameState NotifyVisualizeGameState, XComGameStateContext_Ability NotifyAbilityContext,
									   int HistoryIndex, int PrimaryTargetID = 0, bool bNotifyMultiTargetsAtOnce = true, bool bSingleHitLocation = true)
{
	local StateObjectReference Target, RedirectTarget;		
	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local XComGameState_InteractiveObject InteractiveObject;
	local XComGameState_WorldEffectTileData WorldEffectTileData;
	local int RedirectIndex;
	local array<int> NotifiedIDs;

	if( !bNotifiedTargets )
	{
		if( PrimaryTargetID > 0 )
		{
			Target.ObjectID = PrimaryTargetID;
			VisualizationMgr.SendInterTrackMessage(Target, HistoryIndex);
			NotifiedIDs.AddItem(PrimaryTargetID);
			for (RedirectIndex = 0; RedirectIndex < NotifyAbilityContext.ResultContext.EffectRedirects.Length; ++RedirectIndex)
			{
				if (NotifyAbilityContext.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID == PrimaryTargetID)
				{
					if (NotifiedIDs.Find(NotifyAbilityContext.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID) == INDEX_NONE)
					{
						RedirectTarget = NotifyAbilityContext.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef;
						VisualizationMgr.SendInterTrackMessage(RedirectTarget, HistoryIndex);
						NotifiedIDs.AddItem(RedirectTarget.ObjectID);
					}
		}
			}
		}

		if( bNotifyMultiTargetsAtOnce && bSingleHitLocation && NotifyAbilityContext != None)
		{
			foreach NotifyAbilityContext.InputContext.MultiTargets(Target)
			{
				VisualizationMgr.SendInterTrackMessage(Target, HistoryIndex);
				for (RedirectIndex = 0; RedirectIndex < NotifyAbilityContext.ResultContext.EffectRedirects.Length; ++RedirectIndex)
				{
					if (NotifyAbilityContext.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID == Target.ObjectID)
					{
						if (NotifiedIDs.Find(NotifyAbilityContext.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID) == INDEX_NONE)
						{
							RedirectTarget = NotifyAbilityContext.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef;
							VisualizationMgr.SendInterTrackMessage(RedirectTarget, HistoryIndex);
							NotifiedIDs.AddItem(RedirectTarget.ObjectID);
						}
					}
				}
			}
		}

		foreach NotifyVisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
		{
			Target = EnvironmentDamageEvent.GetReference();
			VisualizationMgr.SendInterTrackMessage(Target, HistoryIndex);
		}

		foreach NotifyVisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
		{
			Target = InteractiveObject.GetReference();
			VisualizationMgr.SendInterTrackMessage(Target, HistoryIndex);
		}

		foreach NotifyVisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldEffectTileData)
		{
			Target = WorldEffectTileData.GetReference();
			VisualizationMgr.SendInterTrackMessage(Target, HistoryIndex);
		}

		//If any of the targets have not been notified, we set it to false
		if(bSingleHitLocation)
		{
			bNotifiedTargets = true;
		}
	}
}

auto state WaitingToStart
{
}

simulated state Executing
{
	simulated function BeginState(name PrevStateName)
	{
		local XComGameStateHistory History;
		local XComGameState_Unit UnitState;

		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if (UnitState.ReflexActionState == eReflexActionState_SelectAction)
				return;
		}
		//  @TODO - there doesn't seem to be a screen effect in play at all aside from the "reflex" overlay, so this code may no longer be needed if there is no longer a post process for reflex
		EnablePostProcessEffect(name(class'X2Action_Reflex'.default.PostProcessName), false);
		`PRES.UIHideReflexOverlay();
	}
}

simulated function EnablePostProcessEffect(name EffectName, bool bEnable)
{
	`PRES.EnablePostProcessEffect(EffectName, bEnable);
}

simulated state Finished
{
begin:
	if( bInterrupted )
	{
		ResumeFromInterrupt(StateChangeContext.AssociatedState.HistoryIndex);
	}
	`assert(bCompleted);
}

function float GetDelayModifier()
{
	if( ShouldPlayZipMode() )
		return class'X2TacticalGameRuleset'.default.ZipModeDelayModifier;
	else
		return 1.0;
}

function float GetNonCriticalAnimationSpeed()
{
	if( ShouldPlayZipMode() )
		return class'X2TacticalGameRuleset'.default.ZipModeTrivialAnimSpeed;
	else
		return 1.0;
}

function float GetMoveAnimationSpeed()
{
	if( ShouldPlayZipMode() )
		return class'X2TacticalGameRuleset'.default.ZipModeMoveSpeed;
	else
		return 1.0;
}

function bool ShouldPlayZipMode()
{
	return `XPROFILESETTINGS.Data.bEnableZipMode;
}

function bool IsWaitingOnActionTrigger()
{
	return false;
}

function TriggerWaitCondition();

DefaultProperties
{
	ExecutingTime = 0.0	
	TimeoutSeconds = 10.0
	bNotifiedTargets=false
	bCauseTimeDilationWhenInterrupting=false
}
