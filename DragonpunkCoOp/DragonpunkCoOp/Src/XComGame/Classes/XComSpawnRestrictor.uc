/* XComSpawnRestrictor
 * Actor(s) placed in each level specifying restrictions on spawning for particular areas.
 */
class XComSpawnRestrictor extends Actor
	placeable
	native;

// The list of volumes describing the area this restrictor affects.
var() array<Volume> Volumes;

// If true, all civilian character types will always be restricted from spawning within these volumes, 
// regardless of other settings.
var() bool CiviliansRestricted;

// If true, all Advent character types will always be restricted from spawning within these volumes, 
// regardless of other settings.
var() bool AdventRestricted;

// If true, all Alien character types will always be restricted from spawning within these volumes, 
// regardless of other settings.
var() bool AliensRestricted;

// If non-empty, the list of character templates which can spawn within these volumes.
var() array<Name> SpawnTemplateInclusionList;

// The list of character templates which are never allowed to spawn within these volumes.
var() array<Name> SpawnTemplateExclusionList;

// If true, all AI units will be restricted from pathing to any tile within these volumes.
var() bool bDisallowPathing <DisplayName=Disallow AI Pathing>;

function bool TemplateRestricted(X2CharacterTemplate Template)
{
	if( Template == None )
	{
		return false;
	}

	if( (CiviliansRestricted && Template.bIsCivilian) ||
	   (AdventRestricted && Template.bIsAdvent) ||
	   (AliensRestricted && Template.bIsAlien) ||
	   (SpawnTemplateInclusionList.Find(Template.DataName) == INDEX_NONE && SpawnTemplateInclusionList.Length > 0) ||
	   (SpawnTemplateExclusionList.Find(Template.DataName) != INDEX_NONE) )
	{
		return true;
	}

	return false;
}

function DrawDebugVolume(Canvas kCanvas)
{
	local Volume CurrentVolume;

	foreach Volumes(CurrentVolume)
	{
		DrawDebugBox(CurrentVolume.BrushComponent.Bounds.Origin, CurrentVolume.BrushComponent.Bounds.BoxExtent, 255, 0, 0, false);
	}
}

function bool IsPathLocationRestricted(vector TileLocation)
{
	local Volume RestrictedVolume;
	if( bDisallowPathing )
	{
		foreach Volumes(RestrictedVolume)
		{
			if( RestrictedVolume != None && RestrictedVolume.EncompassesPoint(TileLocation) )
			{
				return true;
			}
		}
	}
	return false;
}


static function bool IsInvalidPathLocation(vector TestLocation)
{
	local XComSpawnRestrictor Restrictor;

	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComSpawnRestrictor', Restrictor)
	{
		if( Restrictor.IsPathLocationRestricted(TestLocation) )
		{
			return true;
		}
	}
	return false;
}

//Native variant of IsInvalidPathLocation for optimization
static function native bool IsInvalidPathLocationNative(const out vector TestLocation);

DefaultProperties
{
	Begin Object Class=SpriteComponent Name=EditorSpriteComponent
		Sprite=Texture2D'LayerIcons.Editor.spawn_restrictor'
		HiddenGame=True
		Scale=0.25
	End Object
	Components.Add(EditorSpriteComponent);

	Layer=Markup
}