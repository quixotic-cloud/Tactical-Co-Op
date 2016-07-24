//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_PlayEffect extends X2Action;

// The path name of the particle system effect to be played.
var string EffectName;

// The location at which the effect will be played.
var Vector EffectLocation;
var Rotator EffectRotation;
var bool AttachToUnit;
var name AttachToSocketName;
var name AttachToSocketsArrayName;

// If true, this action will stop the already playing effect with the specified name & location.  
// If false, this action will play the specified effect name at the specified location.
var bool bStopEffect;

// If true, this action will not complete until the associated effect is destroyed.
var bool bWaitForCompletion;

// If true, this action will not complete until the associated camera is cleared.
var bool bWaitForCameraCompletion;

// If true, this action will not complete before the associated camera has arrived.
var bool bWaitForCameraArrival;

// If true, the camera will be centered on the EffectLocation when playing the effect.
var float CenterCameraOnEffectDuration;

// If >0.0, the FOW will be revealed around the effect for this radius for CenterCameraOnEffectDuration seconds.
var float RevealFOWRadius;
var int FOWViewerObjectID; //Set with an object ID that should be used to determine whether this FOW viewer can see units or not

// The instance of the Particle system component playing this effect.
var ParticleSystemComponent PSComponent;

// The current look at camera
var X2Camera_LookAtLocationTimed LookAtCam;

// The current FOW Viewer actor
var Actor FOWViewer;

// The game time at which the effect is spawned
var float EffectSpawnTime;

var XComNarrativeMoment NarrativeToPlay;

event bool BlocksAbilityActivation()
{
	return false;
}

event HandleNewUnitSelection()
{
	if( LookAtCam != None )
	{
		`CAMERASTACK.RemoveCamera(LookAtCam);
		LookAtCam = None;
	}
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated private function PlayEffect()
	{
		PSComponent = class'WorldInfo'.static.GetWorldInfo().MyEmitterPool.SpawnEmitter(ParticleSystem(DynamicLoadObject(EffectName, class'ParticleSystem')), EffectLocation, EffectRotation);

		if (AttachToUnit)
		{
			PSComponent.SetAbsolute(false, false, false);
			PSComponent.SetTickGroup( TG_EffectsUpdateWork );

			if (UnitPawn.PerkEffectScale != 1.0)
			{
				PSComponent.SetScale( UnitPawn.PerkEffectScale );
			}

			if (AttachToSocketName != '')
			{
				if (UnitPawn.Mesh.GetSocketByName( AttachToSocketName ) != none)
				{
					if (AttachToSocketsArrayName != '')
					{
						PSComponent.SetActorParameter(AttachToSocketsArrayName, UnitPawn);
					}

					UnitPawn.Mesh.AttachComponentToSocket( PSComponent, AttachToSocketName );
				}
				else
				{
					`log("WARNING: X2Action_PlayEffect could not find socket '" $ AttachToSocketName $ "' to attach particle component on" @ UnitPawn);
				}
			}
			else
			{
				UnitPawn.AttachComponent( PSComponent );
			}
		}
	}

	simulated private function StopEffect()
	{
		local EmitterPool WorldEmitterPool;
		local ParticleSystemComponent TestPSComponent;

		if (!AttachToUnit)
		{
			// find the existing already playing effect - if none is found, this X2Action will be a noop
			WorldEmitterPool = class'WorldInfo'.static.GetWorldInfo().MyEmitterPool;

			foreach WorldEmitterPool.ActiveComponents(TestPSComponent)
			{
				if( PathName(TestPSComponent.Template) ~= EffectName && TestPSComponent.Translation == EffectLocation )
				{
					PSComponent = TestPSComponent;
					break;
				}
			}
		}
		else
		{
			if( PSComponent != None )
			{
				PSComponent.SetAbsolute(class'EmitterPool'.default.PSCTemplate.AbsoluteTranslation,
										class'EmitterPool'.default.PSCTemplate.AbsoluteRotation,
										class'EmitterPool'.default.PSCTemplate.AbsoluteScale);
			}

			if (AttachToSocketName != '')
			{
				foreach UnitPawn.Mesh.AttachedComponents( class'ParticleSystemComponent', TestPSComponent )
				{
					if (PathName( TestPSComponent.Template ) == EffectName)
					{
						PSComponent = TestPSComponent;
						UnitPawn.Mesh.DetachComponent( PSComponent );
						break;
					}
				}
			}
			else
			{
				foreach UnitPawn.ComponentList( class'ParticleSystemComponent', TestPSComponent )
				{
					if (PathName( TestPSComponent.Template ) == EffectName)
					{
						PSComponent = TestPSComponent;
						UnitPawn.DetachComponent( PSComponent );
						break;
					}
				}
			}
		}

		if (PSComponent != none)
		{
			PSComponent.DeactivateSystem( );
		}
	}

	simulated private function bool IsEffectPlaying()
	{
		return PSComponent != None && !PSComponent.HasCompleted();
	}

	private function RequestLookAtCamera()
	{
		LookAtCam = new class'X2Camera_LookAtLocationTimed';
		LookAtCam.LookAtLocation = EffectLocation;
		LookAtCam.LookAtDuration = CenterCameraOnEffectDuration;
		`CAMERASTACK.AddCamera(LookAtCam);

		if( RevealFOWRadius > 0.0 )
		{
			FOWViewer = `XWORLD.CreateFOWViewer(EffectLocation, RevealFOWRadius, FOWViewerObjectID);
		}
	}

	private function ClearLookAtCamera()
	{
		if( LookAtCam != None )
		{
			`CAMERASTACK.RemoveCamera(LookAtCam);
			LookAtCam = None;
		}

		if( FOWViewer != None )
		{
			`XWORLD.DestroyFOWViewer(FOWViewer);
			FOWViewer = None;
		}
	}

Begin:
	// center the LookAt cam & FOW viewer on the effect location
	if( CenterCameraOnEffectDuration > 0.0 )
	{
		if( !bNewUnitSelected )
		{
			RequestLookAtCamera();

			while( (bWaitForCameraCompletion || bWaitForCameraArrival) && LookAtCam != None && !LookAtCam.HasArrived && LookAtCam.IsLookAtValid() )
			{
				Sleep(0.0);
			}
		}

		if (NarrativeToPlay != none)
		{
			`PRESBASE.UINarrative(NarrativeToPlay);
		}

		EffectSpawnTime = WorldInfo.TimeSeconds;
	}

	if( EffectName != "" )
	{
		// play or stop this effect
		if( !bStopEffect )
		{
			PlayEffect();
		}
		else
		{
			StopEffect();
		}

		// wait for effect to complete
		if( bWaitForCompletion )
		{
			while( IsEffectPlaying() )
			{
				Sleep(0.0);
			}
		}
	}

	if( !bWaitForCameraCompletion )
	{
		CompleteActionWithoutExitingExecution();
	}

	// Clear the LookAt cam & FOW viewer after CenterCameraOnEffectDuration time has elapsed
	if( CenterCameraOnEffectDuration > 0.0 && !bNewUnitSelected )
	{
		while( WorldInfo.TimeSeconds < EffectSpawnTime + CenterCameraOnEffectDuration )
		{
			Sleep(0.0);
		}

		ClearLookAtCamera();
	}

	// explicitly clear the reference
	PSComponent = None;

	// exit the action
	if( bWaitForCameraCompletion )
	{
		CompleteAction();
	}
	else
	{
		GotoState('Finished');
	}
}


defaultproperties
{
	RevealFOWRadius = 768.0; //8 tiles
	bWaitForCameraCompletion = true
}

