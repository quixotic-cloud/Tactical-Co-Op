class XComPerkContent extends Actor
	dependson(XGUnitNativeBase)
	native(Unit)
	notplaceable
	HideCategories(Movement,Display,Attachment,Actor,Collision,Physics,Advanced,Debug);

struct native TParticleContentParameters
{
	var() array<name> AssociatedCharacters<DynamicList = "AssociatedCharacterList">;
	var() EmitterInstanceParameterSet EmitterInstanceParameters;
};

struct native TParticleContent
{
	var() ParticleSystem FXTemplate;
	var() name FXTemplateSocket;
	var() name FXTemplateBone;
	var() float Delay;
	var() bool SetActorParameter;
	var() name SetActorName<EditCondition=SetActorParameter>;
	var() bool ForceRemoveOnDeath;
	var(InstanceParameters) array<TParticleContentParameters> CharacterParameters;
};

struct native TAnimContent
{
	var() bool PlayAnimation;
	var() name NoCoverAnim<EditCondition=PlayAnimation>;
	var() name HighCoverAnim<EditCondition=PlayAnimation>;
	var() name LowCoverAnim<EditCondition=PlayAnimation>;
	var() bool AdditiveAnim<EditCondition=PlayAnimation>;
};

// just want need a 2D Array and unreal script won't do that directly
struct native TTargetParticles
{
	var init array< ParticleSystemComponent > Particles;
};

var(General) privatewrite name AssociatedAbility<DynamicList = "AssociatedAbilityList">;
var(General) privatewrite name AssociatedEffect<DynamicList="AssociatedEffectList">;
var(General) privatewrite name AssociatedPassive<DynamicList="AssociatedPassiveList">;
var(General) privatewrite bool ExclusivePerk <ToolTip="Prevent other perks associated with this ability from triggering if this one triggers.">;
var(General) const array<AnimSet> AnimSetsToAlwaysApply<ToolTip="AnimSets that will always be applied to the owner of this perk.">;
var(General) const array<Object> AdditionalResources<ToolTip="Additional resources that need to be loaded for this perk.">;
var(General) privatewrite bool ActivatesWithAnimNotify<ToolTip="Activation for this perk should wait on an AnimNotify_PerkStart being hit.">;
var(General) privatewrite bool TargetEffectsOnProjectileImpact<ToolTip="Wait to trigger TargetActivation and TargetDuration effects until a projectile impact occurs.">;
var(General) privatewrite bool UseTargetPerkScale<ToolTip="Scale all target effects by the PerkScale factor of the target's pawn PerkScale member.">;
var(General) privatewrite bool IgnoreCasterAsTarget<ToolTip="If the caster is in the target list, do not give it the target FX.">;
var(General) privatewrite bool TargetDurationFXOnly<ToolTip="If true, this perk has duration FX but only for the Targets, not the Caster.">;
var(General) privatewrite bool CasterDurationFXOnly<ToolTip="If true, this perk has duration FX but only for the Caster, not the Targets.">;

var(CasterPersistent) array<TParticleContent> PersistentCasterFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(CasterPersistent) array<TParticleContent> EndPersistentCasterFX<EditCondition=EndPersistentFXOnDeath|ToolTip="Delay data is unused. End FX's will always start immediately.">;
var(CasterPersistent) bool EndPersistentFXOnDeath;
var(CasterPersistent) bool DisablePersistentFXDuringActivation;
var(CasterPersistent) SoundCue CasterPersistentSound;
var(CasterPersistent) SoundCue CasterPersistentEndSound<EditCondition=EndPersistentFXOnDeath>;

var(CasterActivation) array<TParticleContent> CasterActivationFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(CasterActivation) TAnimContent CasterActivationAnim;
var(CasterActivation) XComWeapon PerkSpecificWeapon;
var(CasterActivation) name WeaponTargetBone;
var(CasterActivation) name WeaponTargetSocket;
var(CasterActivation) editinline AnimNotify_MITV CasterActivationMITV;
var(CasterActivation) SoundCue CasterActivationSound;
var(CasterActivation) X2UnifiedProjectile CasterProjectile;

var(CasterDuration) array<TParticleContent> CasterDurationFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(CasterDuration) array<TParticleContent> CasterDurationEndedFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(CasterDuration) TAnimContent CasterDurationEndedAnim;
var(CasterDuration) editinline AnimNotify_MITV CasterDurationEndedMITV;
var(CasterDuration) SoundCue CasterDurationSound;
var(CasterDuration) SoundCue CasterDurationEndSound;
var(CasterDuration) bool ManualFireNotify;
var(CasterDuration) float FireVolleyDelay <EditCondition=ManualFireNotify>;
var(CasterDuration) editinline AnimNotify_FireWeaponVolley FireWeaponNotify <EditCondition=ManualFireNotify>;

var(CasterDeactivation) array<TParticleContent> CasterDeactivationFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(CasterDeactivation) SoundCue CasterDeactivationSound;
var(CasterDeactivation) bool ResetCasterActivationMTIVOnDeactivate;

var(CasterDamage) array<TParticleContent> CasterOnDamageFX<ToolTip="Delay data is unused. Damage FX's will always start immediately.">;
var(CasterDamage) bool OnCasterDeathPlayDamageFX;
var(CasterDamage) SoundCue CasterOnDamageSound;
var(CasterDamage) editinline AnimNotify_MITV CasterDamageMITV;
var(CasterDamage) array<TParticleContent> CasterOnMetaDamageFX<ToolTip="This damage FX plays once per volley, rather than with every projectile.">;

var(TargetActivation) array<TParticleContent> TargetActivationFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(TargetActivation) TAnimContent TargetActivationAnim;
var(TargetActivation) editinline AnimNotify_MITV TargetActivationMITV;
var(TargetActivation) SoundCue TargetActivationSound;
var(TargetActivation) SoundCue TargetLocationsActivationSound;

var(TargetDuration) array<TParticleContent> TargetDurationFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(TargetDuration) array<TParticleContent> TargetDurationEndedFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(TargetDuration) TAnimContent TargetDurationEndedAnim;
var(TargetDuration) editinline AnimNotify_MITV TargetDurationEndedMITV;
var(TargetDuration) SoundCue TargetDurationSound;
var(TargetDuration) SoundCue TargetDurationEndSound;
var(TargetDuration) SoundCue TargetLocationsDurationSound;
var(TargetDuration) SoundCue TargetLocationsDurationEndSound;

var(TargetDeactivation) array<TParticleContent> TargetDeactivationFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(TargetDeactivation) SoundCue TargetDeactivationSound;
var(TargetDeactivation) SoundCue TargetLocationsDeactivationSound;

var(TargetDamage) array<TParticleContent> TargetOnDamageFX<ToolTip="Delay data is unused. Damage FX's will always start immediately.">;
var(TargetDamage) bool OnTargetDeathPlayDamageFX;
var(TargetDamage) SoundCue TargetOnDamageSound;
var(TargetDamage) editinline AnimNotify_MITV TargetDamageMITV;

var(Tethers) array<TParticleContent> TetherStartupFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(Tethers) array<TParticleContent> TetherToTargetFX<ToolTip="Only the delay value for element 0 is used.  All effects will start at the same time as element 0.">;
var(Tethers) array<TParticleContent> TetherShutdownFX<ToolTip="Delay data is unused. Shutdown FX's will always start immediately">;
var(Tethers) name TargetAttachmentSocket;
var(Tethers) name TargetAttachmentBone;

var private init array<ParticleSystemComponent> m_PersistentParticles; // active particle systems matching PersistentCasterFX
var private init array<ParticleSystemComponent> m_PersistentEndParticles; // active particle systems matching EndPersistentCasterFX
var private init array<ParticleSystemComponent> m_CasterActivationParticles; // active particle systems matching CasterActivationFX
var private init array<ParticleSystemComponent> m_CasterDurationParticles; // active particle systems matching CasterDurationFX
var private init array<ParticleSystemComponent> m_CasterDurationEndedParticles; // active particle systems matching CasterDurationEndedFX
var private init array<ParticleSystemComponent> m_CasterDeactivationParticles; // active particle systems matching CasterDeactivationFX
var private init array<ParticleSystemComponent> m_CasterOnDamageParticles; // active particle systems matching CasterOnDamageFX
var private init array<ParticleSystemComponent> m_CasterOnMetaDamageParticles; // active particle systems matching CasterOnMetaDamageFX

var private init array< TTargetParticles > m_TargetActivationParticles; // active particle systems matching TargetActivationFX
var private init array< TTargetParticles > m_TargetDurationParticles; // active particle systems matching TargetDurationFX
var private init array< TTargetParticles > m_TargetDurationEndedParticles; // active particle systems matching TargetDurationEndedFX
var private init array< TTargetParticles > m_TargetDeactivationParticles; // active particle systems matching TargetDeactivationFX
var private init array< TTargetParticles > m_TargetOnDamageParticles; // active particle systems matching TargetOnDamageFX

var private init array< AnimNotify_MITV > m_TargetActivationMITVs; // instanced MITVs because Unreal timers suck a bit
var private init array< AnimNotify_MITV > m_TargetDurationEndedMITVs; // instanced MITVs because Unreal timers suck a bit
var private init array< AnimNotify_MITV > m_TargetDamagedMITVs; // instanced MITVs because Unreal timers suck a bit

var private init array< TTargetParticles > m_TetherParticles; // active particle systems matching TetherToTargetFX
var private init array< DynamicPointInSpace > m_TetherAttachmentActors;

var private init array< DynamicPointInSpace > m_LocationActivationSounds;
var private init array< DynamicPointInSpace > m_LocationDeactivationSounds;
var private init array< DynamicPointInSpace > m_LocationDurationSounds;
var private init array< DynamicPointInSpace > m_LocationDurationEndSounds;

var privatewrite XGUnit m_kUnit;
var privatewrite XComUnitPawn m_kPawn;

var privatewrite init array<XGUnit> m_arrTargets;
var privatewrite init array<XComUnitPawn> m_arrTargetPawns;
var privatewrite init array<vector> m_arrTargetLocations;
var privatewrite init array<XGUnit> m_arrAppendTargets;
var privatewrite init array<XComUnitPawn> m_arrAppendTargetPawns;
var privatewrite init array<vector> m_arrAppendTargetLocations;
var privatewrite int m_ActiveTargetCount;
var privatewrite int m_ActiveLocationCount;
var privatewrite bool m_ShooterEffect;

var private XComWeapon m_kWeapon;
var private bool m_RecievedImpactEvent;

cpptext
{
public:
	virtual void GetDynamicListValues(const FString& ListName, TArray<FString>& Values);
}

simulated protected native function PrepTargetMITVs( bool ActivationSet );
simulated protected native function bool PrepTargetDamagedMITV( int TargetIndex );
simulated protected native function PlaySoundCue( Actor kPawn, SoundCue Sound );
simulated protected native function StopSoundCue( Actor kPawn, SoundCue Sound );

simulated protected function array< ParticleSystemComponent > AppendArray( array< ParticleSystemComponent > DestParticles, array< ParticleSystemComponent > SrcParticles  )
{
	local ParticleSystemComponent System;

	foreach SrcParticles( System )
	{
		DestParticles.AddItem( System );
	}

	return DestParticles;
}

simulated protected function PlayTargetsSoundCues( SoundCue Sound, array<XComUnitPawn> Pawns )
{
	local XComUnitPawn Target;

	foreach Pawns( Target )
	{
		PlaySoundCue( Target, Sound );
	}
}

simulated protected function StopTargetsSoundCues( SoundCue Sound, array<XComUnitPawn> Pawns )
{
	local XComUnitPawn Target;

	foreach Pawns( Target )
	{
		StopSoundCue( Target, Sound );
	}
}

simulated protected function PlayTargetLocationSoundCue( SoundCue Sound, array<vector> Locations, out array< DynamicPointInSpace > LocationActors )
{
	local vector Loc;
	local DynamicPointInSpace DummyActor;

	if (Sound == none)
	{
		return;
	}

	foreach Locations(Loc)
	{
		DummyActor = Spawn( class'DynamicPointInSpace', self );
		DummyActor.SetLocation( Loc );
		PlaySoundCue( DummyActor, Sound );

		LocationActors.AddItem( DummyActor );
	}
}

simulated protected function StopTargetLocationSoundCue( out array< DynamicPointInSpace > LocationActors )
{
	local DynamicPointInSpace Dummy;

	foreach LocationActors( Dummy )
	{
		Dummy.Destroy();
	}
	LocationActors.Length = 0;
}

static function EmitterInstanceParameterSet GetEmitterInstanceParametersForParticleContent(const out TParticleContent Content, XComUnitPawn kPawn)
{
	local XComGameState_Unit UnitState;
	local XGUnit Unit;
	local EmitterInstanceParameterSet DefaultParameters;
	local int i;

	//  Try to find the character template that matches the pawn
	//  If instance parameters are defined with no associated character type, that is the default to fall back to
	if (Content.CharacterParameters.Length > 0)
	{
		Unit = XGUnit(kPawn.GetGameUnit());
		if (Unit != none)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID));
			if (UnitState != none)
			{
				for (i = 0; i < Content.CharacterParameters.Length; ++i)
				{
					if (Content.CharacterParameters[i].AssociatedCharacters.Length == 0)
					{
						DefaultParameters = Content.CharacterParameters[i].EmitterInstanceParameters;
						continue;
					}
					if (Content.CharacterParameters[i].AssociatedCharacters.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
					{
						return Content.CharacterParameters[i].EmitterInstanceParameters;
					}
				}
			}
		}
	}

	return DefaultParameters;
}

simulated protected function StartParticleSystem(XComUnitPawn kPawn, TParticleContent Content, out ParticleSystemComponent kComponent, bool sync = false)
{
	local EmitterInstanceParameterSet ParameterSet;

	if (Content.FXTemplate != none)
	{
		if (kComponent != none)
		{
			if (kComponent.bIsActive)
			{
				kComponent.DeactivateSystem();
			}
		}
		else
		{
			kComponent = new(self) class'ParticleSystemComponent';
		}

		kComponent.SetTickGroup( TG_EffectsUpdateWork );
				
		ParameterSet = GetEmitterInstanceParametersForParticleContent(Content, kPawn);
		if (ParameterSet != none)
		{
			kComponent.InstanceParameters = ParameterSet.InstanceParameters;
		}		
		kComponent.SetTemplate(Content.FXTemplate);

		if (kPawn != none)
		{
			if (Content.SetActorParameter)
			{
				kComponent.SetActorParameter( Content.SetActorName, kPawn );
			}

			if ((Content.FXTemplateSocket != '') && (kPawn.Mesh.GetSocketByName( Content.FXTemplateSocket ) != none))
			{
				kPawn.Mesh.AttachComponentToSocket( kComponent, Content.FXTemplateSocket );
			}
			else if ((Content.FXTemplateBone != '') && (kPawn.Mesh.MatchRefBone( Content.FXTemplateBone ) != INDEX_None))
			{
				kPawn.Mesh.AttachComponent( kComponent, Content.FXTemplateBone );
			}
			else
			{
				if ((Content.FXTemplateSocket != '') || (Content.FXTemplateBone != ''))
				{
					`log("WARNING: could not find socket '" $ Content.FXTemplateSocket $ "' or bone '" $ Content.FXTemplateBone $ "' to attach particle component on" @ kPawn);
				}

				kPawn.AttachComponent( kComponent );
			}
		}
		else
		{
			self.AttachComponent( kComponent );
		}

		kComponent.OnSystemFinished = PerkFinished;
		kComponent.SetActive(true);

		if (sync)
		{
			kComponent.JumpForward( 5.0f );
		}
	}
}

simulated function StartTargetParticleSystem(XComUnitPawn kPawn, TParticleContent Content, out ParticleSystemComponent kComponent, bool sync = false)
{
	StartParticleSystem(kPawn, Content, kComponent, sync);

	if (UseTargetPerkScale && kPawn.PerkEffectScale != 1.0)
	{
		kComponent.SetScale( kPawn.PerkEffectScale );
	}
}

simulated function name GetAbilityName( )
{
	return AssociatedAbility;
}

simulated function ReassociateToAbility( name AbilityName )
{
	AssociatedAbility = AbilityName;
}

simulated function StartPersistentFX(XComUnitPawn kPawn)
{
	local X2AbilityTemplate Ability;

	m_kPawn = kPawn;
	StartCasterParticleFX( PersistentCasterFX, m_PersistentParticles );
	PlaySoundCue( m_kPawn, CasterPersistentSound );

	Ability = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AssociatedAbility);
	if (Ability.bIsPassive && (CasterOnDamageFX.Length > 0))
	{
		m_kPawn.arrTargetingPerkContent.AddItem( self );
	}
}

simulated function StopPersistentFX( )
{
	local X2AbilityTemplate Ability;

	EndCasterParticleFX( PersistentCasterFX, m_PersistentParticles );
	StopSoundCue( m_kPawn, CasterPersistentSound );

	Ability = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager( ).FindAbilityTemplate( AssociatedAbility );
	if (Ability.bIsPassive && (CasterOnDamageFX.Length > 0))
	{
		m_kPawn.arrTargetingPerkContent.RemoveItem( self );
	}
}

simulated function OnPawnDeath()
{
	if (EndPersistentFXOnDeath)
	{
		StopPersistentFX();
		StartCasterParticleFX( EndPersistentCasterFX, m_PersistentEndParticles );
		PlaySoundCue( m_kPawn, CasterPersistentEndSound );
	}

	GotoState( 'Idle' );
}

simulated function XComWeapon GetPerkWeapon()
{
	if (m_kWeapon == none && PerkSpecificWeapon != none)
	{
		m_kWeapon = Spawn(class'XComWeapon',m_kPawn,,,,PerkSpecificWeapon);
		m_kWeapon.m_kPawn = m_kPawn;
		m_kPawn.Mesh.AttachComponentToSocket( m_kWeapon.Mesh, m_kWeapon.DefaultSocket );
	}

	return m_kWeapon;
}

simulated function AddPerkTarget(XGUnit kUnit, bool sync = false)
{
	local int i, x;
	local bool bFound;
	local ParticleSystemComponent TempParticles;
	local array<ParticleSystemComponent> NewParticles;
	local TParticleContent Content;

	if (m_arrTargets.Find(kUnit) == -1)
	{
		//  look for an empty space to replace if possible
		for (i = 0; i < m_arrTargets.Length; ++i)
		{
			if (m_arrTargets[i] == none)
			{
				bFound = true;
				break;
			}
		}
		//  add to the end if no empty space was found
		if (!bFound)
		{
			m_TargetActivationParticles.Add(1);
			m_TargetDeactivationParticles.Add(1);
			m_TargetDurationParticles.Add(1);
			m_arrTargets.Add(1);
			m_arrTargetPawns.Add(1);
			m_TetherAttachmentActors.Add(1);
			m_TetherParticles.Add(1);
		}

		m_arrTargets[i] = kUnit;
		m_arrTargetPawns[i] = kUnit.GetPawn();
		++m_ActiveTargetCount;

		if (IsInState( 'DurationActive' ))
		{
			if (sync == false)
			{
				m_TargetActivationParticles[i].Particles.Length = TargetActivationFX.Length;
				for (x = 0; x < TargetActivationFX.Length; ++x)
				{
					Content = TargetActivationFX[ x ];

					if ((Content.FXTemplate != none) && (Content.FXTemplateBone != '' || Content.FXTemplateSocket != ''))
					{
						TempParticles = m_TargetActivationParticles[ i ].Particles[ x ];
						StartTargetParticleSystem( m_arrTargetPawns[ i ], Content, TempParticles );
						m_TargetActivationParticles[ i ].Particles[ x ] = TempParticles;
					}
				}
				PlaySoundCue( m_arrTargetPawns[ i ], TargetActivationSound );
			}

			m_TargetDurationParticles[i].Particles.Length = TargetDurationFX.Length;
			for (x = 0; x < TargetDurationFX.Length; ++x)
			{
				Content = TargetDurationFX[ x ];

				if ((Content.FXTemplate != none) && (Content.FXTemplateBone != '' || Content.FXTemplateSocket != ''))
				{
					TempParticles = m_TargetDurationParticles[ i ].Particles[ x ];
					StartTargetParticleSystem( m_arrTargetPawns[ i ], Content, TempParticles, sync );
					m_TargetDurationParticles[ i ].Particles[ x ] = TempParticles;
				}
			}
			PlaySoundCue( m_arrTargetPawns[ i ], TargetDurationSound );

			if (TetherToTargetFX.Length != 0)
			{
				m_TetherAttachmentActors[i] = Spawn( class'DynamicPointInSpace', self );
				UpdateAttachmentLocations( );

				StartCasterParticleFX( TetherToTargetFX, NewParticles );

				m_TetherParticles[ i ].Particles = AppendArray( m_TetherParticles[ i ].Particles, NewParticles );

				UpdateTetherParticleParams( );
			}

			m_arrTargetPawns[ i ].arrTargetingPerkContent.AddItem( self );
		}
	}
}

simulated function RemovePerkTarget(XGUnit kUnit)
{
	local int i, x;
	local ParticleSystemComponent TempParticles;
	local ParticleSystemComponent ParticleSystem;
	local TParticleContent Content;
	local array<ParticleSystemComponent> NewShutdownParticles;
	local XComGameState_Unit VisualizedUnit;
	local bool bVisualizedUnitIsDead;

	i = m_arrTargets.Find(kUnit);
	if (i != -1)
	{
		VisualizedUnit = kUnit.GetVisualizedGameState();
		bVisualizedUnitIsDead = VisualizedUnit.IsDead();
		if (IsInState( 'DurationActive' ))
		{
			if ( i >= m_TargetDurationEndedParticles.Length )
				m_TargetDurationEndedParticles.Length = i + 1;

			m_TargetDurationEndedParticles[ i ].Particles.Length = TargetDurationEndedFX.Length;
			for (x = 0; x < TargetDurationEndedFX.Length; ++x)
			{
				Content = TargetDurationEndedFX[ x ];

				if ((Content.FXTemplate != none) && (Content.FXTemplateBone != '' || Content.FXTemplateSocket != ''))
				{
					TempParticles = m_TargetDurationEndedParticles[ i ].Particles[ x ];
					StartParticleSystem( m_arrTargetPawns[ i ], Content, TempParticles );
					m_TargetDurationEndedParticles[ i ].Particles[ x ] = TempParticles;
				}
			}
			PlaySoundCue( m_arrTargetPawns[ i ], TargetDurationEndSound );

			`assert(TargetDurationFX.Length == m_TargetDurationParticles[i].Particles.Length);
			for (x = 0; x < m_TargetDurationParticles[i].Particles.Length; ++x)
			{
				if (m_TargetDurationParticles[i].Particles[x] != none && m_TargetDurationParticles[i].Particles[x].bIsActive)
					m_TargetDurationParticles[i].Particles[x].DeactivateSystem(TargetDurationFX[x].ForceRemoveOnDeath && bVisualizedUnitIsDead);
			}

			m_arrTargetPawns[ i ].arrTargetingPerkContent.RemoveItem( self );
			StopSoundCue( m_arrTargetPawns[ i ], TargetDurationSound );

			if (TetherToTargetFX.Length != 0)
			{
				foreach m_TetherParticles[i].Particles( ParticleSystem )
				{
					if (ParticleSystem != none)
					{
						ParticleSystem.DeactivateSystem( );
					}
				}

				StartCasterParticleFX( TetherShutdownFX, NewShutdownParticles );
				m_TetherParticles[i].Particles = AppendArray( m_TetherParticles[i].Particles, NewShutdownParticles );

				UpdateTetherParticleParams( );

				m_TetherAttachmentActors[i].Destroy( );
			}
			else if (IsInState( 'ActionActive' ))
			{
				m_TargetDeactivationParticles[ i ].Particles.Length = TargetDeactivationFX.Length;
				for (x = 0; x < TargetDeactivationFX.Length; ++x)
				{
					Content = TargetDeactivationFX[ x ];

					if ((Content.FXTemplate != none) && (Content.FXTemplateBone != '' || Content.FXTemplateSocket != ''))
					{
						TempParticles = m_TargetDeactivationParticles[ i ].Particles[ x ];
						StartParticleSystem( m_arrTargetPawns[ i ], Content, TempParticles );
						m_TargetDeactivationParticles[ i ].Particles[ x ] = TempParticles;
					}
				}
				PlaySoundCue( m_arrTargetPawns[ i ], TargetDeactivationSound );
			}
		}

		//  Do NOT remove from the array to keep the particle array in sync with the other targets
		m_arrTargets[i] = none;
		m_arrTargetPawns[i] = none;
		--m_ActiveTargetCount;

		if (IsInState( 'DurationActive' ) && (m_ActiveTargetCount == 0) && (m_ActiveLocationCount == 0))
		{
			OnPerkDurationEnd( );
		}
	}
}

simulated function ReplacePerkTarget( XGUnit oldUnitTarget, XGUnit newUnitTarget )
{
	local int i, x;
	local TParticleContent Content;
	local ParticleSystemComponent TempParticles;

	i = m_arrTargets.Find( oldUnitTarget );
	if (i != -1)
	{
		m_arrTargetPawns[ i ].arrTargetingPerkContent.RemoveItem( self );
		StopSoundCue( m_arrTargetPawns[ i ], TargetDurationSound );

		m_arrTargets[ i ] = newUnitTarget;
		m_arrTargetPawns[ i ] = newUnitTarget.GetPawn();
		m_arrTargetPawns[ i ].arrTargetingPerkContent.AddItem( self );

		//We may not have gotten a chance to start the particles "normally". Make sure there's room in the array.
		//(Otherwise, UnrealScript will happily plow through the None access, losing the reference to the particles.)
		if (i >= m_TargetDurationParticles.Length)
			m_TargetDurationParticles.Length = i + 1;

		m_TargetDurationParticles[ i ].Particles.Length = TargetDurationFX.Length;
		for (x = 0; x < TargetDurationFX.Length; ++x)
		{
			Content = TargetDurationFX[ x ];

			if ((Content.FXTemplate != none) && (Content.FXTemplateBone != '' || Content.FXTemplateSocket != ''))
			{
				TempParticles = m_TargetDurationParticles[ i ].Particles[ x ];
				StartTargetParticleSystem( m_arrTargetPawns[ i ], Content, TempParticles );
				m_TargetDurationParticles[ i ].Particles[ x ] = TempParticles;
			}
		}
		PlaySoundCue( m_arrTargetPawns[ i ], TargetDurationSound );

		if (TetherToTargetFX.Length != 0)
		{
			UpdateAttachmentLocations( );
			UpdateTetherParticleParams( );
		}
	}
	else
	{
		AddPerkTarget( newUnitTarget );
	}
}

simulated function OnPerkLoad( XGUnit kUnit, array<XGUnit> arrTargets, array<vector> arrLocations, bool ShooterEffect )
{
	`assert( false ); //Definitely shouldn't make it here!
}

simulated function OnPerkActivation(XGUnit kUnit, array<XGUnit> arrTargets, array<vector> arrLocations, bool ShooterEffect)
{
}

simulated function OnPerkDeactivation( )
{
}

simulated function OnPerkDurationEnd()
{
}

simulated protected function OnTargetDamaged(XComUnitPawn Pawn)
{
	local int i, x;
	local ParticleSystemComponent TempParticles;

	i = m_arrTargetPawns.Find( Pawn );
	if (i != -1)
	{
		if (TargetOnDamageFX.Length > 0)
		{
			// make sure that the targets array has that index available
			if (i >= m_TargetOnDamageParticles.Length)
			{
				m_TargetOnDamageParticles.Length = i + 1;
			}

			// play all the appropriate effects on that particular target
			m_TargetOnDamageParticles[ i ].Particles.Length = TargetOnDamageFX.Length;
			for (x = 0; x < TargetOnDamageFX.Length; ++x)
			{
				if (TargetOnDamageFX[ x ].FXTemplate != none)
				{
					TempParticles = m_TargetOnDamageParticles[ i ].Particles[ x ];
					StartParticleSystem( Pawn, TargetOnDamageFX[ x ], TempParticles );
					m_TargetOnDamageParticles[ i ].Particles[ x ] = TempParticles;
				}
			}

			PlaySoundCue( Pawn, TargetOnDamageSound );
		}

		if (TargetDamageMITV != none)
		{
			if (PrepTargetDamagedMITV(i))
			{
				m_TargetDamagedMITVs[i].ApplyMITV( Pawn );
			}
		}
	}
}

simulated function OnDamage( XComUnitPawn Pawn )
{
	if (Pawn == m_kPawn)
	{
		DoCasterParticleFXOnDamage( );
		PlaySoundCue( Pawn, CasterOnDamageSound );

		if (CasterDamageMITV != none)
		{
			CasterDamageMITV.ApplyMITV( m_kPawn );
		}
	}
	else
	{
		OnTargetDamaged( Pawn );
	}
}

simulated function OnMetaDamage( XComUnitPawn Pawn )
{
	if (Pawn == m_kPawn)
	{
		DoCasterParticleFXOnMetaDamage();
	}
}

simulated protected function StartCasterParticleFX( const array<TParticleContent> FX, out array<ParticleSystemComponent> Particles, bool sync = false )
{
	local int i;
	local ParticleSystemComponent TempParticles;

	if (m_kPawn != none)
	{
		Particles.Length = FX.Length;
		for (i = 0; i < FX.Length; ++i)
		{
			if (FX[ i ].FXTemplate != none)
			{
				TempParticles = Particles[ i ];
				StartParticleSystem( m_kPawn, FX[ i ], TempParticles, sync );
				Particles[ i ] = TempParticles;
			}
		}
	}
}

simulated protected function EndCasterParticleFX( const array<TParticleContent> FX, out array<ParticleSystemComponent> Particles )
{
	local int i;
	local XComGameState_Unit VisualizedUnit;
	local bool bVisualizedUnitIsDead;

	if (m_kPawn != none)
	{
		`assert(FX.Length == Particles.Length);
		VisualizedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kPawn.ObjectID));
		bVisualizedUnitIsDead = VisualizedUnit.IsDead();

		for (i = 0; i < Particles.Length; ++i)
		{
			if (Particles[ i ] != none && Particles[ i ].bIsActive)
			{
				Particles[ i ].DeactivateSystem(FX[i].ForceRemoveOnDeath && bVisualizedUnitIsDead);
			}
		}
	}
}

simulated protected function StartTargetsParticleFX( const array<TParticleContent> FX, out array< TTargetParticles > Particles, bool sync = false )
{
	local int t, i, x;
	local ParticleSystemComponent TempParticles;
	local TParticleContent Content;

	Particles.Length = m_arrTargetPawns.Length + m_arrTargetLocations.Length;
	for (t = 0; t < Particles.Length; ++t)
	{
		Particles[ t ].Particles.Length = FX.Length;
	}

	for (i = 0; i < FX.Length; ++i)
	{
		Content = FX[ i ];
		if (Content.FXTemplate != none)
		{
			if ((Content.FXTemplateBone != '') || (Content.FXTemplateSocket != ''))
			{
				for (t = 0; t < m_arrTargetPawns.Length; ++t)
				{
					if (m_arrTargetPawns[ t ] != none)
					{
						TempParticles = Particles[ t ].Particles[ i ];
						StartTargetParticleSystem( m_arrTargetPawns[ t ], Content, TempParticles, sync );
						Particles[ t ].Particles[ i ] = TempParticles;
					}
				}
			}
			else
			{
				for (t = 0; t < m_arrTargetLocations.Length; ++t)
				{
					x = m_arrTargetPawns.Length + t;

					TempParticles = Particles[ x ].Particles[ i ];

					StartParticleSystem( none, Content, TempParticles, sync );
					TempParticles.SetAbsolute( true, true, true );
					TempParticles.SetTranslation( m_arrTargetLocations[ t ] );

					Particles[ x ].Particles[ i ] = TempParticles;
				}
				m_ActiveLocationCount = m_arrTargetLocations.Length;
			}
		}
	}
}

simulated protected native function ResizeTargetsArray( out array< TTargetParticles > Particles, const array<TParticleContent> FX );
simulated protected function StartAppendTargetsParticleFX( const array<TParticleContent> FX, out array< TTargetParticles > Particles )
{
	local int t, i, x;
	local TParticleContent Content;
	local ParticleSystemComponent TempParticles;

	ResizeTargetsArray( Particles, FX );

	for (i = 0; i < FX.Length; ++i)
	{
		Content = FX[ i ];
		if (Content.FXTemplate != none)
		{
			if ((Content.FXTemplateBone != '') || (Content.FXTemplateSocket != ''))
			{
				for (t = 0; t < m_arrAppendTargetPawns.Length; ++t)
				{
					x = m_arrTargetPawns.Length - t - 1;

					TempParticles = Particles[ x ].Particles[ i ];
					StartTargetParticleSystem( m_arrTargetPawns[ x ], Content, TempParticles );
					Particles[ x ].Particles[ i ] = TempParticles;
				}
			}
			else
			{
				for (t = 0; t < m_arrAppendTargetLocations.Length; ++t)
				{
					x = m_arrTargetPawns.Length + m_arrTargetLocations.Length - t - 1;

					StartParticleSystem( none, Content, TempParticles );
					TempParticles.SetAbsolute( true, true, true );
					TempParticles.SetTranslation( m_arrTargetLocations[ m_arrTargetLocations.Length - t - 1 ] );

					Particles[ x ].Particles[ i ] = TempParticles;
				}
			}
		}
	}
}

simulated protected function EndTargetsParticleFX( out array< TTargetParticles > TargetParticles )
{
	local int t, i;

	for (t = 0; t < TargetParticles.Length; ++t)
	{
		for (i = 0; i < TargetParticles[t].Particles.Length; ++i)
		{
			if (TargetParticles[t].Particles[i] != none && TargetParticles[t].Particles[i].bIsActive)
			{
				TargetParticles[t].Particles[i].DeactivateSystem( );
			}
		}
	}
}

simulated protected function DoCasterActivationParticleFX()
{
	StartCasterParticleFX( CasterActivationFX, m_CasterActivationParticles );
}

simulated protected function StopCasterActivationParticleFX()
{
	EndCasterParticleFX( CasterActivationFX, m_CasterActivationParticles );
}

simulated protected function DoCasterParticleFXForDuration()
{
	StartCasterParticleFX( CasterDurationFX, m_CasterDurationParticles );
}

simulated protected function DoTargetActivationParticleFX( )
{
	StartTargetsParticleFX( TargetActivationFX, m_TargetActivationParticles );
}

simulated protected function DoAppendTargetActivationParticleFX( )
{
	StartAppendTargetsParticleFX( TargetActivationFX, m_TargetActivationParticles );
}

simulated protected function StopTargetActivationParticleFX( )
{
	EndTargetsParticleFX( m_TargetActivationParticles );
}

simulated protected function DoCasterParticleFXOnDamage()
{
	StartCasterParticleFX( CasterOnDamageFX, m_CasterOnDamageParticles );
}

simulated protected function DoCasterParticleFXOnMetaDamage()
{
	StartCasterParticleFX( CasterOnMetaDamageFX, m_CasterOnMetaDamageParticles );
}

simulated protected function DoTargetParticleFXForDuration()
{
	StartTargetsParticleFX( TargetDurationFX, m_TargetDurationParticles );
}

simulated protected function DoCasterDurationParticleFX( )
{
	StartCasterParticleFX( CasterDurationFX, m_CasterDurationParticles );
}

simulated protected function DoTargetDurationParticleFX( )
{
	StartTargetsParticleFX( TargetDurationFX, m_TargetDurationParticles );
}

simulated protected function DoAppendTargetDurationParticleFX( )
{
	StartAppendTargetsParticleFX( TargetDurationFX, m_TargetDurationParticles );
}

simulated protected function DoCasterDurationEndedParticleFX()
{
	StartCasterParticleFX( CasterDurationEndedFX, m_CasterDurationEndedParticles );
}

simulated protected function DoTargetDurationEndedParticleFX()
{
	StartTargetsParticleFX( TargetDurationEndedFX, m_TargetDurationEndedParticles );
}

simulated protected function DoCasterDeactivationParticleFX( )
{
	StartCasterParticleFX( CasterDeactivationFX, m_CasterDeactivationParticles );
}

simulated protected function DoTargetDeactivationParticleFX( )
{
	StartTargetsParticleFX( TargetDeactivationFX, m_TargetDeactivationParticles );
}

simulated protected function DoAppendTargetDeactivationParticleFX( )
{
	StartAppendTargetsParticleFX( TargetDeactivationFX, m_TargetDeactivationParticles );
}

simulated protected function DoTetherStartupParticleFX( )
{
	local array<ParticleSystemComponent> NewParticles;
	local int x;

	for (x = 0; x < m_arrTargetPawns.Length; ++x)
	{
		StartCasterParticleFX( TetherStartupFX, NewParticles );

		m_TetherParticles[ x ].Particles = AppendArray( m_TetherParticles[ x ].Particles, NewParticles );
		NewParticles.Length = 0;
	}
}

simulated protected function DoTetherParticleFX( bool sync = false )
{
	local array<ParticleSystemComponent> NewParticles;
	local int x;

	for (x = 0; x < m_arrTargetPawns.Length; ++x)
	{
		StartCasterParticleFX( TetherToTargetFX, NewParticles, sync );

		m_TetherParticles[ x ].Particles = AppendArray( m_TetherParticles[ x ].Particles, NewParticles );
		NewParticles.Length = 0;
	}
}

simulated protected function DoTetherParticleFXWrapper( )
{
	DoTetherParticleFX( );
}

simulated protected function DoTetherShutdownParticleFX( )
{
	local array<ParticleSystemComponent> NewParticles;
	local int x;

	for (x = 0; x < m_arrTargetPawns.Length; ++x)
	{
		StartCasterParticleFX( TetherShutdownFX, NewParticles );

		m_TetherParticles[ x ].Particles = AppendArray( m_TetherParticles[ x ].Particles, NewParticles );
		NewParticles.Length = 0;
	}
}

simulated protected function DoAppendTetherStartupParticleFX( )
{
	local array<ParticleSystemComponent> NewParticles;
	local int PreAppendPawnLength;
	local int x;

	PreAppendPawnLength = m_arrTargetPawns.Length - m_arrAppendTargetPawns.Length;

	for (x = 0; x < m_arrAppendTargetPawns.Length; ++x)
	{
		StartCasterParticleFX( TetherStartupFX, NewParticles );

		m_TetherParticles[ PreAppendPawnLength + x ].Particles = AppendArray( m_TetherParticles[ PreAppendPawnLength + x ].Particles, NewParticles );
		NewParticles.Length = 0;
	}
}

simulated protected function DoAppendTetherParticleFX( )
{
	local array<ParticleSystemComponent> NewParticles;
	local int PreAppendPawnLength;
	local int x;

	PreAppendPawnLength = m_arrTargetPawns.Length - m_arrAppendTargetPawns.Length;

	for (x = 0; x < m_arrAppendTargetPawns.Length; ++x)
	{
		StartCasterParticleFX( TetherToTargetFX, NewParticles );

		m_TetherParticles[ PreAppendPawnLength + x ].Particles = AppendArray( m_TetherParticles[ PreAppendPawnLength + x ].Particles, NewParticles );
		NewParticles.Length = 0;
	}
}

simulated protected function DoManualFireVolley( )
{
	FireWeaponNotify.bPerkVolley = true;
	FireWeaponNotify.PerkAbilityName = string(AssociatedAbility);

	FireWeaponNotify.NotifyUnit( m_kPawn );
}

simulated protected function UpdateAttachmentLocations( )
{
	local int x;
	local XComUnitPawn TargetPawn;
	local DynamicPointInSpace TetherAttachment;
	local Vector AttachLocation;

	for (x = 0; x < m_arrTargetPawns.Length; ++x)
	{
		TargetPawn = m_arrTargetPawns[x];
		TetherAttachment = m_TetherAttachmentActors[x];

		if ((TargetPawn == none) || (TetherAttachment == none))
		{
			continue;
		}

		if (TargetAttachmentSocket != '')
		{
			TargetPawn.Mesh.GetSocketWorldLocationAndRotation( TargetAttachmentSocket, AttachLocation );
		}
		else if (TargetAttachmentBone != '')
		{
			AttachLocation = TargetPawn.Mesh.GetBoneLocation( TargetAttachmentBone );
		}
		else
		{
			AttachLocation = TargetPawn.Location;
		}

		TetherAttachment.SetLocation( AttachLocation );
	}
}

simulated protected function StopExistingTetherFX( )
{
	local TTargetParticles TargetParticles;
	local ParticleSystemComponent ParticleSystem;

	foreach m_TetherParticles( TargetParticles )
	{
		foreach TargetParticles.Particles( ParticleSystem )
		{
			if (ParticleSystem != none)
			{
				ParticleSystem.DeactivateSystem( );
			}
		}
	}
}

simulated protected function UpdateTetherParticleParams( )
{
	local int x, y;
	local XComUnitPawn TargetPawn;
	local DynamicPointInSpace TetherAttachment;
	local ParticleSystemComponent ParticleSystem;
	local TTargetParticles TargetParticles;

	local Vector ParticleParameterDistance;
	local float Distance;

	for (x = 0; x < m_arrTargetPawns.Length; ++x)
	{
		TargetPawn = m_arrTargetPawns[ x ];
		TetherAttachment = m_TetherAttachmentActors[ x ];

		if ((TargetPawn == none) || (TetherAttachment == none))
		{
			continue;
		}

		TargetParticles = m_TetherParticles[ x ];

		for (y = 0; y < TargetParticles.Particles.Length; ++y)
		{
			ParticleSystem = TargetParticles.Particles[ y ];

			ParticleParameterDistance = TetherAttachment.Location - ParticleSystem.GetPosition( );
			Distance = VSize( ParticleParameterDistance );

			ParticleSystem.SetAbsolute( false, true, false );
			ParticleSystem.SetRotation( rotator( Normal( ParticleParameterDistance ) ) );

			ParticleParameterDistance.X = Distance;
			ParticleParameterDistance.Y = Distance;
			ParticleParameterDistance.Z = Distance;

			ParticleSystem.SetVectorParameter( 'Distance', ParticleParameterDistance );
			ParticleSystem.SetFloatParameter( 'Distance', Distance );
		}
	}
}

simulated event Tick( float fDeltaT )
{
	if ((TetherToTargetFX.Length != 0) && !IsInState( 'Idle' ))
	{
		UpdateAttachmentLocations( );

		UpdateTetherParticleParams( );
	}
}

simulated function TriggerImpact( )
{
}

simulated function AddAnimSetsToPawn(XComUnitPawn kPawn)
{
	local AnimSet kAnimSet;

	m_kPawn = kPawn;
	if (m_kPawn != none && !m_kPawn.IsA('XComTank'))        //  slight hack. don't give animsts to SHIVs (which would happen with Advanced Servomotors)
	{
		foreach AnimSetsToAlwaysApply(kAnimSet)
		{
			if (m_kPawn.Mesh.AnimSets.Find(kAnimSet) == -1)
			{
				m_kPawn.Mesh.AnimSets.AddItem(kAnimSet);
			}
		}
	}
}

delegate DoEffectDelegate( );
simulated protected native function SetDelegateTimer( float delay, delegate<DoEffectDelegate> EffectFunction );

simulated protected function TimerDoEffects( const array<TParticleContent> FX, delegate<DoEffectDelegate> EffectFunction )
{
	if (FX.Length > 0)
	{
		if (FX[0].Delay > 0)
		{
			SetDelegateTimer( FX[0].Delay, EffectFunction );
		}
		else
		{
			EffectFunction( );
		}
	}
}

auto simulated state Idle
{
	simulated function PerkStart( XGUnit kUnit, array<XGUnit> arrTargets, array<vector> arrLocations, bool ShooterEffect )
	{
		local XGUnit TargetUnit;

		m_kUnit = kUnit;
		m_kPawn = kUnit.GetPawn( );

		m_arrTargets = arrTargets;
		m_arrTargetLocations = arrLocations;
		m_ShooterEffect = ShooterEffect;

		m_arrTargetPawns.Length = 0;
		foreach arrTargets( TargetUnit )
		{
			if (TargetUnit != none)
			{
				m_arrTargetPawns.AddItem( TargetUnit.GetPawn( ) );
			}
		}
		m_ActiveTargetCount = m_arrTargets.Length;
		m_ActiveLocationCount = 0;
	}

	simulated function OnPerkActivation( XGUnit kUnit, array<XGUnit> arrTargets, array<vector> arrLocations, bool ShooterEffect )
	{
		PerkStart( kUnit, arrTargets, arrLocations, ShooterEffect );

		GotoState( 'ActionActive' );
	}

	simulated function OnPerkLoad( XGUnit kUnit, array<XGUnit> arrTargets, array<vector> arrLocations, bool ShooterEffect )
	{
		`assert(AssociatedEffect != '');

		PerkStart( kUnit, arrTargets, arrLocations, ShooterEffect );

		GotoState( 'DurationActive' );
	}

Begin:
}

simulated state ActionActive
{
	simulated function StartTargetIndependentEffects( )
	{
		m_RecievedImpactEvent = false;

		// clean up these arrays from the previous activation
		StopTargetLocationSoundCue( m_LocationDurationEndSounds );
		StopTargetLocationSoundCue( m_LocationDeactivationSounds );

		if (DisablePersistentFXDuringActivation)
		{
			StopPersistentFX( );
		}

		if (ManualFireNotify)
		{
			if (FireVolleyDelay > 0)
			{
				SetTimer( FireVolleyDelay, false, nameof( DoManualFireVolley ) );
			}
			else
			{
				DoManualFireVolley( );
			}
		}

		TimerDoEffects( CasterActivationFX, DoCasterActivationParticleFX );
		PlaySoundCue( m_kPawn, CasterActivationSound );

		if (CasterActivationMITV != none)
		{
			CasterActivationMITV.ApplyMITV( m_kPawn );
		}

		if (AssociatedEffect != '')
		{
			TimerDoEffects( CasterDurationFX, DoCasterDurationParticleFX );
			PlaySoundCue( m_kPawn, CasterDurationSound );
		}

		PrepTargetMITVs( true );
	}

	simulated function StartTargetImpactEffects( )
	{
		local XComUnitPawn TargetPawn;
		local int x;

		TimerDoEffects( TargetActivationFX, DoTargetActivationParticleFX );
		PlayTargetsSoundCues( TargetActivationSound, m_arrTargetPawns );
		PlayTargetLocationSoundCue( TargetLocationsActivationSound, m_arrTargetLocations, m_LocationActivationSounds );

		if (TargetActivationMITV != none)
		{
			for (x = 0; x < m_arrTargetPawns.Length; ++x)
			{
				TargetPawn = m_arrTargetPawns[ x ];
				m_TargetActivationMITVs[ x ].ApplyMITV( TargetPawn );
			}
		}

		if (AssociatedEffect != '')
		{
			TimerDoEffects( TargetDurationFX, DoTargetDurationParticleFX );
			PlayTargetsSoundCues( TargetDurationSound, m_arrTargetPawns );
			PlayTargetLocationSoundCue( TargetLocationsDurationSound, m_arrTargetLocations, m_LocationDurationSounds );
		}

		TimerDoEffects( TetherToTargetFX, DoTetherParticleFXWrapper );
	}

	simulated function StartTethers( )
	{
		local int x;

		m_TetherParticles.Length = m_arrTargetPawns.Length;
		m_TetherAttachmentActors.Length = m_arrTargetPawns.Length;

		for (x = 0; x < m_arrTargetPawns.Length; ++x)
		{
			m_TetherAttachmentActors[ x ] = Spawn( class'DynamicPointInSpace', self );
			m_TetherParticles[ x ].Particles.Length = 0;
		}
		UpdateAttachmentLocations( );

		TimerDoEffects( TetherStartupFX, DoTetherStartupParticleFX );
	}

	simulated function EndTargetIndepentEffects( )
	{
		local XComGameState_Unit VisualizedUnit;

		if (DisablePersistentFXDuringActivation)
		{
			StartPersistentFX( m_kPawn );
		}

		if (CasterActivationMITV != none && ResetCasterActivationMTIVOnDeactivate)
		{
			if (CasterActivationMITV.bApplyFullUnitMaterial)
			{
				m_kPawn.CleanUpMITV( );
			}
			else
			{
				CasterActivationMITV.ResetPawnName = m_kPawn.Name;
				CasterActivationMITV.ResetMaterial( );
			}
		}

		StopCasterActivationParticleFX( );
		StopSoundCue( m_kPawn, CasterActivationSound );
		TimerDoEffects( CasterDeactivationFX, DoCasterDeactivationParticleFX );
		PlaySoundCue( m_kPawn, CasterDeactivationSound );


		VisualizedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID( m_kUnit.ObjectID ));

		if (TargetEffectsOnProjectileImpact && !m_RecievedImpactEvent && VisualizedUnit.IsAlive())
		{
			`redscreen( "Perk Content for "@AssociatedAbility@"."@AssociatedEffect@" did not receive expected projectile impact. Tell StephenJameson" );
		}
	}

	simulated event BeginState( Name PreviousStateName )
	{
		StartTargetIndependentEffects( );

		if (TetherToTargetFX.Length != 0)
		{
			StartTethers( );
		}

		if (!TargetEffectsOnProjectileImpact)
		{
			StartTargetImpactEffects( );
		}
	}

	simulated event EndState( name nmNext )
	{
		EndTargetIndepentEffects( );

		StopTargetActivationParticleFX( );
		StopTargetsSoundCues( TargetActivationSound, m_arrTargetPawns );
		StopTargetLocationSoundCue( m_LocationActivationSounds );

		TimerDoEffects( TargetDeactivationFX, DoTargetDeactivationParticleFX );
		PlayTargetsSoundCues( TargetDeactivationSound, m_arrTargetPawns );
		PlayTargetLocationSoundCue( TargetLocationsDeactivationSound, m_arrTargetLocations, m_LocationDeactivationSounds );
	}

	simulated function TriggerImpact( )
	{
		if (TargetEffectsOnProjectileImpact && !m_RecievedImpactEvent)
		{
			StartTargetImpactEffects( );
		}
		m_RecievedImpactEvent = true;
	}

	simulated function OnPerkDeactivation( )
	{
		if (TargetEffectsOnProjectileImpact && !m_RecievedImpactEvent)
		{
			StartTargetImpactEffects( ); // Make sure we play the effects anyway and that the location count get set appropriately.
		}

		// if there's no effect or no targets
		if ((AssociatedEffect == '') || ((m_arrTargetPawns.Length == 0) && (m_ActiveLocationCount == 0) && (TetherToTargetFX.Length == 0) && !m_ShooterEffect))
		{
			GotoState( 'Idle' );
		}
		else
		{
			GotoState( 'DurationActive' );
		}
	}

Begin:
}

simulated state DurationAction extends ActionActive
{
	simulated function StartTargetImpactEffects( )
	{
		local XComUnitPawn TargetPawn;
		local int x;

		TimerDoEffects( TargetActivationFX, DoAppendTargetActivationParticleFX );
		PlayTargetsSoundCues( TargetActivationSound, m_arrAppendTargetPawns );
		PlayTargetLocationSoundCue( TargetLocationsActivationSound, m_arrAppendTargetLocations, m_LocationActivationSounds );

		if (TargetActivationMITV != none)
		{
			for (x = 0; x < m_arrAppendTargetPawns.Length; ++x)
			{
				TargetPawn = m_arrTargetPawns[ m_arrTargetPawns.Length - x - 1 ];
				m_TargetActivationMITVs[ m_arrTargetPawns.Length - x - 1 ].ApplyMITV( TargetPawn );
			}
		}

		if (AssociatedEffect != '')
		{
			TimerDoEffects( TargetDurationFX, DoAppendTargetDurationParticleFX );
			PlayTargetsSoundCues( TargetDurationSound, m_arrAppendTargetPawns );
			PlayTargetLocationSoundCue( TargetLocationsDurationSound, m_arrAppendTargetLocations, m_LocationDurationSounds );
		}

		TimerDoEffects( TetherToTargetFX, DoAppendTetherParticleFX );
	}

	simulated function StartTethers( )
	{
		local int x;

		m_TetherParticles.Length = m_TetherParticles.Length + m_arrAppendTargetPawns.Length;
		m_TetherAttachmentActors.Length = m_TetherAttachmentActors.Length + m_arrAppendTargetPawns.Length;

		for (x = 0; x < m_arrAppendTargetPawns.Length; ++x)
		{
			m_TetherAttachmentActors[ m_arrTargetPawns.Length - x - 1 ] = Spawn( class'DynamicPointInSpace', self );
			m_TetherParticles[ m_arrTargetPawns.Length - x - 1 ].Particles.Length = 0;
		}
		UpdateAttachmentLocations( );

		TimerDoEffects( TetherStartupFX, DoAppendTetherStartupParticleFX );
	}

	simulated event EndState( name nmNext )
	{
		EndTargetIndepentEffects( );

		StopTargetActivationParticleFX( );
		StopTargetsSoundCues( TargetActivationSound, m_arrAppendTargetPawns );
		StopTargetLocationSoundCue( m_LocationActivationSounds );

		TimerDoEffects( TargetDeactivationFX, DoAppendTargetDeactivationParticleFX );
		PlayTargetsSoundCues( TargetDeactivationSound, m_arrAppendTargetPawns );
		PlayTargetLocationSoundCue( TargetLocationsDeactivationSound, m_arrAppendTargetLocations, m_LocationDeactivationSounds );

		m_arrAppendTargets.Length = 0;
		m_arrAppendTargetPawns.Length = 0;
		m_arrAppendTargetLocations.Length = 0;
	}

Begin:
}

simulated state DurationActive
{
	simulated event BeginState( Name PreviousStateName )
	{
		local XComUnitPawn TargetPawn;
		local int x;

		if (PreviousStateName == 'DurationAction')
		{
			return;
		}

		if (PreviousStateName == 'Idle') // coming from save/load process
		{
			// initially size the target arrays.  we don't use them, but by the time we're active these should be the
			// same size regardless of how the perk started up (from activation or load).
			m_TargetActivationParticles.Length = m_arrTargetPawns.Length + m_arrTargetLocations.Length;
			m_TargetDeactivationParticles.Length = m_arrTargetPawns.Length + m_arrTargetLocations.Length;

			StartCasterParticleFX( CasterDurationFX, m_CasterDurationParticles, true );
			PlaySoundCue( m_kPawn, CasterDurationSound );

			StartTargetsParticleFX( TargetDurationFX, m_TargetDurationParticles, true );
			PlayTargetsSoundCues( TargetDurationSound, m_arrTargetPawns );
			PlayTargetLocationSoundCue( TargetLocationsDurationSound, m_arrTargetLocations, m_LocationDurationSounds );

			m_TetherParticles.Length = m_arrTargetPawns.Length;
			m_TetherAttachmentActors.Length = m_arrTargetPawns.Length;

			for (x = 0; x < m_arrTargetPawns.Length; ++x)
			{
				m_TetherAttachmentActors[ x ] = Spawn( class'DynamicPointInSpace', self );
				m_TetherParticles[ x ].Particles.Length = 0;
			}
			UpdateAttachmentLocations( );
			DoTetherParticleFX( true );
		}

		m_kPawn.arrTargetingPerkContent.AddItem( self );
		if (CasterDurationEndedMITV != none)
		{
			CasterDurationEndedMITV.ApplyMITV( m_kPawn );
		}

		PrepTargetMITVs( false );
		for (x = 0; x < m_arrTargetPawns.Length; ++x)
		{
			TargetPawn = m_arrTargetPawns[x];

			TargetPawn.arrTargetingPerkContent.AddItem( self );
			
			if (TargetDurationEndedMITV != none)
			{
				m_TargetDurationEndedMITVs[x].ApplyMITV( TargetPawn );
			}
		}
	}

	simulated event EndState( name nmNext )
	{
		local XComUnitPawn TargetPawn;
		local int x;

		if (nmNext == 'DurationAction')
		{
			return;
		}

		m_kPawn.arrTargetingPerkContent.RemoveItem( self );

		foreach m_arrTargetPawns( TargetPawn )
		{
			TargetPawn.arrTargetingPerkContent.RemoveItem( self );
		}
		m_ActiveTargetCount = 0;

		EndCasterParticleFX( CasterDurationFX, m_CasterDurationParticles );
		EndTargetsParticleFX( m_TargetDurationParticles );

		StopSoundCue( m_kPawn, CasterDurationSound );
		StopTargetsSoundCues( TargetDurationSound, m_arrTargetPawns );
		StopTargetLocationSoundCue( m_LocationDurationSounds );

		TimerDoEffects( CasterDurationEndedFX, DoCasterDurationEndedParticleFX );
		TimerDoEffects( TargetDurationEndedFX, DoTargetDurationEndedParticleFX );

		PlaySoundCue( m_kPawn, CasterDurationEndSound );
		PlayTargetsSoundCues( TargetDurationEndSound, m_arrTargetPawns );
		PlayTargetLocationSoundCue( TargetLocationsDurationEndSound, m_arrTargetLocations, m_LocationDurationSounds );

		if (TetherToTargetFX.Length != 0)
		{
			StopExistingTetherFX( );
			DoTetherShutdownParticleFX( );
			UpdateTetherParticleParams( );

			for (x = 0; x < m_arrTargetPawns.Length; ++x)
			{
				m_TetherAttachmentActors[x].Destroy( );
			}
		}
	}

	simulated function OnPerkDurationEnd( )
	{
		GotoState( 'Idle' );
	}

	simulated function OnPerkActivation( XGUnit kUnit, array<XGUnit> arrTargets, array<vector> arrLocations, bool ShooterEffect )
	{
		local XGUnit TargetUnit;
		local vector Loc;

		`assert( ShooterEffect == m_ShooterEffect );

		foreach arrLocations(Loc)
		{
			m_arrTargetLocations.AddItem( Loc );
			m_arrAppendTargetLocations.AddItem( Loc );
		}

		foreach arrTargets( TargetUnit )
		{
			if (TargetUnit != none)
			{
				m_arrTargets.AddItem( TargetUnit );
				m_arrTargetPawns.AddItem( TargetUnit.GetPawn( ) );

				m_arrAppendTargets.AddItem( TargetUnit );
				m_arrAppendTargetPawns.AddItem( TargetUnit.GetPawn( ) );
			}
		}

		m_ActiveTargetCount += arrTargets.Length;

		GotoState( 'DurationAction' );
	}

Begin:
}

static function name ChooseAnimationForCover(XGUnit kUnit, TAnimContent AnimContent)
{
	return class'XComIdleAnimationStateMachine'.static.ChooseAnimationForCover( kUnit, AnimContent.NoCoverAnim, AnimContent.LowCoverAnim, AnimContent.HighCoverAnim );
}

simulated function PerkFinished(ParticleSystemComponent PSystem)
{
	//`log("****" @ GetFuncName() @ "****" @ self @ PSystem);
	PSystem.DeactivateSystem();
}

static function GetAssociatedPerks( out array<XComPerkContent> ValidPerks, XComUnitPawnNativeBase Caster, const name ActivatingAbilityName )
{
	local XComGameState_Unit UnitState;
	local XComPerkContent Perk;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID( Caster.ObjectID ));

	foreach Caster.arrPawnPerkContent( Perk )
	{
		// does the perk match the ability
		if (Perk.AssociatedAbility != ActivatingAbilityName)
		{
			continue;
		}

		if (Perk.AssociatedPassive != '') // if it's associated to a passive element of the ability, does the unit have that ability
		{
			if (!UnitState.HasSoldierAbility( Perk.AssociatedPassive ))
			{
				continue;
			}
		}

		if (Perk.ExclusivePerk)
		{
			ValidPerks.Length = 0;
			ValidPerks.AddItem( Perk );
			return;
		}

		ValidPerks.AddItem( Perk );
	}
}