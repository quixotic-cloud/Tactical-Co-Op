class XComTacticalSoundInfo_Names extends Object
    dependson(XComTacticalSoundInfo, XComTacticalGRI)
	hidecategories(Object);

struct RegionAmbiences
{
	var() EContinent Continent;
	var() string AmbienceToUse;
};

struct RainAmbience
{	
	var() string AmbienceToUse;
};

// used only for normal maps (non-ufo, non-terror)
var(Normal) array<string> BackgroundAmbiences<tooltip="List of possible background ambiences to use">;

var(Terror) array<string> TerrorAmbiences<tooltip="List of possible terror background ambiences to use">;
var(EXALT)  array<string> ExaltAmbiences<tooltip="List of possible EXALT mission background ambiences">;

var(Rain) array<RainAmbience> RainAmbiences<Tooltip="List of ambiences to use for rain conditions">;

function string GetAmbienceByContinent(const out array<RegionAmbiences> Ambiences, EContinent Continent)
{
	local int Idx;
	for (Idx = 0; Idx < Ambiences.Length; ++Idx)
	{
		if (Ambiences[Idx].Continent == Continent)
		{
			return Ambiences[Idx].AmbienceToUse;
		}
	}

	return "";
}

function string GetBackgroundAmbience()
{
    return (BackgroundAmbiences.Length > 0) ? BackgroundAmbiences[Rand(BackgroundAmbiences.Length)] : "";
}

function string GetTerrorMissionAmbience()
{
    return (TerrorAmbiences.Length > 0) ? TerrorAmbiences[Rand(TerrorAmbiences.Length)] : "";
}

function string GetExaltMissionAmbience()
{
	return (ExaltAmbiences.Length > 0) ? ExaltAmbiences[Rand(ExaltAmbiences.Length)] : "";
}

// NOTE: This is not network-aware, seperate clients may pick different SoundCue's for the same map
function LoadSoundsFor(XComTacticalSoundInfo SoundInfoTemplate, object ObjectRequestingLoad, delegate<XComContentManager.OnObjectLoaded> BackgroundCallback, delegate<XComContentManager.OnObjectLoaded> OverlayCallback)
{
    local XComTacticalSoundInfo AmbienceInfo;
    local XComTacticalGRI GRI;
    local XGBattle_SP kBattle;
//    local ETOD TimeOfDay;
//	local EContinent Continent;
	local EMissionType Mission;
	local SoundCue OverlayAmbience;
	local string CueToLoad;
    
    local bool bIsUFOMission;
    local bool bIsTerrorMission;

    bIsUfoMission = false;
    bIsTerrorMission = false;

	GRI = XComTacticalGRI( class'WorldInfo'.static.GetWorldInfo().GRI );
	if (GRI != none)
	{
		kBattle = XGBattle_SP(GRI.m_kBattle);
		if (kBattle != none && kBattle.m_kDesc != none)
		{
			Mission = EMissionType(kBattle.m_kDesc.m_iMissionType);
			if (Mission == eMission_TerrorSite)
			{
				bIsTerrorMission = true;
			}
			else if (Mission == eMission_LandedUFO || Mission == eMission_Crash)
			{
				bIsUFOMission = true;
			}
		}
	}

    // Make a new AmbienceInfo and copy the values in from SoundInfoTemplate
    // We do this becuase SoundCues from SoundInfoTemplate may already be filled in
    // and should override anything we compute in this function
	AmbienceInfo = new(self) class'XComTacticalSoundInfo'(SoundInfoTemplate);

	// If there is an ambient overlay in kismet, that takes precedence -- jboswell
	OverlayAmbience = FindKismetOverlayAmbience();
	if (OverlayAmbience != none)
	{
		AmbienceInfo.OverlayAmbience = OverlayAmbience;
	}

    // Load up the Background Ambience. This is present on every map unless disabled
    if (AmbienceInfo.PlayBackgroundAmbience)
    {
		if (AmbienceInfo.BackgroundAmbience == none)
		{
			if (bIsUfoMission) 
				CueToLoad = GetBackgroundAmbience(); // TODO: Someday account for small vs large UFO's
			else if (bIsTerrorMission)
				CueToLoad = GetTerrorMissionAmbience();
			else
				CueToLoad = GetBackgroundAmbience(); // as per Roland, play normal abduction background

			if (Len(CueToLoad) > 0)
				`CONTENT.RequestObjectAsync(CueToLoad, ObjectRequestingLoad, BackgroundCallback);
		}
		else
		{
			BackgroundCallback(AmbienceInfo.BackgroundAmbience);
		}
    }
    else
    {
        AmbienceInfo.BackgroundAmbience = none;
    }

	if (AmbienceInfo.PlayOverlayAmbience && AmbienceInfo.OverlayAmbience != none)
	{
		// Ambience is specified in the map
		OverlayCallback(AmbienceInfo.OverlayAmbience);
	}
}

function SoundCue FindKismetOverlayAmbience()
{
	local array<SequenceObject> LevelLoadedActions;
	local SequenceObject Action;
	local SeqAct_PlaySound PlaySound;
	local int OutputIdx, LinkIdx;
	local SeqEvent_LevelLoaded LevelLoaded;
	local SoundCue OverlayAmbientCue;

	// Find any PlaySound actions that are linked to LevelLoaded, and take ownership
	// of their sounds. Also, prevent them from playing, as this may disrupt the cinematic mojo -- jboswell
	class'Engine'.static.GetCurrentWorldInfo().GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_LevelLoaded', true, LevelLoadedActions);
	foreach LevelLoadedActions(Action)
	{
		LevelLoaded = SeqEvent_LevelLoaded(Action);
		for (OutputIdx = 0; OutputIdx < LevelLoaded.OutputLinks.Length; ++OutputIdx)
		{
			for (LinkIdx = 0; LinkIdx < LevelLoaded.OutputLinks[OutputIdx].Links.Length; ++LinkIdx)
			{
				PlaySound = SeqAct_PlaySound(LevelLoaded.OutputLinks[OutputIdx].Links[LinkIdx].LinkedOp);
				if (PlaySound != none)
				{
					OverlayAmbientCue = PlaySound.PlaySound;
					PlaySound.PlaySound = none;
					return OverlayAmbientCue;
				}
			}
		}
	}

	return none;
}

defaultproperties
{
}
