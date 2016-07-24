/* XComHackReplacor
 * Actor(s) placed in each level specifying spawning options for Hackables.
 */
class XComHackReplacor extends Actor
	placeable
	native;

// The actors defining the locations at which the Hackable could spawn.  
// These actors will be destroyed in the event that a Hackable spawns at their location.
var() array<Actor> ReplacementActors;


// The Interactive level actor archetype that could spawn in as a replacement.
var() XComBlueprint ReplacementBlueprint;


cpptext
{
#if WITH_EDITOR
	virtual void CheckForErrors();
#endif
};


DefaultProperties
{
	Begin Object Class=SpriteComponent Name=EditorSpriteComponent
	Sprite = Texture2D'LayerIcons.Editor.tower_selector'
		HiddenGame=True
		Scale=0.25
	End Object
	Components.Add(EditorSpriteComponent);

	ReplacementBlueprint=XComBlueprint'AdventTower.Blueprints.BP_AdventTower_1x1'

	Layer=Markup
}