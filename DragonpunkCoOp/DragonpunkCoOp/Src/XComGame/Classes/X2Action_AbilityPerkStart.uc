//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_AbilityPerkStart extends X2Action;

var privatewrite XComGameStateContext_Ability StartingAbility;
var private XGUnit TrackUnit;

var bool NotifyTargetTracks;
var bool AppendAbilityPerks;        //  @TODO - set this dynamically as appropriate, for now it will always be true
var bool TrackHasNoFireAction;

var privatewrite bool NeedsDelay;
var private bool ImpactNotified;

function Init(const out VisualizationTrack InTrack)
{
	local X2AbilityTemplate AbilityTemplate;

	super.Init(InTrack);

	StartingAbility = XComGameStateContext_Ability(StateChangeContext);
	TrackUnit = XGUnit(Track.TrackActor);

	if (AppendAbilityPerks)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(StartingAbility.InputContext.AbilityTemplateName);
		TrackUnit.GetPawn().AppendAbilityPerks(AbilityTemplate.DataName, true, AbilityTemplate.GetPerkAssociationName());
	}
}

event bool BlocksAbilityActivation()
{
	return false;
}

function string GetAbilityName( )
{
	return string(StartingAbility.InputContext.AbilityTemplateName);
}

function NotifyTargetsAbilityApplied( )
{
	local StateObjectReference Target;
	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local XComGameState_WorldEffectTileData WorldEffectTileData;
	local XComGameState VisualizeGameState;

	VisualizeGameState = StartingAbility.AssociatedState;

	if (StartingAbility.InputContext.PrimaryTarget.ObjectID > 0)
	{
		VisualizationMgr.SendInterTrackMessage( StartingAbility.InputContext.PrimaryTarget );
	}

	foreach StartingAbility.InputContext.MultiTargets( Target )
	{
		VisualizationMgr.SendInterTrackMessage( Target );
	}

	foreach VisualizeGameState.IterateByClassType( class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent )
	{
		Target = EnvironmentDamageEvent.GetReference( );
		VisualizationMgr.SendInterTrackMessage( Target );
	}

	foreach VisualizeGameState.IterateByClassType( class'XComGameState_WorldEffectTileData', WorldEffectTileData )
	{
		Target = WorldEffectTileData.GetReference( );
		VisualizationMgr.SendInterTrackMessage( Target );
	}
}

function NotifyPerkStart( AnimNotify_PerkStart Notify )
{
	local int x, t, e, ShooterEffectIndex;
	local XComUnitPawnNativeBase CasterPawn;
	local XComGameState_Unit TargetState;
	local array<XGUnit> Targets, SuccessTargets;
	local array<EffectResults> TargetEffectResults, SuccessTargetEffectResults;
	local array<XComPerkContent> Perks;
	local EffectResults EffectApplicationResults;
	local X2Effect_Persistent TargetEffect;
	local name EffectResult;
	local int CasterInTargetsIndex;
	local XGUnit CasterUnit;
	local bool FoundEffect;
	local bool bAssociatedSourceEffect;

	if( Notify != none && NotifyTargetTracks )
	{
		NotifyTargetsAbilityApplied( );
	}

	TargetState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( StartingAbility.InputContext.PrimaryTarget.ObjectID ) );
	if (TargetState != none)
	{
		Targets.AddItem( XGUnit( TargetState.GetVisualizer( ) ) );
		TargetEffectResults.AddItem( StartingAbility.ResultContext.TargetEffectResults );
	}
	for (x = 0; x < StartingAbility.InputContext.MultiTargets.Length; ++x)
	{
		TargetState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( StartingAbility.InputContext.MultiTargets[ x ].ObjectID ) );
		if (TargetState != none)
		{
			Targets.AddItem( XGUnit( TargetState.GetVisualizer( ) ) );
			TargetEffectResults.AddItem( StartingAbility.ResultContext.MultiTargetEffectResults[x] );
		}
	}

	CasterUnit = XGUnit( `XCOMHISTORY.GetVisualizer( StartingAbility.InputContext.SourceObject.ObjectID ) );
	CasterPawn = CasterUnit.GetPawn( );
	CasterInTargetsIndex = Targets.Find(CasterUnit);

	class'XComPerkContent'.static.GetAssociatedPerks( Perks, CasterPawn, StartingAbility.InputContext.AbilityTemplateName );
	for (x = 0; x < Perks.Length; ++x)
	{
		// make sure that the way we're supposed to activate this perk (with a notify or not) matches with how we're actually being triggered
		// (with a notify or not)
		if (Perks[x].ActivatesWithAnimNotify != (Notify != none))
		{
			continue;
		}

		SuccessTargets = Targets;
		SuccessTargetEffectResults = TargetEffectResults;

		if (Perks[x].IgnoreCasterAsTarget && (CasterInTargetsIndex != INDEX_NONE))
		{
			// Remove the source if it is supposed to be ignored
			SuccessTargets.Remove(CasterInTargetsIndex, 1);
			SuccessTargetEffectResults.Remove(CasterInTargetsIndex, 1);
		}

		// if we part of an effect that is applied to the target(s), see if that effect was actually applied succesefully.
		if (Perks[x].AssociatedEffect != '')
		{
			bAssociatedSourceEffect = false;
			for (ShooterEffectIndex = 0; ShooterEffectIndex < StartingAbility.ResultContext.ShooterEffectResults.Effects.Length; ++ShooterEffectIndex)
			{
				TargetEffect = X2Effect_Persistent(StartingAbility.ResultContext.ShooterEffectResults.Effects[ShooterEffectIndex]);

				if ((TargetEffect != none) &&
					(TargetEffect.EffectName == Perks[x].AssociatedEffect) &&
					(StartingAbility.ResultContext.ShooterEffectResults.ApplyResults[ShooterEffectIndex] == 'AA_Success'))
				{
					bAssociatedSourceEffect = true;
					break;
				}
			}

			if (Targets.Length > 0)
			{
				// Reverse iterate so that we can remove based on index an keep the unprocessed SuccessTargets in the same index as they are in Targets
				for (t = Targets.Length - 1; t >= 0; --t)
				{
					EffectApplicationResults = SuccessTargetEffectResults[ t ];
					FoundEffect = false;

					for (e = 0; e < EffectApplicationResults.Effects.Length; ++e)
					{
						TargetEffect = X2Effect_Persistent( EffectApplicationResults.Effects[ e ] );
						EffectResult = EffectApplicationResults.ApplyResults[ e ];

						if ((TargetEffect != none) && (TargetEffect.EffectName == Perks[ x ].AssociatedEffect) && (EffectResult == 'AA_Success'))
						{
							FoundEffect = true;
							break;
						}
					}

					//There were no successful applications of the effect to this target. Don't use them in the perk.
					if (!FoundEffect)
						SuccessTargets.Remove(t, 1);
				}
			}

			if (!bAssociatedSourceEffect && (Targets.Length > 0) && (SuccessTargets.Length == 0))
			{
				// if there are no successful targets, then we shouldn't start this perk
				continue;
			}
		}

		Perks[ x ].OnPerkActivation( TrackUnit, SuccessTargets, StartingAbility.InputContext.TargetLocations, bAssociatedSourceEffect );
	}
}

function XComWeapon GetPerkWeapon( )
{
	local XGUnit CasterUnit;
	local XComUnitPawnNativeBase CasterPawn;
	local array<XComPerkContent> Perks;
	local int x;
	local XComWeapon Weapon;

	CasterUnit = XGUnit( `XCOMHISTORY.GetVisualizer( StartingAbility.InputContext.SourceObject.ObjectID ) );
	CasterPawn = CasterUnit.GetPawn( );

	class'XComPerkContent'.static.GetAssociatedPerks( Perks, CasterPawn, StartingAbility.InputContext.AbilityTemplateName );

	for (x = 0; x < Perks.Length; ++x)
	{
		// if the perk isn't in one of the active states, we probably didn't pass the targets filter in NotifyPerkStart
		if (Perks[x].IsInState( 'ActionActive' ) || Perks[x].IsInState( 'DurationAction' ))
		{
			Weapon = Perks[x].GetPerkWeapon( );
			if (Weapon != none)
			{
				return Weapon;
			}
		}
	}

	return none;
}

function TriggerImpact( )
{
	local int x;
	local XComUnitPawnNativeBase CasterPawn;
	local array<XComPerkContent> Perks;

	CasterPawn = XGUnit( `XCOMHISTORY.GetVisualizer( StartingAbility.InputContext.SourceObject.ObjectID ) ).GetPawn( );

	class'XComPerkContent'.static.GetAssociatedPerks( Perks, CasterPawn, StartingAbility.InputContext.AbilityTemplateName );
	for (x = 0; x < Perks.Length; ++x)
	{
		Perks[ x ].TriggerImpact( );
	}
	ImpactNotified = true;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event BeginState(Name PreviousStateName)
	{
		local int x;
		local XComUnitPawnNativeBase CasterPawn;
		local array<XComPerkContent> Perks;

		CasterPawn = XGUnit( `XCOMHISTORY.GetVisualizer( StartingAbility.InputContext.SourceObject.ObjectID ) ).GetPawn( );
		TrackUnit.CurrentPerkAction = self;
		class'XComPerkContent'.static.GetAssociatedPerks( Perks, CasterPawn, StartingAbility.InputContext.AbilityTemplateName );
		for (x = 0; x < Perks.Length; ++x)
		{
			if (Perks[x].ManualFireNotify)
			{
				NeedsDelay = true;
				break;
			}
		}

		NotifyPerkStart( none );
	}

Begin:

	if (NeedsDelay && TrackHasNoFireAction)
	{
		while (!ImpactNotified && !IsTimedOut( ))
			Sleep( 0.0f );
	}

	CompleteAction();
}

DefaultProperties
{
	AppendAbilityPerks = true
}