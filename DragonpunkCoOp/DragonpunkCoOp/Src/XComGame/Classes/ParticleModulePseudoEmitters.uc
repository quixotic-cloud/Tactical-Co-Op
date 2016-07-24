/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class ParticleModulePseudoEmitters extends ParticleModuleSpawnBase
	native(Particle)
	editinlinenew
	hidecategories(Object,Spawn,Burst);

//=============================================================================
//	Properties
//=============================================================================

enum ReadWriteOption
{
	eStoreLocations,
	eSpawnFromLocations
};

/* Store Locations for other emitters or use data from another emitter? */
var() ReadWriteOption   m_ModuleOperations;

/* Name of the emitter in the PSC to grab the location data from. */
var(PseudoEmitter) Name      m_sEmitterName;

/* Time before pseduo emitter begins emitting particles */
var(PseudoEmitter) float     m_fActivationDelay;

/* Time after activating before pseudo emitter ends. */
var(PseudoEmitter) float     m_fDuration;

/* Spawn Rate for the pseudo emitters. */
var(PseudoEmitter) float     m_fSpawnRate;

/* Holds a reference to the emitter that has the data we want. */
var transient native pointer  m_pEmitterWithStoredData{FParticleEmitterInstance};

/* Variables used to keep track the range of psuedo emitters currently active. */
var transient int            m_iMinSpawningEmitterIndex;
var transient int            m_iMaxSpawningEmitterIndex;

//=============================================================================
//	C++
//=============================================================================
cpptext
{
public:
	virtual UBOOL GetSpawnAmount(FParticleEmitterInstance* Owner, INT Offset, FLOAT OldLeftover, 
		FLOAT DeltaTime, INT& Number, FLOAT& Rate);

	virtual void Spawn(FParticleEmitterInstance* Owner, INT Offset, FLOAT SpawnTime);
}

//=============================================================================
//	Default properties
//=============================================================================
defaultproperties
{
	bSpawnModule=true
	bUpdateModule=false

	m_ModuleOperations=eSpawnFromLocations;

	m_fActivationDelay=1;
	m_fDuration=2;
	m_fSpawnRate=1;

	m_iMinSpawningEmitterIndex=-1
	m_iMaxSpawningEmitterIndex=-1
}
