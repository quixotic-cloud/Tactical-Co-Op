class StaticMeshCue extends Object
	native(Core)
	editinlinenew
	collapsecategories
	hidecategories(Object);

struct native StaticMeshCueEntry
{
	var() StaticMesh    StaticMesh;
	var() float         Weight;

	structdefaultproperties
	{
		Weight = 1.0f;
	}
};

var() instanced array<StaticMeshCueEntry>   StaticMeshes;

simulated native function StaticMesh Pick();
