//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_AbilityPerkDurationEnd extends X2Action
	dependson(XComAnimNodeBlendDynamic);

var private XGUnit TrackUnit;

var private XGUnit CasterUnit;
var private XGUnit TargetUnit;
var private XComUnitPawnNativeBase CasterPawn;
var private XComPerkContent EndingPerk;

var private CustomAnimParams AnimParams;
var private int x, i;

var XComGameState_Effect EndingEffectState;

function Init(const out VisualizationTrack InTrack)
{
	local X2Effect EndingEffect;
	local name EndingEffectName;
	local array<XComPerkContent> Perks;
	local bool bIsCasterTarget;

	super.Init(InTrack);

	TrackUnit = XGUnit( Track.TrackActor );

	EndingEffect = class'X2Effect'.static.GetX2Effect( EndingEffectState.ApplyEffectParameters.EffectRef );
	if (X2Effect_Persistent(EndingEffect) != none)
	{
		EndingEffectName = X2Effect_Persistent(EndingEffect).EffectName;
	}
	`assert( EndingEffectName != '' ); // what case isn't being handled?

	CasterUnit = XGUnit( `XCOMHISTORY.GetVisualizer( EndingEffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID ) );
	CasterPawn = CasterUnit.GetPawn( );

	TargetUnit = XGUnit( `XCOMHISTORY.GetVisualizer( EndingEffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID ) );

	class'XComPerkContent'.static.GetAssociatedPerks( Perks, CasterPawn, EndingEffectState.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName );

	bIsCasterTarget = (TargetUnit == CasterUnit);
	for (x = 0; x < Perks.Length; ++x)
	{
		if (Perks[ x ].AssociatedEffect == EndingEffectName)
		{
			if ((bIsCasterTarget && Perks[ x ].TargetDurationFXOnly) ||
				(!bIsCasterTarget && Perks[ x ].CasterDurationFXOnly))
			{
				continue;
			}

			EndingPerk = Perks[ x ];
			break;
		}
	}
}

event bool BlocksAbilityActivation()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event BeginState(Name PreviousStateName)
	{
		if (EndingPerk != none)
		{
			if ((TargetUnit != None) && (TargetUnit != CasterUnit))
			{
				EndingPerk.RemovePerkTarget( TargetUnit );
			}
			else
			{
				EndingPerk.OnPerkDurationEnd( );
			}
		}
	}

Begin:

	if (EndingPerk != none)
	{
		AnimParams.AnimName = class'XComPerkContent'.static.ChooseAnimationForCover( CasterUnit, EndingPerk.CasterDurationEndedAnim );
		AnimParams.PlayRate = GetNonCriticalAnimationSpeed();

		if ((EndingPerk.m_ActiveTargetCount == 0) && EndingPerk.CasterDurationEndedAnim.PlayAnimation && AnimParams.AnimName != '')
		{
			if( EndingPerk.CasterDurationEndedAnim.AdditiveAnim )
			{
				FinishAnim(CasterPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(AnimParams));
				CasterPawn.GetAnimTreeController().RemoveAdditiveDynamicAnim(AnimParams);
			}
			else
			{
				FinishAnim(CasterPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
			}
		}

		if (EndingPerk.TargetDurationEndedAnim.PlayAnimation)
		{
			AnimParams.AnimName = class'XComPerkContent'.static.ChooseAnimationForCover( TargetUnit, EndingPerk.TargetDurationEndedAnim );
			if (AnimParams.AnimName != '')
			{
				if( EndingPerk.CasterDurationEndedAnim.AdditiveAnim )
				{
					FinishAnim(TargetUnit.GetPawn().GetAnimTreeController().PlayAdditiveDynamicAnim(AnimParams));
					TargetUnit.GetPawn().GetAnimTreeController().RemoveAdditiveDynamicAnim(AnimParams);
				}
				else
				{
					FinishAnim(TargetUnit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
				}
			}
		}
	}

	CompleteAction();
}

