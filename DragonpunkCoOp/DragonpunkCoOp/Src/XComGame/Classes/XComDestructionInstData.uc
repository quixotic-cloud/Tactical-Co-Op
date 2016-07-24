//---------------------------------------------------------------------------------------
//  FILE:    XComDestructionInstData.uc
//  AUTHOR:  Jeremy Shopf - 09/09/2011
//  PURPOSE: Maintains instance data for destruction rendering (debris/deco meshes). Allows
//              instancing components to be divorced from prefabbed actors.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComDestructionInstData extends Object
	native(Core);

// Cached pointer to the level volume that holds this data
var transient Actor CachedOwner;

// A monotonically increasing integer used to assign ComponentJoinKeys to new instanced mesh components
var private int MaxJoinKey;

// Deprecated - kept only for serialization in of old packages
struct native DebrisMeshInfo
{
	var int ColumnIdx;
	var StaticMeshComponent MeshComponent;
};

struct native InstancedMeshKey
{
   var XComDecoFracLevelActor Actor;
   var StaticMesh             Mesh;

	structcpptext
	{
		UBOOL operator==( const FInstancedMeshKey& Other ) const;
		friend inline DWORD GetTypeHash(const FInstancedMeshKey &T)
		{
			return PointerHash(T.Mesh, PointerHash(T.Actor));
		}


		friend FArchive &operator<<(FArchive &Ar, FInstancedMeshKey &T);
	}
};

// Array to track all instancing mesh components created due to XComDecoFracLevelActors
var	const private native Map{FInstancedMeshKey, class UInstancedStaticMeshComponent*} DecoFracMeshToDecoComponents;

// Look for external references and flush if one is found
native final function FlushForEditor();

// Flush all instance data
native final function Flush();

// Remove materials that may have been mistakenly dragged and dropped on the instanced mesh components
native final function RemoveOverrideMaterials();

// Put components from all actor->component maps back onto the level volume. Because none of these components are in the defaultproperties
//     of the level volume, they have to be manually inserted back into the components array in PostLoad()
native final function AddComponentsFromMaps();

// Find components that are missing parent pointers to XComDecoFracLevelActors and fix them up
native final function CleanupMaps();

// Adds a new destruction actor and creates initial deco/debris components
native final function GenerateVisibleInstances( XComTileFracLevelActor Actor, array<int> BoundaryFragmentData );

// Adds a new destruction actor and creates initial deco/debris components
native final function FlushActor( XComDecoFracLevelActor Actor );

// Set the hidden flag on the relevent mesh primitive components
native function SetHidden( XComDecoFracLevelActor Actor, bool bShouldCutout );

// Set the cutoutflag (building visibility) on the relevent mesh primitive components
native final function SetCutoutFlag( XComDecoFracLevelActor Actor, bool bShouldCutout );

// Set the cutdownflag (building visibility) on the relevent mesh primitive components
native final function SetCutdownFlag( XComDecoFracLevelActor Actor, bool bShouldCutdown );

native final function SetCutdownHeight( XComDecoFracLevelActor Actor, float fCutdownHeight );

native final function SetVisFadeFlag( XComDecoFracLevelActor Actor, bool bVisFade, bool bForceReattach );

native final function SetPrimitiveVisHeight( XComDecoFracLevelActor Actor, float fCutdownHeight, float fCutoutHeight, float fOpacityMaskHeight, float fPreviousOpacityMaskHeight );

native final function SetPrimitiveVisFadeValues( XComDecoFracLevelActor Actor, float fCutoutFade, float fTargetCutoutFade );

// Handle map changes
native final function OnMapLoad();

// To be called when world data is initialized
native final function Initialize();

cpptext
{
	virtual void PostLoad(); 
	virtual void PreSave();
	virtual void Serialize(FArchive& Ar);
	virtual void AddReferencedObjects(TArray<UObject*>& ObjectArray);
}

defaultproperties
{
	MaxJoinKey=0;
}