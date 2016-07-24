//---------------------------------------------------------------------------------------
//  FILE:    XComContentManager.uc
//  AUTHOR:  Justin Boswell
//  PURPOSE: Responsible for managing the dynamic content for XCom. Units, weapons, etc.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComContentManager extends Object
	native(Core)
	inherits(FTickableObject)
	dependson(XGGameData,XGTacticalGameCore)
	config(Content);

enum EUIMode
{
	eUIMode_Common,
	eUIMode_Shell,
	eUIMode_Tactical,
	eUIMode_Strategy,
};

enum EColorPalette
{
	ePalette_HairColor<DisplayName=Hair Color>,
	ePalette_ShirtColor<DisplayName=Shirt Color>,
	ePalette_PantsColor<DisplayName=Pants Color>,
	ePalette_FormalClothesColor<DisplayName=Formal Clothes Color>,
	ePalette_CaucasianSkin<DisplayName=Caucasian Skin>,
	ePalette_AfricanSkin<DisplayName=African Skin>,
	ePalette_HispanicSkin<DisplayName=Hispanic Skin>,
	ePalette_AsianSkin<DisplayName=Asian Skin>,
	ePalette_EyeColor<DisplayName=Eye Color>,
	ePalette_ArmorTint<DisplayName=Armor Tints>,
};

struct native ArchetypeLoadedCallback
{
	var object Target;
	var delegate<OnArchetypeLoaded> Callback;
	var int ArchetypeIndex;
};

struct native XComPackageInfo
{
	var init config string ArchetypeName;
	var transient object Archetype; // populated once game is running
	var init array<ArchetypeLoadedCallback> LoadedCallbacks<FGDEIgnore=true>;
};

struct native GameArchetypeLoadedCallback
{
	var Object  Target;
	var delegate<OnObjectLoaded>    Callback;
	var Object  GameArchetype;
};

struct native XComColorPalettePackageInfo extends XComPackageInfo
{
	var config EColorPalette Palette;
};

//------------------------------------------------------------------------------
// Config values set in DefaultContent.ini
//------------------------------------------------------------------------------
var config int DefaultPrimaryWeaponTint;
var config int DefaultEngineerArmorTint;
var config int DefaultScientistArmorTint;
var config int DefaultEngineerArmorTintSecondary;
var config int DefaultScientistArmorTintSecondary;
var config protected array<XComColorPalettePackageInfo> ColorPaletteInfo;
var config protected array<string> LoadingMovieAudioEventPaths; // List of Wise events to keep resident in memory so they can play behind bink loading movies


var transient array<string> RequiredArchetypes; // A list of archetypes to load when CacheContent is called
var protected transient array<XComPerkContent> PerkContent;
var private init array<GameArchetypeLoadedCallback>  m_arrGameArchetypeCallbacks;
var config bool	bAllowJITLoad;
var EUIMode LastUIMode;
var array<object> MapContent; // Cache of loaded UI content, gets cleared between maps
var privatewrite bool bNeedsFlushForGC;

// Local cache of data from Tactical/Strategy Resources packages. We maintain a local copy
// so that requests don't have to go through DLO/FindObject, which interact badly with async loading
var const private native Map_Mirror ResourceTags{TMap<FString,TArray<FString> >};
var const private native Map_Mirror GameContentCache{TMap<FString,UObject*>};
var private array<AkEvent> LoadingMovieAudioEvents;

//------------------------------------------------------------------------------
// Game State Content hooks
//------------------------------------------------------------------------------

// The Path name to the effect that should be played to represent the destruction of a unit's loot when it's timer expires
var config string LootExpiredEffectPathName;

// The Path name to the effect that should be played to represent the destruction of a unit's loot for each loot item when it's timer expires
var config string LootItemExpiredEffectPathName;

// The Path name to the effect that should be played to represent the ATT flare
var config string ATTFlareEffectPathName;

// The Path name to the effect that should be played to represent the PsiGate
var config string PsiGateEffectPathName;

// The Path name to the effect that should be played when a unit warps in via psi gate
var config string PsiWarpInEffectPathName;

// The amount of time to focus on this spawner when it spawns
var config float LookAtCamDuration;
//----------------------------------

// Called when an archetype with package info is loaded and ready to use
delegate OnArchetypeLoaded(Object LoadedArchetype, int ContentID, int SubID);
//  Used when a non-package info type of content gets loaded
delegate OnObjectLoaded(Object LoadedArchetype);

//------------------------------------------------------------------------------
// External interface ( game code )
//------------------------------------------------------------------------------

// Loads the object / archetype specified by ArchetypeName. This is the main point of contact for external systems to interact with the content manager
// NOTE: this can only return an object for a synchronous request!!!
// NOTE: callbacks for synchronous requests will happen synchronously!!!
native final function Object RequestGameArchetype(string ArchetypeName, optional Object CallbackObject, optional delegate<OnObjectLoaded> Callback, optional bool bAsync);

// Legacy from XEU, but still the method to call to get Color Palettes
native final function XComLinearColorPalette GetColorPalette(EColorPalette PaletteType);

// Perk Content Handling
native final function AppendAbilityPerks(name AbilityName, XComUnitPawnNativeBase UnitPawn, optional bool bUnique = false);
native final function  CachePerkContent();
native final function  ClearPerkContentCache();

//------------------------------------------------------------------------------
// External interface ( systems code )
//------------------------------------------------------------------------------
simulated native function RequestContent();
simulated native function ClearRequestedContent();

//Helper methods used as part of RequestGameArchetype. Shouldn't really be used directly.
native final function RequestObjectAsync(string Object, optional object CallbackObject, optional delegate<OnObjectLoaded> Callback, optional bool AddToGameCache);
native final function UnCacheObject(string Object);
native final function ClearContentCache(optional bool bClearMapContent = true, optional bool bInitiateGCAfterClear = false);
native final function CacheGameContent(const out string ContentTag, object ObjectToCache);
native final function object GetGameContent(coerce string ContentTag);
simulated native function FlushArchetypeCache();

cpptext
{
	void Init();

	void LoadRequiredContent(const FURL &URL, UBOOL bAsync=FALSE);
	void LoadMapContent(const FURL &URL, UBOOL bAsync=FALSE);
	void UnloadMapContent();
	void ClearLoadedContent(UBOOL bClearMapContent=TRUE);

	void CacheContent(UBOOL bAsync=FALSE);
	//CallbackObject and CallbackFn are used to detect when an archetype has finished loading - Return value is the number of archetypes requested
	INT CacheContentAsync(UObject* CallbackObject, FScriptDelegate CallbackFn=FScriptDelegate(EC_EventParm));

	virtual void PostReloadConfig(UProperty *Property);

	static void LoadObjectAsync(const FString &ObjectPath, FAsyncCompletionCallback Callback, void *CallbackData);

	template <typename... Args>
	static void LoadObjectAsync(const FString &ObjectPath, XComContentLoading::ICallable<Args...> *Callback);

	// FTickableObject interface

	/**
	 * Returns whether it is okay to tick this object. E.g. objects being loaded in the background shouldn't be ticked
	 * till they are finalized and unreachable objects cannot be ticked either.
	 *
	 * @return	TRUE if tickable, FALSE otherwise
	 */
	virtual UBOOL IsTickable() const;
	/**
	 * Used to determine if an object should be ticked when the game is paused.
	 *
	 * @return always FALSE as we wait to dispatch callbacks while the game is paused.
	 */
	virtual UBOOL IsTickableWhenPaused() const;
	/**
	 * Just calls the tick event
	 *
	 * @param DeltaTime The time that has passed since last frame.
	 */
	virtual void Tick(FLOAT DeltaTime);
}

simulated native static function Object LoadObjectFromContentPackage(string ObjectName);

simulated native function UpdateContentEntitlements();

defaultproperties
{
	LastUIMode = eUIMode_Common
}
