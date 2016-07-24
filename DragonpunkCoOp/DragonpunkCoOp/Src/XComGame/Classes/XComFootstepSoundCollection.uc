class XComFootstepSoundCollection extends Object;

// Pair/Map of material type -> sound cue
struct MaterialSoundPair
{
	// the type of material, as specified in XComPhysicalMaterialProperty
	var() EMaterialType		MaterialType;

	// the sound cue to use for this type of material
	var() SoundCue			SoundCue<ToolTip="Sound to use when it's NOT raining">;

	var() SoundCue          SoundSplashCue<Tooltip="Sound to play when it IS raining">;
};

// map of material type to footstep sounds.
var() array<MaterialSoundpair>			FootstepSounds;

function SoundCue GetFootstepSoundInArray(int FootstepSoundIndex, bool bIsOutsideAndIsRaining)
{
	local SoundCue SoundCue;

	if (bIsOutsideAndIsRaining)
		SoundCue = FootstepSounds[FootstepSoundIndex].SoundSplashCue; // rainy
				
	if (!bIsOutsideAndIsRaining || SoundCue == none)
		SoundCue = FootstepSounds[FootstepSoundIndex].SoundCue; // normal

	return SoundCue;
}

/**
 * Plays the character's footstep sound for the given foot index
 * @param P  	         The pawn to play the footstep sound for
 * @param FootIndex	     Which foot index to play
 * @param MaterialType	 The type of material the character is stepping on, as defined in XComPhysicalMaterialProperty
 */
function PlayFootstepSound( Pawn P, int FootIndex, EMaterialType MaterialType, bool bIsOutsideAndIsRaining )
{
	local int FootstepSoundIndex;
	local SoundCue SoundCue;
	
	FootstepSoundIndex = FootstepSounds.Find( 'MaterialType', MaterialType );

	if ( FootstepSoundIndex >= 0 )
	{
		// normal case, should be 100% of the time
		SoundCue = GetFootstepSoundInArray(FootstepSoundIndex, bIsOutsideAndIsRaining);
	}
	else
	{
		FootstepSoundIndex = FootstepSounds.Find( 'MaterialType', MaterialType_Default );
			
		if (FootstepSoundIndex >= 0)
		{
			// use the default material if it exists
			SoundCue = GetFootstepSoundInArray(FootstepSoundIndex, bIsOutsideAndIsRaining);
		}
		else if (FootstepSounds.Length > 0)
		{
			// we have no other choice: Take a wild guess and play the 
			// first footstep in the array if we can 
			SoundCue = GetFootstepSoundInArray(0, bIsOutsideAndIsRaining);
		}		
	}
	
	// play the sound, make sure it doesn't replicate
	if ( SoundCue != none )
		P.PlaySound( SoundCue, true );
}

defaultproperties
{	
}