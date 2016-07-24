class XComCharacterVoiceBank extends object
	native(Unit)
	hidecategories(Object);

var() SoundCue HunkerDown<SpeechEvent=HunkerDown>;
var() SoundCue Reload<SpeechEvent = Reloading>;
var() SoundCue Overwatching<SpeechEvent = Overwatch>;

var() SoundCue Moving<SpeechEvent = Moving>;
var() SoundCue Dashing<SpeechEvent = Dashing>;
var() SoundCue JetPackMove<SpeechEvent = JetpackMove>;

var() SoundCue LowAmmo<SpeechEvent = LowAmmo>;
var() SoundCue OutOfAmmo<SpeechEvent = AmmoOut>;

var() SoundCue Suppressing<SpeechEvent = Suppressing>;
var() SoundCue AreaSuppressing<SpeechEvent = AreaSuppressing>;
var() SoundCue FlushingTarget<SpeechEvent = Flushing>;
var() SoundCue HealingAlly<SpeechEvent = HealingAlly>;
var() SoundCue StabilizingAlly<SpeechEvent = StabilizingAlly>;
var() SoundCue RevivingAlly<SpeechEvent = RevivingAlly>;
var() SoundCue CombatStim<SpeechEvent = CombatStim>;
var() SoundCue FragOut<SpeechEvent = ThrowGrenade>;
var() SoundCue SmokeGrenadeThrown<SpeechEvent = SmokeGrenade>;
var() SoundCue SpyGrenadeThrown<SpeechEvent = BattleScanner>;
var() SoundCue FiringRocket<SpeechEvent = FireRocket>;
var() SoundCue GhostModeActivated<SpeechEvent = GhostModeActive>;
var() SoundCue JetPackDeactivated<SpeechEvent = JetPackOff>;
var() SoundCue ArcThrower<SpeechEvent = ArcThrower>;
var() SoundCue RepairSHIV<SpeechEvent = RepairSHIV>;

var() SoundCue Kill<SpeechEvent = TargetKilled>;
var() SoundCue MultiKill<SpeechEvent = MultipleTargetsKilled>;
var() SoundCue Missed<SpeechEvent = TargetMissed>;

var() SoundCue TargetSpotted<SpeechEvent = TargetSpotted>;
var() SoundCue TargetSpottedHidden<SpeechEvent = TargetSpopttedHidden>;
var() SoundCue HeardSomething<SpeechEvent = TargetHeard>;

var() SoundCue TakingFire<SpeechEvent = TakingFire>;
var() SoundCue FriendlyKilled<SpeechEvent = SquadMemberDead>;
var() SoundCue Panic<SpeechEvent = PanicScream>;
var() SoundCue PanickedBreathing<SpeechEvent = PanickedBreathing>;
var() SoundCue Wounded<SpeechEvent = TakingDamage>;
var() SoundCue Died<SpeechEvent = DeathScream>;
var() SoundCue Flanked<SpeechEvent = SoldierFlanked>;
var() SoundCue Suppressed<SpeechEvent = Suppressed>;

var() SoundCue PsiControlled<SpeechEvent = PsionicsMindControl>;

var() SoundCue CivilianRescued<SpeechEvent = CivilianRescue>;

var() SoundCue RunAndGun<SpeechEvent = RunAndGun>;
var() SoundCue GrapplingHook<SpeechEvent = GrapplingHook>;

var() SoundCue AlienRetreat<SpeechEvent = AlienRetreat>;
var() SoundCue AlienMoving<SpeechEvent = AlienMoving>;
var() SoundCue AlienNotStunned<SpeechEvent = AlienNotStunned>;
var() SoundCue AlienReinforcements<SpeechEvent = AlienReinforcements>;
var() SoundCue AlienSighting<SpeechEvent = AlienSightings>;
var() SoundCue DisablingShot<SpeechEvent = DisablingShot>;
var() SoundCue ShredderRocket<SpeechEvent = ShredderRocket>;
var() SoundCue PsionicsMindfray<SpeechEvent = PsionicsMindfray>;
var() SoundCue PsionicsPanic<SpeechEvent = PsionicsPanic>;
var() SoundCue PsionicsInspiration<SpeechEvent = PsionicsInspiration>;
var() SoundCue PsionicsTelekineticField<SpeechEvent = PsionicsTelekineticField>;
var() SoundCue SoldierControlled<SpeechEvent = SoldierControlled>;
var() SoundCue StunnedAlien<SpeechEvent = StunnedAlien>;
var() SoundCue Explosion<SpeechEvent = Explosion>;
var() SoundCue RocketScatter<SpeechEvent = RocketScatter>;
var() SoundCue PsiRift<SpeechEvent = VolunteerPsiRift>;
var() SoundCue Poisoned<SpeechEvent = Poisoned>;

var() SoundCue HiddenMovement<SpeechEvent = HiddenMovement>;
var() SoundCue HiddenMovementVox<SpeechEvent = HiddenMovementVox>;
var() SoundCue ExaltChatter<SpeechEvent = ExaltChatter>;
var() SoundCue Strangled<SpeechEvent = Strangled>;

var() SoundCue CollateralDamage<SpeechEvent = CollateralDamage>;
var() SoundCue ElectroPulse<SpeechEvent = ElectroPulse>;
var() SoundCue Flamethrower<SpeechEvent = Flamethrower>;
var() SoundCue JetBoots<SpeechEvent = JetBoots>;
var() SoundCue KineticStrike<SpeechEvent = KineticStrike>;
var() SoundCue OneForAll<SpeechEvent = OneForAll>;
var() SoundCue ProximityMine<SpeechEvent = ProximityMine>;

var() SoundCue SoldierVIP<SpeechEvent = SoldierVIP>;
var() SoundCue UsefulVIP<SpeechEvent = UsefulVIP>;
var() SoundCue GenericVIP<SpeechEvent = GenericVIP>;
var() SoundCue HostileVIP<SpeechEvent = HostileVIP>;
var() SoundCue EngineerScienceVIP<SpeechEvent = EngineerScienceVIP>;



var native private Map_Mirror EventToPropertyMapOldVersion{TMap<BYTE, UObjectProperty*>};
var native private Map_Mirror EventToPropertyMap{ TMap<FName, UObjectProperty*> };
//var native private Map_Mirror EventToMRVMap{TMap<USoundCue*, INT>};
//var native public  MultiMap_Mirror RandomNodeChildren{TMultiMap<FString,FString>};
//var native public  MultiMap_Mirror RandomNodeUsedChildren{TMultiMap<FString,FString>};

native final function SoundCue GetSoundCue(Name EventStr);
native final function SetSoundCue(Name EventStr, SoundCue CueIn);

cpptext
{
	virtual void AddReferencedObjects(TArray<UObject*>& ObjectArray);
	virtual void Serialize(FArchive &Ar);
	TMap<FName, UObjectProperty*>* GetEventToPropertyMap();
}
