//---------------------------------------------------------------------------------------
//  FILE:    ToggleableInstancedStaticMeshComponent.uc
//  AUTHOR:  Jeremy Shopf  --  6/2/2011
//  PURPOSE: Instanced Static Mesh Component extended to support changing visibility of
//				individual instances
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class ToggleableInstancedStaticMeshComponent extends InstancedStaticMeshComponent
		native(Level);


/* An array of flags used to encode information such as a unique ID, etc. Assume int is 32-bit,
 * the highest bit is reserved for visibility (0=not visible, 1=visible). The remaining bits can be
 * used for whatever purpose and will be maintained across light builds and sorting. */
var array<int> PerInstanceBitfield;
var int        nVisibleInstances;

// Mask for visibility bit
const INSTANCE_Visibility = 0x800000;

cpptext
{


	// Functions that would be pure virtual if UnrealScript's interface functionality wasn't so lousy
    virtual void InitializeInstances(UBOOL bForceInitialization) { check(0); }
	virtual void UpdateInstancesRuntime(UBOOL bForceVisible=FALSE) { check(0); }


	//  JMS - interface to instancing types that have extended per-instance data
	virtual void ClearInstanceBitfields() { PerInstanceBitfield.Empty(); }

	virtual TArray<INT> GetInstanceBitfields() { return PerInstanceBitfield; }

	virtual void AddInstanceBitfield( int nBitfield ) { PerInstanceBitfield.AddItem( nBitfield ); }

	virtual INT GetVisibleInstanceCount() const { return Min( PerInstanceSMData.Num(), nVisibleInstances ); }

	virtual void ForceAllInstancesVisible();


	virtual void SortVisibleInstances();
	virtual void UpdateVisibleInstances();
}
