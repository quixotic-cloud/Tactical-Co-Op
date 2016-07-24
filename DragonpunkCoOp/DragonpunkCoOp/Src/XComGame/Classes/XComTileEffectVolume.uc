/**
 * XComTileEffectActor
 * Author: David Burchanowski
 * Description:Volume used to indicate tiles that should be filled with world effects at tactical start.
 *              Note that startup logic is handled by XComTileEffectActor. Both do essentially the same thing,
 *              but since we already have a large amount of markup using the actor version of this functionality,
 *              it doesn't make sense to go back and change it. So they share what they can
 */
class XComTileEffectVolume extends Volume
	placeable
	native;

var() int Intensity;
var() class<X2Effect_World> TileEffect;
var() bool AutoApplyAtMissionStart;
var() float Coverage; // Percentage, 0.0-1.0, of the volume that should have the effect applied.

var editoronly transient ParticleSystemComponent PreviewParticleSystem;
var editoronly transient class<X2Effect_World> ActiveParticleTileEffect;

cpptext
{
	virtual void PostEditChangeProperty( struct FPropertyChangedEvent& PropertyChangedEvent );
	virtual UBOOL Tick( FLOAT DeltaTime, enum ELevelTick TickType );

	void StartParticlePreviewEffect( );
}


// returns a list of all tiles that lie inside this volume and should have the effect applied,
// as well as the intensity that should be applied at each tile
// If AllPossible is true, the Coverage parameter is ignored and every possible tile is returned.
// This is to support clearing the effect, since the random coverage is not deterministic
native function GetAffectedTiles(out array<TilePosPair> Tiles, out array<int> Intensities, optional bool AllPossible = true);

// Applies the effect to all units in the specified tiles (basically the result from GetAffectedTiles)
native function ApplyToUnits(const out array<TilePosPair> Tiles, const out array<int> Intensities, XComGameState NewGameState);

// Removes this effect from all tiles contained in the volume
native function ClearAffectedTiles(XComGameState NewGameState);

// Adds visualization for a game state that called ApplyToUnits or ClearAffectedUnits
function AddVisualizationTracks(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local X2Effect_World WorldEffect;
	local XComGameState_WorldEffectTileData WorldEffectData;
	local XComGameState_Unit UnitState;
	local VisualizationTrack BuildTrack;
	local VisualizationTrack EmptyTrack;
	local StateObjectReference EffectStateRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent ApplyEffect;

	WorldEffect = X2Effect_World(class'XComEngine'.static.GetClassDefaultObject(TileEffect));

	// do visualization for the world
	foreach GameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldEffectData)
	{
		BuildTrack.StateObject_OldState = WorldEffectData;
		BuildTrack.StateObject_NewState = WorldEffectData;
		WorldEffect.AddX2ActionsForVisualization(GameState, BuildTrack, '');
		VisualizationTracks.AddItem(BuildTrack);
		break;
	}

	// and for the units
	foreach GameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = UnitState;
		BuildTrack.StateObject_NewState = UnitState;

		foreach UnitState.AffectedByEffects(EffectStateRef)
		{
			EffectState = XComGameState_Effect(GameState.GetGameStateForObjectID(EffectStateRef.ObjectID));
			if( EffectState != none )
			{
				//Assume that effect names are the same for each tile
				ApplyEffect = EffectState.GetX2Effect();
				if( ApplyEffect != none && GameState.GetGameStateForObjectID(EffectState.ObjectID) != none ) // only visualize effects that were added in this state
				{
					ApplyEffect.AddX2ActionsForVisualization(GameState, BuildTrack, 'AA_Success');
				}
			}
		}

		if(BuildTrack.TrackActions.Length > 0)
		{
			VisualizationTracks.AddItem(BuildTrack);
		}
	}
}

defaultproperties
{
	bMovable=true
	AutoApplyAtMissionStart=true
	Coverage=0.25
		
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