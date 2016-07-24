//-----------------------------------------------------------
// FIRAXIS GAMES: Blend IK notify
//
// "Replaces" AnimNotify_PlayParticleSystem with a version that can do
// multiple particle systems.
//
// (c) 2008 Firaxis Games
//-----------------------------------------------------------

class AnimNotify_PlayEffectCue extends AnimNotify_PlayParticleEffect
	native(Animation)
	hidecategories(ParticleSystems);

var() /*editinline*/ EffectCue EffectCueToPlay;
	
cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
}

defaultproperties
{

}