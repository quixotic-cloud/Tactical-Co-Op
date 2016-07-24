//---------------------------------------------------------------------------------------
//  FILE:    XComFadingStaticMeshComponent.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Static mesh component that transitions between two different static meshes
//           when being shown and hidden. This is a very commmon task now with the pathing pawn,
//           so abstracting out into a component to reduce code duplication. 
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2FadingStaticMeshComponent extends StaticMeshComponent
	native(Core);

var private StaticMesh VisibleMesh; // mesh displayed when this component is not hidden
var private StaticMesh HideMesh;    // mesh that will be swapped to when this component is hidden. Should play some sort of fade out.
var private float FullHideDelay;    // total seconds until the component actually hides. Should be at least as long as HideMesh's transition.

var private float HideDelayTimer; // seconds remaining in the current fadeout

cpptext
{
	// unreal overrides
	virtual void Tick(FLOAT DeltaTime);
	virtual void SetHiddenGame(UBOOL Visible);

	void DuplicateMaterials();
}

/// <summary> 
/// Sets the normal and fadeout meshes on this component. This should be used instead
/// of StaticMeshComponent::SetStaticMesh.
/// If DuplicateMaterials == true, then any MaterialInstanceTimeVarying materials on the meshes
/// will be duplicated into separate instances. This needs to be done if you plan on having the same
/// materials on multiple static meshes in different states, otherwise they will all be manipulating
/// the same material instance
/// </summary>
native function SetStaticMeshes(StaticMesh InVisibleMesh, StaticMesh InHideMesh);

/// <summary> 
/// Swaps to the fade out mesh and then hides the component when the fade is complete.
/// </summary>
native function FadeOut();

/// <summary> 
/// Returns true if this mesh is currently displaying the hide mesh, but
/// has not yet gone fully hidden
/// </summary>
native function bool IsFading();

/// <summary> 
/// Restarts the current mesh's animations
/// </summary>
native function ResetMaterialTimes();

defaultproperties
{
	FullHideDelay=5
}