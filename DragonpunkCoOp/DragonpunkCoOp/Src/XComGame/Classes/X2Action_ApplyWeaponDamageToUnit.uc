//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ApplyWeaponDamageToUnit extends X2Action 
	dependson(XComAnimNodeBlendDynamic)
	config(Animation);

var X2AbilityTemplate                                                       AbilityTemplate; //The template for the ability that is affecting us
var Actor                                                                   DamageDealer;
var int                                                                     m_iDamage, m_iMitigated, m_iShielded, m_iShredded;
var array<DamageResult>                                                     DamageResults;
var array<EAbilityHitResult>                                                HitResults;
var name																	DamageTypeName;
var Vector                                                                  m_vHitLocation;
var Vector                                                                  m_vMomentum;
var bool                                                                    bGoingToDie;
var bool                                                                    bWasHit;
var bool                                                                    bWasCounterAttack;
var bool                                                                    bCounterAttackAnim;
var XComGameStateContext_Ability                                            AbilityContext;
var CustomAnimParams                                                        AnimParams;
var EAbilityHitResult                                                       HitResult;
var XComGameStateContext_TickEffect                                         TickContext;
var XComGameStateContext_AreaDamage                                         AreaDamageContext;
var XComGameStateContext_Falling                                            FallingContext;
var XComGameStateContext_ApplyWorldEffects                                  WorldEffectsContext;
var int                                                                     TickIndex;      //This is set by AddX2ActionsForVisualization_Tick
var AnimNodeSequence                                                        PlayingSequence;
var X2Effect                                                                OriginatingEffect;
var X2Effect                                                                AncestorEffect; //In the case of ticking effects causing damage effects, this is the ticking effect (if known and different)
var bool                                                                    bHiddenAction;
var StateObjectReference													CounterAttackTargetRef;
var bool                                                                    bDoOverrideAnim;
var XComGameState_Unit                                                      OverrideOldUnitState;
var X2Effect_Persistent                                                     OverridePersistentEffectTemplate;
var string                                                                  OverrideAnimEffectString;
var bool                                                                    bPlayDamageAnim;  // Only display the first damage hit reaction
var bool                                                                    bIsUnitRuptured;
var bool																	bShouldContinueAnim;
var bool																	bMoving;
var bool																	bSkipWaitForAnim;
var X2Action_MoveDirect														RunningAction;
var config float															HitReactDelayTimeToDeath;
var XComGameState_Unit														UnitState;
var XComGameState_AIGroup													GroupState;
var int																		ScanGroup;
var XGUnit																	ScanUnit;
var XComPerkContent															kPerkContent;
var array<name>                                                             TargetAdditiveAnims;

var X2Effect DamageEffect;		// If the damage was from an effect, this is the effect

// Needs to match values in DamageMessageBox.as
enum eWeaponDamageType
{
	eWDT_Armor,
	eWDT_Shred,
	eWDT_Repeater,
	eWDT_Psi,
};

function Init(const out VisualizationTrack InTrack)
{
	local int MultiIndex, WorldResultIndex, RedirectIndex;
	local int DmgIndex, ActionIndex;
	local XComGameState_Unit OldUnitState;
	local X2EffectTemplateRef LookupEffect;
	local X2Effect SourceEffect;
	local X2Action_ApplyWeaponDamageToUnit OtherAction;	
	local XComGameState_Item SourceItemGameState;
	local X2WeaponTemplate WeaponTemplate;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability IterateAbility;	
	local XComGameState LastGameStateInInterruptChain;
	local DamageResult DmgResult;
	local X2Action OutFirstDamageAction;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local name TargetAdditiveAnim;

	super.Init(InTrack);

	History = `XCOMHISTORY;	

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);	
	if (AbilityContext != none)
	{
		LastGameStateInInterruptChain = AbilityContext.GetLastStateInInterruptChain();

		//Perform special processing for counter attack before doing anything with AbilityContext, as we may need to switch
		//to the counter attack ability context
		if (AbilityContext.ResultContext.HitResult == eHit_CounterAttack)
		{	
			bWasCounterAttack = true;
			//Check if we are the original shooter in a counter attack sequence, meaning that we are now being attacked. The
			//target of a counter attack just plays a different flinch/reaction anim
			IterateAbility = class'X2Ability'.static.FindCounterAttackGameState(AbilityContext, XComGameState_Unit(InTrack.StateObject_NewState));
			if (IterateAbility != None)
			{
				//In this situation we need to update ability context so that it is from the counter attack game state				
				AbilityContext = IterateAbility;
				OldUnitState = XComGameState_Unit(History.GetGameStateForObjectID(InTrack.StateObject_NewState.ObjectID, eReturnType_Reference, AbilityContext.AssociatedState.HistoryIndex - 1));
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(InTrack.StateObject_NewState.ObjectID, eReturnType_Reference, AbilityContext.AssociatedState.HistoryIndex));
				bCounterAttackAnim = false; //We are the target of the counter attack, don't play the counter attack anim
			}
			else
			{
				CounterAttackTargetRef = AbilityContext.InputContext.SourceObject;
				bCounterAttackAnim = true; //We are counter attacking, play the counter attack anim
			}
		}
		else
		{
			UnitState = XComGameState_Unit(LastGameStateInInterruptChain.GetGameStateForObjectID(InTrack.StateObject_NewState.ObjectID));
			if (UnitState == None) //This can occur for abilities which were interrupted but never resumed, e.g. because the shooter was killed.
				UnitState = XComGameState_Unit(InTrack.StateObject_NewState); //Will typically be the same as the OldState in this case.

			`assert(UnitState != none);			//	this action should have only been added for a unit!
			OldUnitState = XComGameState_Unit(InTrack.StateObject_OldState);
			`assert(OldUnitState != none);
		}
	}
	else
	{
		TickContext = XComGameStateContext_TickEffect(StateChangeContext);
		AreaDamageContext = XComGameStateContext_AreaDamage(StateChangeContext);
		FallingContext = XComGameStateContext_Falling(StateChangeContext);
		WorldEffectsContext = XComGameStateContext_ApplyWorldEffects(StateChangeContext);

		UnitState = XComGameState_Unit(InTrack.StateObject_NewState);
		OldUnitState = XComGameState_Unit(InTrack.StateObject_OldState);
	}

	m_iDamage = 0;
	m_iMitigated = 0;
	
	if (AbilityContext != none)
	{
		DamageDealer = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID).GetVisualizer();
		SourceItemGameState = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
		WeaponTemplate = X2WeaponTemplate(SourceItemGameState.GetMyTemplate());
	}

	//Set up a damage type
	if (WeaponTemplate != none)
	{
		DamageTypeName = WeaponTemplate.BaseDamage.DamageType;
		if (DamageTypeName == '')
		{
			DamageTypeName = WeaponTemplate.DamageTypeTemplateName;
		}
	}
	else if (TickContext != none || WorldEffectsContext != none)
	{
		for (DmgIndex = 0; DmgIndex < UnitState.DamageResults.Length; ++DmgIndex)
		{
			if (UnitState.DamageResults[DmgIndex].Context == StateChangeContext)
			{
				LookupEffect = UnitState.DamageResults[DmgIndex].SourceEffect.EffectRef;
				SourceEffect = class'X2Effect'.static.GetX2Effect(LookupEffect);
				DamageEffect = SourceEffect;
				DamageTypeName = SourceEffect.DamageTypes[0];
				m_iDamage = UnitState.DamageResults[DmgIndex].DamageAmount;
				break;
			}
		}
	}
	else
	{
		DamageTypeName = class'X2Item_DefaultDamageTypes'.default.DefaultDamageType;
	}

	bWasHit = false;
	m_vHitLocation = UnitPawn.GetHeadshotLocation();
	if (AbilityContext != none)
	{
		AbilityTemplate =  class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		`assert(AbilityTemplate != none);
		if (AbilityContext.InputContext.PrimaryTarget.ObjectID == InTrack.StateObject_NewState.ObjectID)
		{
			bWasHit = bWasHit || AbilityContext.IsResultContextHit();	
			HitResult = AbilityContext.ResultContext.HitResult;
			HitResults.AddItem(HitResult);
		}
		
		for (MultiIndex = 0; MultiIndex < AbilityContext.InputContext.MultiTargets.Length; ++MultiIndex)
		{
			if (AbilityContext.InputContext.MultiTargets[MultiIndex].ObjectID == InTrack.StateObject_NewState.ObjectID)
			{
				bWasHit = bWasHit || AbilityContext.IsResultContextMultiHit(MultiIndex);
				HitResult = AbilityContext.ResultContext.MultiTargetHitResults[MultiIndex];
				HitResults.AddItem(HitResult);
			}
		}	

		if (HitResults.Length == 0)
		{
			for (RedirectIndex = 0; RedirectIndex < AbilityContext.ResultContext.EffectRedirects.Length; ++RedirectIndex)
			{
				if (AbilityContext.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID == InTrack.StateObject_NewState.ObjectID)
				{
					if (AbilityContext.InputContext.PrimaryTarget.ObjectID == AbilityContext.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID)
					{
						bWasHit = bWasHit || AbilityContext.IsResultContextHit();
						HitResult = AbilityContext.ResultContext.HitResult;
						HitResults.AddItem(HitResult);
					}
				}
				for (MultiIndex = 0; MultiIndex < AbilityContext.InputContext.MultiTargets.Length; ++MultiIndex)
				{
					if (AbilityContext.InputContext.MultiTargets[MultiIndex].ObjectID == AbilityContext.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID)
					{
						bWasHit = bWasHit || AbilityContext.IsResultContextMultiHit(MultiIndex);
						HitResult = AbilityContext.ResultContext.MultiTargetHitResults[MultiIndex];
						HitResults.AddItem(HitResult);
					}
				}
			}
		}
	}
	else if (TickContext != none)
	{
		bWasHit = (TickIndex == INDEX_NONE) || (TickContext.arrTickSuccess[TickIndex] == 'AA_Success');
		HitResult = bWasHit ? eHit_Success : eHit_Miss;

		if (bWasHit)
			HitResults.AddItem(eHit_Success);
	}
	else if (FallingContext != none || AreaDamageContext != None)
	{
		bWasHit = true;
		HitResult = eHit_Success;

		HitResults.AddItem( eHit_Success );
	}
	else if (WorldEffectsContext != none)
	{
		for (WorldResultIndex = 0; WorldResultIndex < WorldEffectsContext.TargetEffectResults.Effects.Length; ++WorldResultIndex)
		{
			if (WorldEffectsContext.TargetEffectResults.Effects[WorldResultIndex] == OriginatingEffect)
			{
				if (WorldEffectsContext.TargetEffectResults.ApplyResults[WorldResultIndex] == 'AA_Success')
				{
					bWasHit = true;
					HitResult = eHit_Success;
					HitResults.AddItem(eHit_Success);
				}
				else
				{
					bWasHit = false;
					HitResult = eHit_Miss;
					HitResults.AddItem(eHit_Miss);
				}
					
				break;
			}
		}
	}
	else
	{
		`RedScreen("Unhandled context for this action:" @ StateChangeContext @ self);
	}

	if (AbilityContext != none || TickContext != none)
	{
		if (bWasHit)
		{
			bPlayDamageAnim = false;
		}

		for (DmgIndex = 0; DmgIndex < UnitState.DamageResults.Length; ++DmgIndex)
		{ 
			if (LastGameStateInInterruptChain != none)
			{
				if(UnitState.DamageResults[DmgIndex].Context != LastGameStateInInterruptChain.GetContext())
					continue;
			}
			else if (UnitState.DamageResults[DmgIndex].Context != StateChangeContext)
			{
				continue;
			}
			LookupEffect = UnitState.DamageResults[DmgIndex].SourceEffect.EffectRef;
			SourceEffect = class'X2Effect'.static.GetX2Effect(LookupEffect);
			if (SourceEffect == OriginatingEffect || (AncestorEffect != None && SourceEffect == AncestorEffect))
			{
				DamageResults.AddItem(UnitState.DamageResults[DmgIndex]);
				m_iDamage = UnitState.DamageResults[DmgIndex].DamageAmount;
				m_iMitigated = UnitState.DamageResults[DmgIndex].MitigationAmount;

				if (bWasHit)
				{
					bPlayDamageAnim = true;
				}
			}
		}

		if (!bWasHit && ((OriginatingEffect.bApplyOnHit && !OriginatingEffect.bApplyOnMiss ) || m_iDamage + m_iMitigated == 0))
		{
			//  this was not a hit and no damage was dealt. if any other damage action exists, hide this.
			for (ActionIndex = 0; ActionIndex < InTrack.TrackActions.Length; ++ActionIndex)
			{
				OtherAction = X2Action_ApplyWeaponDamageToUnit(InTrack.TrackActions[ActionIndex]);
				if (OtherAction != none && OtherAction != self && !OtherAction.bHiddenAction)
				{
					bHiddenAction = true;
					break;
				}
			}
		}
		else if (bWasHit && OriginatingEffect.bApplyOnMiss && !OriginatingEffect.bApplyOnHit)
 		{
			//  never visualize the miss effect when it's actually a hit, the hit will visualize instead
			bHiddenAction = true;
		}
	}
	else if (AreaDamageContext != None)
	{
		//  For falling and area damage, there isn't an effect to deal with, so just grab the raw change in HP
		m_iDamage = OldUnitState.GetCurrentStat( eStat_HP ) - UnitState.GetCurrentStat( eStat_HP );

		for (DmgIndex = 0; DmgIndex < UnitState.DamageResults.Length; ++DmgIndex)
		{
			if (UnitState.DamageResults[DmgIndex].Context == AreaDamageContext)
			{
				DmgResult = UnitState.DamageResults[DmgIndex];
				break;
			}
		}

		DmgResult.DamageAmount = m_iDamage;
		DmgResult.Context = AreaDamageContext;

		DamageResults.AddItem( DmgResult );

		VisualizationMgr.TrackHasActionOfType( Track, class'X2Action_ApplyWeaponDamageToUnit', OutFirstDamageAction );
		bPlayDamageAnim = OutFirstDamageAction == self;
	}
	else if (FallingContext != none)
	{
		//  For falling and area damage, there isn't an effect to deal with, so just grab the raw change in HP
		m_iDamage = OldUnitState.GetCurrentStat( eStat_HP ) - UnitState.GetCurrentStat( eStat_HP );
		
		DmgResult.DamageAmount = m_iDamage;
		DmgResult.Context = FallingContext;

		DamageResults.AddItem( DmgResult );
	}
	else
	{
		//  For falling and area damage, there isn't an effect to deal with, so just grab the raw change in HP
		m_iDamage = OldUnitState.GetCurrentStat(eStat_HP) - UnitState.GetCurrentStat(eStat_HP);
	}
	
	bGoingToDie = UnitState.IsDead() || UnitState.IsIncapacitated();

	// If the old state was not Ruptured and the new state has become Ruptured
	bIsUnitRuptured = (OldUnitState.Ruptured == 0) && (UnitState.Ruptured > 0);

	bMoving = X2Action_Move(`XCOMVISUALIZATIONMGR.GetCurrentTrackActionForVisualizer(Unit, true)) != none ||
			  X2Action_Move(`XCOMVISUALIZATIONMGR.GetCurrentTrackActionForVisualizer(Unit, false)) != none;

	if( bMoving )
	{
		RunningAction = X2Action_MoveDirect(`XCOMVISUALIZATIONMGR.GetCurrentTrackActionForVisualizer(Unit, true));
		if( RunningAction == None )
		{
			RunningAction = X2Action_MoveDirect(`XCOMVISUALIZATIONMGR.GetCurrentTrackActionForVisualizer(Unit, false));
		}
	}

	//  look for an additive anim to play for the target based on its effects
	foreach UnitState.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		TargetAdditiveAnim = EffectState.GetX2Effect().TargetAdditiveAnimOnApplyWeaponDamage(StateChangeContext, UnitState, EffectState);
		if (TargetAdditiveAnim != '')
			TargetAdditiveAnims.AddItem(TargetAdditiveAnim);
	}
}

function HandleTrackMessage()
{
	bShouldContinueAnim = true;
}


// This function implements feedback from Jake S, "have the armor lines only play if after 
// the damage is applied, the soldier is at 2/3 health or higher.  Also, they should only 
// say the lines if their armor hasn't been shredded."
function bool ShouldPlayArmorHitVO()
{
	local bool bIsMitigated, bIsShredded;
	local int i;

	// Return false if any damage causes Shedding.
	for (i = 0; i < DamageResults.Length; i++)
	{
		bIsMitigated = bIsMitigated || (DamageResults[i].MitigationAmount > 0);
		bIsShredded = (DamageResults[i].Shred > 0);
		if (bIsShredded)
		{
			return false;
		}
	}

	// Return false if Armor was not used.
	if (!bIsMitigated)
		return false;

	// Return false if the unit has too little health anyway.
	if (UnitState.GetCurrentStat(eStat_HP)/UnitState.GetMaxStat(eStat_HP) < 0.6666f)
		return false;


	return true;
}

//@TODO - rmcfall/jbouscher - effect template?
simulated function bool ShouldPlayAnimation()
{
	local bool bFalling; //See if we are going to be falling / fell. Don't do any hurt animations if so
	local X2Action FallingAction;

	bFalling = VisualizationMgr.TrackHasActionOfType(Track, class'X2Action_UnitFalling', FallingAction);

	return UnitPawn.GetAnimTreeController().GetAllowNewAnimations() &&
			bPlayDamageAnim &&
		   !bMoving &&
		   !bFalling;
}

function bool IsTimedOut()
{
	return ExecutingTime >= TimeoutSeconds;
}

//@TODO - rmcfall/jbouscher - effect template?
simulated function Name ComputeAnimationToPlay(const string AppendEffectString="")
{	
	local vector vHitDir;
	local float fDot;
	local vector UnitRight;
	local float fDotRight;
	local vector WorldUp;
	local Name AnimName;
	local string AnimString;

	WorldUp.X = 0.0f;
	WorldUp.Y = 0.0f;
	WorldUp.Z = 1.0f;
	
	if (AbilityTemplate != none && AbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Cursor'))
	{
		//Damage from position-based abilities should have their damage direction based on the target location
		`assert( AbilityContext.InputContext.TargetLocations.Length > 0 );
		vHitDir = Unit.GetPawn().Location - AbilityContext.InputContext.TargetLocations[0];
	}
	else if (DamageDealer != none)
	{
		vHitDir = Unit.GetPawn().Location - DamageDealer.Location;
	}
	else
	{
		vHitDir = -Vector(Unit.GetPawn().Rotation);
	}

	vHitDir = Normal(vHitDir);
	m_vMomentum = vHitDir * 500.0f; //@TODO - rmcfall - replace magic number with template field or some other momentum multiplier

	fDot = vHitDir dot vector(Unit.GetPawn().Rotation);
	UnitRight = Vector(Unit.GetPawn().Rotation) cross WorldUp;
	fDotRight = vHitDir dot UnitRight;

	kPerkContent = XGUnit(DamageDealer).GetPawn().GetPerkContent(string(AbilityTemplate.Name));
	if( kPerkContent != none && kPerkContent.TargetActivationAnim.PlayAnimation && !kPerkContent.TargetActivationAnim.AdditiveAnim )
	{
		AnimName = class'XComPerkContent'.static.ChooseAnimationForCover(Unit, kPerkContent.TargetActivationAnim);
	}

	if (AnimName == '')
	{
		if( Unit.IsTurret() )  //@TODO - rmcfall/jbouscher - this selection may need to eventually be based on other factors, such as the current state of the unit
		{
			if( Unit.GetTeam() == eTeam_Alien )
			{
				AnimString = "NO_"$AppendEffectString$"HurtFront_Advent";
			}
			else
			{
				AnimString = "NO_"$AppendEffectString$"HurtFront_Xcom";
			}
		}
		else
		{
			if( abs(fDot) >= abs(fDotRight) )
			{
				if( fDot > 0 )
				{
					AnimString = "HL_"$AppendEffectString$"HurtBack";
				}
				else
				{
					AnimString = "HL_"$AppendEffectString$"HurtFront";
				}
			}
			else
			{
				if( fDotRight > 0 )
				{
					AnimString = "HL_"$AppendEffectString$"HurtRight";
				}
				else
				{
					AnimString = "HL_"$AppendEffectString$"HurtLeft";
				}
			}
		}
	}
	
	AnimName = name(AnimString);
	if( !Unit.GetPawn().GetAnimTreeController().CanPlayAnimation(AnimName) )
	{
		AnimString = "HL_"$AppendEffectString$"HurtFront";
		AnimName = name(AnimString);

		if( !Unit.GetPawn().GetAnimTreeController().CanPlayAnimation(AnimName) )
		{
			// If AppendEffectString is "", then "HL_HurtFrontA" (the default hit fall back) will be checked
			// which should be there. If it isn't then there is an issue with the animation set.

			// If AppendEffectString is not blank, that means the IdleStateMachine is currently locking down
			// the animations for this unit and if the override is not found, then no animation should be played.
			AnimName = '';
		}
	}

	return AnimName;
}

event OnAnimNotify(AnimNotify ReceiveNotify)
{
	local XComAnimNotify_NotifyTarget NotifyTarget;

	super.OnAnimNotify(ReceiveNotify);

	NotifyTarget = XComAnimNotify_NotifyTarget(ReceiveNotify);
	if(NotifyTarget != none)
	{
		//We are hitting someone while playing our damage anim. This must be a counter attack.
		VisualizationMgr.SendInterTrackMessage(CounterAttackTargetRef);		
	}
}

simulated state Executing
{
	simulated event BeginState(name nmPrevState)
	{
		super.BeginState(nmPrevState);
		
		//Rumbles controller
		Unit.CheckForLowHealthEffects();
	}

	//Returns the string we should use to call out damage - potentially using "Burning", "Poison", etc. instead of the default
	simulated function string GetDamageMessage()
	{
		if (X2Effect_Persistent(DamageEffect) != none)
			return X2Effect_Persistent(DamageEffect).FriendlyName;

		if (X2Effect_Persistent(OriginatingEffect) != None)
			return X2Effect_Persistent(OriginatingEffect).FriendlyName;

		if (X2Effect_Persistent(AncestorEffect) != None)
			return X2Effect_Persistent(AncestorEffect).FriendlyName;

		return "";
	}

	simulated function ShowDamageMessage()
	{
		local string UIMessage;

		UIMessage = GetDamageMessage();
		if (UIMessage == "")
			UIMessage = class'XGLocalizedData'.default.HealthDamaged;

		if( m_iShredded > 0 )
		{
			ShowShreddedMessage();
		}
		if( m_iMitigated > 0 )
		{
			ShowMitigationMessage();
		}
		if(m_iShielded > 0)
		{
			ShowShieldedMessage();
		}
		if(m_iDamage > 0)
		{
			ShowHPDamageMessage(UIMessage);
		}

		if( m_iMitigated > 0 && ShouldPlayArmorHitVO())
		{
			Unit.UnitSpeak('ArmorHit');
		}
		else if(m_iShielded > 0 || m_iDamage > 0)
		{
			Unit.UnitSpeak('TakingDamage');
		}
	}

	simulated function ShowCritMessage()
	{
		Unit.UnitSpeak('CriticallyWounded');
		
		if( m_iShredded > 0 )
		{
			ShowShreddedMessage();
		}
		if( m_iMitigated > 0 )
		{
			ShowMitigationMessage();
		}
		if(m_iShielded > 0)
		{
			ShowShieldedMessage();
		}
		if(m_iDamage > 0)
		{
			ShowHPDamageMessage(GetDamageMessage(), class'XGLocalizedData'.default.CriticalHit);
		}
	}

	simulated function ShowGrazeMessage()
	{
		if( m_iShredded > 0 )
		{
			ShowShreddedMessage();
		}
		if( m_iMitigated > 0 )
		{
			ShowMitigationMessage();
		}
		if(m_iShielded > 0)
		{
			ShowShieldedMessage();
		}
		if(m_iDamage > 0)
		{
			ShowHPDamageMessage(class'XGLocalizedData'.default.GrazeHit);
		}

		if( m_iMitigated > 0 && ShouldPlayArmorHitVO())
		{
			Unit.UnitSpeak('ArmorHit');
		}
		else if(m_iShielded > 0 || m_iDamage > 0)
		{
			Unit.UnitSpeak('TakingDamage');
		}
	}

	simulated function ShowHPDamageMessage(string UIMessage, optional string CritMessage)
	{
		local XComUIBroadcastWorldMessage kBroadcastWorldMessage;
		
		kBroadcastWorldMessage = class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), UIMessage, UnitPawn.m_eTeamVisibilityFlags, class'XComUIBroadcastWorldMessage_DamageDisplay', m_iDamage, 0, CritMessage, DamageTypeName == 'Psi'? eWDT_Psi : -1);
		if(kBroadcastWorldMessage != none)
		{
			XComUIBroadcastWorldMessage_DamageDisplay(kBroadcastWorldMessage).Init_DisplayDamage(eUIBWMDamageDisplayType_Hit, m_vHitLocation, Unit.GetVisualizedStateReference(), m_iDamage, UnitPawn.m_eTeamVisibilityFlags);
		}
	}

	simulated function ShowMitigationMessage()
	{
		local int CurrentArmor;
		CurrentArmor = UnitState.GetArmorMitigationForUnitFlag();
		//The flyover shows the armor amount that exists after shred has been applied.
		if (CurrentArmor > 0)
		{
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XGLocalizedData'.default.ArmorMitigation, UnitPawn.m_eTeamVisibilityFlags, class'XComUIBroadcastWorldMessage_DamageDisplay', CurrentArmor, /*modifier*/, /*crit*/, eWDT_Armor);
		}
	}

	simulated function ShowShieldedMessage()
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XGLocalizedData'.default.ShieldedMessage, UnitPawn.m_eTeamVisibilityFlags, class'XComUIBroadcastWorldMessage_DamageDisplay', m_iShielded);
	}

	simulated function ShowShreddedMessage()
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XGLocalizedData'.default.ShreddedMessage, UnitPawn.m_eTeamVisibilityFlags, class'XComUIBroadcastWorldMessage_DamageDisplay', m_iShredded, , , eWDT_Shred);
	}

	simulated function ShowMissMessage()
	{
		if (m_iDamage > 0)
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.MissedMessage, UnitPawn.m_eTeamVisibilityFlags, class'XComUIBroadcastWorldMessage_DamageDisplay', m_iDamage);
		else if (!OriginatingEffect.IsA('X2Effect_Persistent')) //Persistent effects that are failing to cause damage are not noteworthy.
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.MissedMessage);
	}

	simulated function ShowCounterattackMessage()
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.CounterattackMessage);
	}

	simulated function ShowLightningReflexesMessage()
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.LightningReflexesMessage);
	}

	simulated function ShowUntouchableMessage()
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.UntouchableMessage);
	}

	simulated function ShowFreeKillMessage()
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.FreeKillMessage, , , , , , eWDT_Repeater);
	}

	simulated function ShowAttackMessages()
	{			
		local int i;

		if (HitResults.Length == 0 && DamageResults.Length == 0 && bWasHit)
		{
			// Must be damage from World Effects (Fire, Poison, Acid)
			ShowDamageMessage();
		}
		else
		{
			//It seems that misses contain a hit result but no damage results. So fill in some zero / null damage result entries if there is a mismatch.
			if(HitResults.Length > DamageResults.Length)
			{				
				DamageResults.Add(HitResults.Length - DamageResults.Length);				
			}

			for (i = 0; i < HitResults.Length && i < DamageResults.Length; i++) // some abilities damage the same target multiple times
			{
				HitResult = HitResults[i];

				m_iDamage = DamageResults[i].DamageAmount;
				m_iMitigated = DamageResults[i].MitigationAmount;
				m_iShielded = DamageResults[i].ShieldHP;
				m_iShredded = DamageResults[i].Shred;

				if (DamageResults[i].bFreeKill)
				{
					ShowFreeKillMessage();
					return;
				}

				switch (HitResult)
				{
				case eHit_CounterAttack:
					ShowCounterattackMessage();
					break;
				case eHit_LightningReflexes:
					ShowLightningReflexesMessage();
					break;
				case eHit_Untouchable:
					ShowUntouchableMessage();
					break;
				case eHit_Crit:
					ShowCritMessage();
					break;
				case eHit_Graze:
					ShowGrazeMessage();
					break;
				case eHit_Success:
					ShowDamageMessage();
					break;
				default:
					ShowMissMessage();
					break;
				}
			}
		}
	}

	function bool SingleProjectileVolley()
	{
		// Jwats: Melee doesn't have a volley so treat no volley as a single volley
		return XGUnit(DamageDealer).GetPawn().GetAnimTreeController().GetNumProjectileVolleys() <= 1;
	}

	function bool AttackersAnimUsesWeaponVolleyNotify()
	{
		local array<AnimNotify_FireWeaponVolley> OutNotifies;
		local array<float> OutNotifyTimes;

		XGUnit(DamageDealer).GetPawn().GetAnimTreeController().GetFireWeaponVolleyNotifies(OutNotifies, OutNotifyTimes);
		return (OutNotifies.length > 0);
	}

	function DoTargetAdditiveAnims()
	{
		local name TargetAdditiveAnim;
		local CustomAnimParams CustomAnim;

		CustomAnim.Additive = true;
		foreach TargetAdditiveAnims(TargetAdditiveAnim)
		{
			CustomAnim.AnimName = TargetAdditiveAnim;
			UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(CustomAnim);
		}
	}

	function UnDoTargetAdditiveAnims()
	{
		local name TargetAdditiveAnim;
		local CustomAnimParams CustomAnim;

		CustomAnim.Additive = true;
		CustomAnim.TargetWeight = 0.0f;
		foreach TargetAdditiveAnims(TargetAdditiveAnim)
		{
			CustomAnim.AnimName = TargetAdditiveAnim;
			UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(CustomAnim);
		}
	}

Begin:
	if (!bHiddenAction)
	{
		GroupState = UnitState.GetGroupMembership();
		if( GroupState != None )
		{
			for( ScanGroup = 0; ScanGroup < GroupState.m_arrMembers.Length; ++ScanGroup )
			{
				ScanUnit = XGUnit(`XCOMHISTORY.GetVisualizer(GroupState.m_arrMembers[ScanGroup].ObjectID));
				if( ScanUnit != None )
				{
					ScanUnit.VisualizedAlertLevel = eAL_Red;
					ScanUnit.IdleStateMachine.CheckForStanceUpdateOnIdle();
				}
			}
		}

		ShowAttackMessages(); 

		if( bWasHit || m_iDamage > 0 || m_iMitigated > 0)       //  misses can deal damage
		{
			`PRES.m_kUnitFlagManager.RespondToNewGameState(Unit, AbilityContext.GetLastStateInInterruptChain(), true);

			// The unit was hit but may be locked in a persistent CustomIdleOverrideAnim state
			// Check to see if we need to temporarily suspend that to play a reaction
			OverrideOldUnitState = XComGameState_Unit(Track.StateObject_OldState);
			bDoOverrideAnim = class'X2StatusEffects'.static.GetHighestEffectOnUnit(OverrideOldUnitState, OverridePersistentEffectTemplate, true);

			OverrideAnimEffectString = "";
			if( bDoOverrideAnim )
			{
				// Allow new animations to play
				UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
				OverrideAnimEffectString = string(OverridePersistentEffectTemplate.EffectName);
			}

			if (ShouldPlayAnimation())
			{
				// Particle effects should only play when the animation plays.  mdomowicz 2015_07_08
				// Update: if the attacker's animation uses AnimNotify_FireWeaponVolley, the hit effect will play 
				// via X2UnifiedProjectile, so in that case we should skip the hit effect here.  mdomowicz 2015_07_29
				if (!AttackersAnimUsesWeaponVolleyNotify())
				{
					UnitPawn.PlayHitEffects(m_iDamage, DamageDealer, m_vHitLocation, DamageTypeName, m_vMomentum, bIsUnitRuptured);
				}

				Unit.ResetWeaponsToDefaultSockets();
				AnimParams.AnimName = ComputeAnimationToPlay(OverrideAnimEffectString);

				if( AnimParams.AnimName != '' )
				{
					AnimParams.PlayRate = GetMoveAnimationSpeed();
					PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
				}

				kPerkContent = XGUnit(DamageDealer).GetPawn().GetPerkContent(string(AbilityTemplate.Name));
				if( kPerkContent != none && kPerkContent.TargetActivationAnim.PlayAnimation && kPerkContent.TargetActivationAnim.AdditiveAnim )
				{
					AnimParams.AnimName = class'XComPerkContent'.static.ChooseAnimationForCover(Unit, kPerkContent.TargetActivationAnim);
					UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(AnimParams);
				}
				DoTargetAdditiveAnims();
			}
			else if( bMoving && RunningAction != None )
			{
				RunningAction.TriggerRunFlinch();
			}
			else
			{
				`log("HurtAnim not playing", , 'XCom_Visualization');
			}

			if( !bGoingToDie && !bSkipWaitForAnim)
			{
				if( Track.TrackActor.CustomTimeDilation < 1.0 )
				{
					Sleep(PlayingSequence.AnimSeq.SequenceLength * PlayingSequence.Rate * Track.TrackActor.CustomTimeDilation);
				}
				else
				{
					FinishAnim(PlayingSequence);
				}
				bShouldContinueAnim = false;
			}

			if (`BATTLE.GetAIPlayer() != None)
			{
				XGAIPlayer(`BATTLE.GetAIPlayer()).OnTakeDamage(Unit.ObjectID, m_iDamage, none);
			}

			if( bDoOverrideAnim )
			{
				// Turn off new animation playing
				UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
			}
		}
		else
		{
			if (ShouldPlayAnimation())
			{
				if(bCounterAttackAnim)
				{
					AnimParams.AnimName = 'HL_Counterattack';					
				}
				else
				{
					Unit.ResetWeaponsToDefaultSockets();

					if( Unit.IsTurret() )  //@TODO - rmcfall/jbouscher - this selection may need to eventually be based on other factors, such as the current state of the unit
					{
						if( Unit.GetTeam() == eTeam_Alien )
						{
							AnimParams.AnimName = 'NO_Flinch_Advent';
						}
						else
						{
							AnimParams.AnimName = 'NO_Flinch_Xcom';
						}
					}
					else
					{
						switch( Unit.m_eCoverState )
						{
						case eCS_LowLeft:
						case eCS_HighLeft:
							AnimParams.AnimName = 'HL_Flinch';
							break;
						case eCS_LowRight:
						case eCS_HighRight:
							AnimParams.AnimName = 'HR_Flinch';
							break;
						case eCS_None:
							// Jwats: No cover randomizes between the 2 animations
							if( Rand(2) == 0 )
							{
								AnimParams.AnimName = 'HL_Flinch';
							}
							else
							{
								AnimParams.AnimName = 'HR_Flinch';
							}
							break;
						}
					}
				}				

				PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
				DoTargetAdditiveAnims();
			}
			else if( bMoving && RunningAction != None )
			{
				RunningAction.TriggerRunFlinch();
			}
			else
			{
				`log("DodgeAnim not playing");
			}

			if( !bGoingToDie )
			{
				if( Track.TrackActor.CustomTimeDilation < 1.0 )
				{
					Sleep(PlayingSequence.AnimSeq.SequenceLength * PlayingSequence.Rate * Track.TrackActor.CustomTimeDilation);
				}
				else
				{
					FinishAnim(PlayingSequence);
				}
				bShouldContinueAnim = false;
			}

			if (!bWasCounterAttack)
			{
				Unit.UnitSpeak('TakingFire');
			}

			if (Unit.m_kBehavior != none)
			{
				Unit.m_kBehavior.OnTakeFire();
			}			
		}

		if( !bMoving )
		{
			if( PlayingSequence != None && !bGoingToDie )
			{
				Sleep(0.0f);
				while( bShouldContinueAnim )
				{
					PlayingSequence.ReplayAnim();
					FinishAnim(PlayingSequence);
					bShouldContinueAnim = false;
					Sleep(0.0f); // Wait to see if another projectile comes
				}
			}
			else if( PlayingSequence != None && bGoingToDie )
			{
				//Only play the hit react if there is more than one projectile volley
				if( !SingleProjectileVolley() )
				{
					Sleep(HitReactDelayTimeToDeath * GetDelayModifier()); // Let the hit react play for a little bit before we CompleteAction to go to death
				}
			}
		}
	}

	kPerkContent = XGUnit(DamageDealer).GetPawn().GetPerkContent(string(AbilityTemplate.Name));
	if( kPerkContent != none && kPerkContent.TargetActivationAnim.PlayAnimation && kPerkContent.TargetActivationAnim.AdditiveAnim )
	{
		AnimParams.AnimName = class'XComPerkContent'.static.ChooseAnimationForCover(Unit, kPerkContent.TargetActivationAnim);
		UnitPawn.GetAnimTreeController().RemoveAdditiveDynamicAnim(AnimParams);
	}
	UnDoTargetAdditiveAnims();

	CompleteAction();
}

DefaultProperties
{
	TimeoutSeconds = 8.0f
	bDoOverrideAnim=false
	bPlayDamageAnim = true
	bCauseTimeDilationWhenInterrupting = true
}
