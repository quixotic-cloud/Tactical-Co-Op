class XComCharacterVoice extends object	
	native(Unit)
	hidecategories(Object);


// Allow designers to hook up the banks directly here, but then clear this out on consoles
var() notforconsole array<XComCharacterVoiceBank> VoiceBanks;
// List of names that we will use to async load the packages, maintained by PostEditChangeProperty/PostLoad
var() private editconst const array<string> VoiceBankNames;
// The bank that sounds will be pulled from at runtime, updated by streaming
var privatewrite const transient XComCharacterVoiceBank CurrentVoiceBank;
var privatewrite const transient bool bStreamingRequestInFlight;

var() string AkBankName;
var() string AkCustomizationEventName;
var int akBankId;

var() SoundCue CharacterCustomizationCue;

native final function SoundCue GetSoundCue(Name nEvent);
native final function StreamNextVoiceBank(optional bool bForce=false);

native final function PlayAkEvent(Name nEvent, Actor Owner);

function PlaySoundForEvent(Name nEvent, Actor Owner)
{
	local SoundCue Cue;
	local bool bProfileSettingsEnabledChatter;
	local bool bKismetDistabledChatter;
	local bool bChatterDistabledByINI;
	local array<string> EventStrings;

	bProfileSettingsEnabledChatter = `XPROFILESETTINGS != none && `XPROFILESETTINGS.Data.m_bEnableSoldierSpeech;
	bKismetDistabledChatter = `BATTLE != none && `BATTLE.m_kDesc.m_bDisableSoldierChatter;
	bChatterDistabledByINI = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().DisableCharacterVoices;

	if(!bProfileSettingsEnabledChatter || bKismetDistabledChatter || bChatterDistabledByINI)
		return;

	if( akBankId != 0 )
	{
		PlayAkEvent(nEvent, Owner);
		return;
	}

	// It is normal to not get a cue, some sound banks will not include a cue for certain events
	// e.g. You don't always need a soldier to talk when he throws a grenade or dashes
	Cue = GetSoundCue(nEvent);
	if (Cue != none)
	{
		Owner.PlaySound(Cue, true);
		StreamNextVoiceBank(true);
	}
	else
	{
		//If we didn't find a match, see if this was a whisper line or personality line. If so, try falling back to the regular variant.
		EventStrings = SplitString(string(nEvent), "_");
		if(EventStrings.Length > 0)
		{
			Cue = GetSoundCue(Name(EventStrings[0]));
			if(Cue != none)
			{
				Owner.PlaySound(Cue, true);
				StreamNextVoiceBank(true);
			}
			else
			{
				StreamNextVoiceBank(true);
				`log("No sound cue for event" @ nEvent, , 'DevSound');
			}
		}
		else
		{
			StreamNextVoiceBank(true);
			`log("No sound cue for event" @ nEvent, , 'DevSound');
		}
	}
}

cpptext
{	
	virtual void Serialize(FArchive& Ar);
	virtual void PostLoad();
	virtual void BeginDestroy();
	virtual void PostEditChangeProperty(FPropertyChangedEvent &PropertyThatChanged);

	static void OnVoiceBankLoaded(UObject *LoadedObject, void *CallbackData);

}
