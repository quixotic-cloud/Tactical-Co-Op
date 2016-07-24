//---------------------------------------------------------------------------------------
//  FILE:    Checkpoint.uc
//  AUTHOR:  Ryan McFall  --  07/1/2010
//  PURPOSE: Initially brought over from Gears 2 by Dominic Cerquetti - this is a heavily
//           modified version of the save system used in that game.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class Checkpoint extends Object
	dependson(XComTacticalGRI)
	dependson(XGBattle)
	native(Core);

cpptext
{
	/** contains the platform specific setup code for writing a checkpoint */	
	void WriteCheckpoint();
	/** serializes the final data that is written to disk into the specified archive */	
	void SerializeFinalData(FArchive& Ar);
	void SaveData();
	void LoadXComArchetypes();
	void LoadData(INT CheckpointVersion);
	void Cleanup();

	UBOOL SequenceVarShouldBeSaved(FString strVarPathName);
}

struct native ActorRecord
{
	/** Full pathname of the actor this record pertains to */
	var string ActorPathName;
	/** Name of the actor this record pertains to, without path */
	var string ActorName;
	/** Position of the actor */
	var vector ActorPosition;
	/** Rotation of the actor */
	var rotator ActorRotation;
	/** Actor class in case we need to recreate it */
	var string ActorClassPath;
	/** Template */
	var int TemplateIndex;  // If this object should use a template - this will index into the ActorTemplates array
	/** Actual serialized data for this actor */
	var array<byte> RecordData;
};

/** Archetypes to load */
struct native ActorTemplateInfo
{	
	// These fields control the template load
	var string ActorClassPath;
	var string ArchetypePath;
	var byte  LoadParams[64];
	var bool  UseTemplate;

	// The result of using ActorClass, LoadParams - used by the load
	var class ActorClass;
	var Actor Template;
};

var localized string    DisplayName;    /** the save file name that shows up in the Xbox dashboard */
var class               MyClass;        /** holds the class of this checkpoint object, allows the game engine to construct
											a subclass if necessary when loading */
var int                 SlotIndex;      /** save slot number - not serialized (taken from filename) */
var string              BaseLevelName;  /** base "P" level this checkpoint was saved in */
var string              GameType;       /** base name of the game type that the saved game was created with */
var array<ActorRecord>  ActorRecords;   /** Records of actors serialized with this checkpoint. */

//Stores data for later serialization
var array<object>       ActorRecordClasses; //UScriptStructs

var array<byte>         KismetData;     /** Kismet data serialized with this checkpoint */            
var array<name>         ActorNames;     /** Contains the names for all actors in the level at the time the checkpoint was created. 
											Used to facilitate serializing object references. */
var array<name>         ClassNames;     /** Name table used to serialize class variables */
var array<ActorTemplateInfo>   ActorTemplates; /** A list of structures containing info on templates needed to spawn recorded actors */

// These are designed to be defined in the defaultproperties block of sub classes
var const array<class<Actor> > ActorClassesToRecord; /** List of the actor classes this checkpoint should attempt to record. */
var const array<class<Actor> > ActorClassesToDestroy;/** List of actor classes to destroy on checkpoint load. */
var const array<class<Actor> > ActorClassesNotToDestroy;/** List of actor classes to exclude from destruction 
															(e.g. subclasses of something in the ToDestroy list which should be exempt) */

var const bool IsMapSave;

var array<class<Actor> > OnlyApplyActorClasses; /** Use this array to apply only a subset of the check point **/

var int SyncSeed;
var int CheckpointVersion;

// Passed down from XComEngine
delegate PostSaveCheckpointCallback();
delegate PostLoadCheckpointCallback();

// MHU - Used specifically to stream in battle description dependent maps (ie. Cinematics on a per char basis).
//function AddDescriptionDependentStreamingMaps()
//{
//	local XComEngine kEngine;	
//	local XcomPlayerController PC;	
//	local XComGameReplicationInfo kGeneralGRI;

//	kGeneralGRI = XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI);	
//	//Clear the delegate once we've fired it off - or else it could stick around and cause bad mojo
//	foreach kGeneralGRI.LocalPlayerControllers( class'XComPlayerController', PC )
//	{
//		break;
//	}
//	kEngine = XComEngine(PC.Player.Outer);

//	kEngine.MapManager.AddDescriptionDependentStreamingMaps();
//}

event PreLoadCheckpoint()
{		
	OnlyApplyActorClasses.Remove(0, OnlyApplyActorClasses.Length);
}

event PostLoadCheckpoint()
{
	class'Engine'.static.GetEngine().SetRandomSeeds(SyncSeed);	
}

event PreSaveCheckpoint()
{
	SyncSeed = class'Engine'.static.GetEngine().GetSyncSeed();	
}

native final function LoadKismetData();

static native final function string GetBaseLevelName();

defaultproperties
{
/**
 *  Define these subclass defaultproperties for new 'types' of checkpoint: 
 *  
 *  ActorClassesToRecord;           List of the actor classes this checkpoint should attempt to record.		
 *  ActorClassesToDestroy;          List of actor classes to destroy on checkpoint load.
 *  ActorClassesNotToDestroy;       List of actor classes to exclude from destruction 
*/
}
