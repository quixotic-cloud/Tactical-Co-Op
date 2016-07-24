// ---------------------------------------------------
// Decal Cue
// ---------------------------------------------------
// Works kind of like a sound cue
//
// It contains one or more particle system to choose
// from at runtime and special information about them
//
// (c) 2008 Firaxis Games
// Author: Dominic Cerquetti (dcerquetti@firaxis.com)
// ---------------------------------------------------

class DecalCue extends Object
	native(Graphics)
	editinlinenew
	hidecategories(Object)
	collapsecategories;
	
struct native DecalCueEntry
{	
	/**
	 *  Choose the decal material to be used for this entry. Overrides values in the template.
	 */
	var() MaterialInterface DecalMaterial;

	/**
	 *  The chance that this decal entry will be used relative to the weights of the rest of the entries. If all
	 *  entries are equal they have an equal chance of being used.
	 */
	var() float Weight;

	structdefaultproperties
	{
		Weight = 1.0f;
	}
};

/**
 *  A data structure that encapsulates the common properties that users may want to set on decals
 */
struct native DecalProperties
{
	var() float DecalWidthLow<ToolTip="Sets the minimum width of the decal projection volume (Unreal Units)">;
	var() float DecalWidthHigh<ToolTip="Sets the maximum width of the decal projection volume (Unreal Units)">;
	var() float DecalHeightLow<ToolTip="Sets the minimum height of the decal projection volume (Unreal Units)">;
	var() float DecalHeightHigh<ToolTip="Sets the maximum height of the decal projection volume (Unreal Units)">;
	var() float DecalDepth<ToolTip="Defines how long the decal's projection volume should be (Unreal Units)">;
	var() float DecalLifespan<ToolTip="Sets the lifespan of the decal (Seconds). 0.0 sets the system to use the world default.">;	
	var() float DecalBackfaceAngle<ToolTip="This value controls how permissive the decal is with respect to projecting on to surfaces at an angle to it.">;
	var() bool  bUseRandomRotation<ToolTip="If checked, the decal will use a random rotation when placed">;
	var() vector2D DecalBlendRange<ToolTip="Start/End blend range specified as an angle in degrees. Controls where to start blending out the decal on a surface">;
	var() int SortOrder<ToolTip="Controls the order in which decal elements are rendered.  Higher values draw later (on top)">;

	structdefaultproperties
	{
		DecalWidthLow = 200.0f;
		DecalWidthHigh = 200.0f;		
		DecalHeightLow = 200.0f;
		DecalHeightHigh = 200.0f;
		DecalLifespan = 0.0f;
		DecalBackfaceAngle = 0.001f;
		DecalDepth = 200.0f;
		bUseRandomRotation = TRUE;
		DecalBlendRange=(X=89.5,Y=180);
		SortOrder = 0;
	}
};
	
var() array<DecalCueEntry> DecalMaterials;

native protected function int PickDecalIndexToUse();

function MaterialInterface PickDecal()
{
	if (DecalMaterials.Length <= 0)
		return none;

	return DecalMaterials[PickDecalIndexToUse()].DecalMaterial;
}

static function SpawnDecalFromCue(  DecalManager DecalMgr,
									DecalCue Cue,
									DecalProperties DecalSettings,
									float DepthBias,
									Vector PlacementLocation,
									Rotator ProjectionDir,
									optional PrimitiveComponent OverrideComponent = none,
									optional bool bProjectOnTerrain = true,
									optional bool bProjectOnSkeletal = true,
									optional TraceHitInfo HitInfo)
{	
	// MHU - Cue null check, logspam fix
	if (Cue != none)
	{
		class'DecalCue'.static.SpawnDecal( DecalMgr, 
										   Cue.PickDecal(), 
										   DecalSettings, 
										   DepthBias,
										   PlacementLocation, 
										   ProjectionDir, 
										   OverrideComponent, 
										   bProjectOnTerrain, 
										   bProjectOnSkeletal, 
										   HitInfo );	
	}
}

static function SpawnDecal( DecalManager DecalMgr,
							MaterialInterface UseMaterial, 
							DecalProperties DecalSettings,
							float DepthBias,
							Vector PlacementLocation,
							Rotator ProjectionDir,
							optional PrimitiveComponent OverrideComponent = none,
							optional bool bProjectOnTerrain = true,
							optional bool bProjectOnSkeletal = true,
							optional TraceHitInfo HitInfo)
{
	local float fRotation;
	local float fWidth;
	local float fHeight;
	local float fDepth;	
	local float fBackfaceAngle;
	local float fLifespan;	
	local vector2d kDecalBlendRange;
	local MaterialInstanceTimeVarying MITV;

	//Constants
	local  float kDefaultDecalScale;
	local  float kDefaultDecalBackfaceAngle;
	local vector2d kDefaultDecalBlendRange;

	kDefaultDecalScale = 200.0f;
	kDefaultDecalBackfaceAngle = 0.001f;
	kDefaultDecalBlendRange = vect2d(89.5,180);

	if (UseMaterial == none)
		return;
		
	fRotation = FRand() * 360.0;	
	fWidth = RandRange(DecalSettings.DecalWidthLow, 
					   DecalSettings.DecalWidthHigh);
	fWidth = fWidth > 0.0f ? fWidth : kDefaultDecalScale;
	fHeight = RandRange(DecalSettings.DecalHeightLow, 
						DecalSettings.DecalHeightHigh);
	fHeight = fHeight > 0.0f ? fHeight : kDefaultDecalScale;
	fDepth = DecalSettings.DecalDepth;	
	fLifespan = DecalSettings.DecalLifespan > 0.0f ? DecalSettings.DecalLifespan : DecalMgr.DecalLifeSpan;	
	fBackfaceAngle = DecalSettings.DecalBackfaceAngle;
	fBackfaceAngle = fBackfaceAngle != 0.0f ? fBackfaceAngle : kDefaultDecalBackfaceAngle;	
	kDecalBlendRange = (DecalSettings.DecalBlendRange.X == 0.0f && DecalSettings.DecalBlendRange.Y == 0.0f) ? kDefaultDecalBlendRange : 
																											  DecalSettings.DecalBlendRange;
		
	if (UseMaterial.IsA('MaterialInstanceTimeVarying'))
	{
		 MITV = new class'MaterialInstanceTimeVarying';
		 MITV.SetParent(UseMaterial);
		 MITV.SetDuration(fLifespan);
		 UseMaterial = MITV;
	}

	//This is a work around the fact that sort order doesn't appear to work consistently for dynamic decals
	DepthBias -= DecalSettings.SortOrder * 0.001;

	DecalMgr.SpawnDecal( UseMaterial, 
						 PlacementLocation, 
						 ProjectionDir, 
						 fWidth, 
						 fHeight, 
						 fDepth, 
						 false, 
						 fRotation, 
						 OverrideComponent, 
						 bProjectOnTerrain, 
						 bProjectOnSkeletal, 
						 HitInfo.BoneName, 
						 HitInfo.Item, 
						 HitInfo.LevelIndex,
						 fLifespan,
						 , 
						 DepthBias,
						 fBackfaceAngle,
						 kDecalBlendRange,
						 DecalSettings.SortOrder);
}