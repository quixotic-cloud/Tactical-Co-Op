/**
 * XComTileEffectActor
 * Author: Russell Aasland
 * Description: Actor used to indicate tiles that should be filled with world effects at tactical start
 */
class XComTileEffectActor extends Actor
	native;

var() int Intensity;
var() class<X2Effect_World> TileEffect;

var editoronly transient ParticleSystemComponent PreviewParticleSystem;
var editoronly transient class<X2Effect_World> ActiveParticleTileEffect;

cpptext
{
	static void AddEffectsToStartState( );

	virtual void PostEditChangeProperty( struct FPropertyChangedEvent& PropertyChangedEvent );

	virtual UBOOL Tick( FLOAT DeltaTime, enum ELevelTick TickType );

	void StartParticlePreviewEffect( );
}

defaultproperties
{
	bMovable = true
		
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.EffectActorSprite'
		Scale=0.25
		AlwaysLoadOnClient=FALSE
		AlwaysLoadOnServer=FALSE
		HiddenGame=true
	End Object
	Components.Add(Sprite)
	Layer=fX
}