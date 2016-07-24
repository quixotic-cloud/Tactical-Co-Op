// XCom Sound manager
// 
// Manages common sound and music related tasks for XCOM

class XComSoundManager extends Actor config(GameData);

struct native AkEventMapping
{
	var string strKey;
	var AkEvent TriggeredEvent;
};

// Sound Mappings
var config array<string> SoundEventPaths;
var config array<AkEventMapping> SoundEvents;

struct AmbientChannel
{
	var SoundCue Cue;
	var AudioComponent Component;
	var bool bHasPlayRequestPending;
};

//------------------------------------------------------------------------------
// AmbientChannel Management
//------------------------------------------------------------------------------
protected function SetAmbientCue(out AmbientChannel Ambience, SoundCue NewCue)
{
	if (NewCue != Ambience.Cue)
	{
		if (Ambience.Component != none && Ambience.Component.IsPlaying())
		{
			Ambience.Component.FadeOut(0.5f, 0.0f);
			Ambience.Component = none;
		}

		Ambience.Cue = NewCue;
		Ambience.Component = CreateAudioComponent(NewCue, false, true);

		if (Ambience.bHasPlayRequestPending)
			StartAmbience(Ambience);
	}
}

protected function StartAmbience(out AmbientChannel Ambience, optional float FadeInTime=0.5f)
{
	if (Ambience.Cue == none)
	{
		Ambience.bHasPlayRequestPending = true;
		return;
	}

	if (Ambience.Cue != none && Ambience.Component != none && ( !Ambience.Component.IsPlaying() || Ambience.Component.IsFadingOut() ) )
	{
		Ambience.Component.bIsMusic = (Ambience.Cue.SoundClass == 'Music'); // Make sure the music flag is correct
		Ambience.Component.FadeIn(FadeInTime, 1.0f);
	}
}

protected function StopAmbience(out AmbientChannel Ambience, optional float FadeOutTime=1.0f)
{
	Ambience.bHasPlayRequestPending = false;

	if (Ambience.Component != none && Ambience.Component.IsPlaying())
	{
		Ambience.Component.FadeOut(FadeOutTime, 0.0f);
	}
}

//------------------------------------------------------------------------------
// Music management
//------------------------------------------------------------------------------
function PlayMusic( SoundCue NewMusicCue, optional float FadeInTime=0.0f )
{
	local MusicTrackStruct MusicTrack;

	MusicTrack.TheSoundCue = NewMusicCue;
	MusicTrack.FadeInTime = FadeInTime;
	MusicTrack.FadeOutTime = 1.0f;
	MusicTrack.FadeInVolumeLevel = 1.0f;
	MusicTrack.bAutoPlay = true;

	`log("XComSoundManager.PlayMusic: Starting" @ NewMusicCue,,'DevSound');

	WorldInfo.UpdateMusicTrack(MusicTrack);
}

function StopMusic(optional float FadeOutTime=1.0f)
{
	local MusicTrackStruct MusicTrack;

	`log("XComSoundManager.StopMusic: Stopping" @ WorldInfo.CurrentMusicTrack.TheSoundCue,,'DevSound');

	MusicTrack.TheSoundCue = none;

	WorldInfo.CurrentMusicTrack.FadeOutTime = FadeOutTime;
	WorldInfo.UpdateMusicTrack(MusicTrack);
}

//---------------------------------------------------------------------------------------
function PlaySoundEvent(string strKey)
{
	local int Index;

	Index = SoundEvents.Find('strKey', strKey);

	if(Index != INDEX_NONE)
	{
		WorldInfo.PlayAkEvent(SoundEvents[Index].TriggeredEvent);
	}
}

//---------------------------------------------------------------------------------------
function Init()
{
	local int idx;
	local XComContentManager ContentMgr;

	ContentMgr = `CONTENT;

	// Load Events
	for( idx = 0; idx < SoundEventPaths.Length; idx++ )
	{
		ContentMgr.RequestObjectAsync(SoundEventPaths[idx], self, OnAkEventMappingLoaded);
	}
}

//---------------------------------------------------------------------------------------
function OnAkEventMappingLoaded(object LoadedArchetype)
{
	local AkEvent TempEvent;
	local AkEventMapping EventMapping;

	TempEvent = AkEvent(LoadedArchetype);
	if( TempEvent != none )
	{
		EventMapping.strKey = string(TempEvent.name);
		EventMapping.TriggeredEvent = TempEvent;

		SoundEvents.AddItem(EventMapping);
	}
}

//---------------------------------------------------------------------------------------
