//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_StartStopSound extends X2Action;

var SoundCue Sound;
var float	FadeInTime;
var float	VolumeMultiplier;
var float	PitchMultiplier;
var bool	bSuppressSubtitles;

var bool WaitForCompletion;
var private float TimeRemaining;

var bool bIsPositional;
var vector vWorldPosition;
var int iAssociatedGameStateObjectId;
var bool bStartPersistentSound;
var bool bStopPersistentSound;



event bool BlocksAbilityActivation()
{
	return false;
}

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	function SpawnOneOffSound()
	{
		local XComSoundEmitter Emitter;

		if (Sound.AkEventOverride != None)
		{
			Emitter = Spawn(class'XComSoundEmitter');
			Emitter.SetLocation(vWorldPosition);
			Emitter.PostAkEvent(Sound.AkEventOverride);
		}
	}


	function SpawnPersistentSoundForObjectId(int iObjectId)
	{
		local XComSoundEmitter Emitter;

		if (Sound.AkEventOverride != None && iAssociatedGameStateObjectId != 0)
		{
			Emitter = Spawn(class'XComSoundEmitter');
			Emitter.iAssociatedGameStateObjectId = iObjectId;
			Emitter.bIsPersistentSound = true;
			Emitter.SetLocation(vWorldPosition);
			Emitter.PostAkEvent(Sound.AkEventOverride);
		}
	}


	function DestroyPersistentSoundForObjectId(int iObjectId)
	{
		local XComSoundEmitter Emitter;

		foreach AllActors(class 'XComSoundEmitter', Emitter)
		{
			if (Emitter.iAssociatedGameStateObjectId == iObjectId)
			{
				if (Sound.AkEventOverride != None)
					Emitter.PostAkEvent(Sound.AkEventOverride);

				Emitter.Destroy();
				break;
			}
		}
	}


	function bool DoesSoundEmitterAlreadyExistForObjectId(int iObjectId)
	{
		local XComSoundEmitter Emitter;

		foreach AllActors(class 'XComSoundEmitter', Emitter)
		{
			if (Emitter.iAssociatedGameStateObjectId == iObjectId)
			{
				return true;
			}
		}

		return false;
	}


	function bool PersistentSoundInputsAreValid()
	{
		if (!bStartPersistentSound && !bStopPersistentSound)
			return false;

		if (iAssociatedGameStateObjectId == 0)
		{
			`RedScreen("X2Action_StartStopSound cannot start or stop a persistent sound without an ObjectId.  See mdomowicz.");
			return false;
		}

		if (bStartPersistentSound && DoesSoundEmitterAlreadyExistForObjectId(iAssociatedGameStateObjectId))
		{
			`RedScreen("X2Action_StartStopSound: for now we only support one sound emitter per iObjectId.  see mdomowicz.");
			return false;
		}

		return true;
	}


	simulated private function BeginSound()
	{
		local PlayerController Controller;

		if (bIsPositional)
		{
			if (PersistentSoundInputsAreValid())
			{
				if (bStartPersistentSound)
				{
					SpawnPersistentSoundForObjectId(iAssociatedGameStateObjectId);
				}
				else if (bStopPersistentSound)
				{
					DestroyPersistentSoundForObjectId(iAssociatedGameStateObjectId);
				}
			}
			else
			{
				SpawnOneOffSound();
			}
		}
		else
		{
			// play the sound cue on each player
			foreach class'WorldInfo'.static.GetWorldInfo().AllControllers(class'PlayerController', Controller)
			{
				Controller.Kismet_ClientPlaySound(Sound, Controller, VolumeMultiplier, PitchMultiplier, FadeInTime, bSuppressSubtitles, true);
			}
		}
	}

	simulated event Tick(float DeltaTime)
	{
		TimeRemaining -= DeltaTime;
	}

Begin:
	BeginSound();

	if(WaitforCompletion)
	{
		TimeRemaining = Sound.Duration;
		while(TimeRemaining > 0)
		{
			Sleep(0.0);
		}
	}

	CompleteAction();
}

defaultproperties
{
}

