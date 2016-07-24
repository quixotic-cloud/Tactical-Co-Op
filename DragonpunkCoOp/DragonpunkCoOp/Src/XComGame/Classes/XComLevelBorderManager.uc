class XComLevelBorderManager extends Actor
	native(Level)
	config(Game)
	dependson(XComWorldData);

var InstancedStaticMeshComponent m_kLevelBorderWalls;

var transient const globalconfig int    LevelBorderTileRange;
var transient const globalconfig int    LevelBorderHeightRange;

var const string                  LevelBorderStaticMeshName;

var private int                         PreviousTileCalculated[3];

var transient bool                      bGameHidden;
var transient bool                      bCinematicHidden;

function InitManager()
{
	m_kLevelBorderWalls.SetTranslation(vect(0,0,0));
	m_kLevelBorderWalls.SetRotation(rot(0,0,0));

	m_kLevelBorderWalls.SetStaticMesh( StaticMesh(DynamicLoadObject(LevelBorderStaticMeshName,class'StaticMesh')) );
}

native function SetBorderGameHidden(const bool bNewGameHidden);
native function SetBorderCinematicHidden(const bool bNewCinematicHidden);

native function ShowBorder(const bool bShow);
native function UpdateCursorLocation(const out Vector CursorLocation, optional const bool bForceRefresh=false);

defaultproperties
{
	begin object class=InstancedStaticMeshComponent name=LevelBorderWall
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		HiddenGame=false
		HiddenEditor=true
		AbsoluteRotation=true
		AbsoluteTranslation=true
		bTranslucentIgnoreFOW=true
	end object
	Components.Add(LevelBorderWall);
	m_kLevelBorderWalls=LevelBorderWall;

	LevelBorderStaticMeshName="UI_Cover.Meshes.LevelBorderTile"

	PreviousTileCalculated[0] = -1
	PreviousTileCalculated[1] = -1
	PreviousTileCalculated[2] = -1

	bGameHidden=false
	bCinematicHidden=false
}