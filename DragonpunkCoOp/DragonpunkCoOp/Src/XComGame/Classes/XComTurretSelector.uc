/* XComTurretSelector
 * Actor(s) placed in each level specifying spawning options for turrets.
 */
class XComTurretSelector extends Actor
	placeable
	native;

struct native TurretOption
{
	// The actor defining the location at which the turret could spawn.  
	// This actor will be destroyed in the event that a turret spawns at this location.
	var() Actor ReplacementActor;

	// The chance for this Turret to spawn at Alert Level 1, with 1.0 meaning that this turret will always spawn. 
	// (The chance increases based on higher Alert Levels).
	var() float SpawnWeight;
};

// The list of turret options which may be spawned for this level.
var() array<TurretOption> TurretOptions;

// The list of turret templates which are permissible to spawn as replacements.
var() array<Name> PossibleTurretTemplates;

cpptext
{
#if WITH_EDITOR
	virtual void CheckForErrors();
#endif
};


DefaultProperties
{
	Begin Object Class=SpriteComponent Name=EditorSpriteComponent
		Sprite=Texture2D'LayerIcons.Editor.turret_selector'
		HiddenGame=True
		Scale=0.25
	End Object
	Components.Add(EditorSpriteComponent);

	Layer=Markup

	PossibleTurretTemplates(0)=AdvTurretM1
	PossibleTurretTemplates(1)=AdvTurretM2
	PossibleTurretTemplates(2)=AdvTurretM3
}