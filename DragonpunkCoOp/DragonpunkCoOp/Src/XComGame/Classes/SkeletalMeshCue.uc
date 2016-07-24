class SkeletalMeshCue extends Object
	native(Core)
	editinlinenew
	collapsecategories
	hidecategories(Object);

struct native SkeletalMeshCueEntry
{
	var() SkeletalMesh    SkeletalMesh;
	var() float         Weight;

	structdefaultproperties
	{
		Weight = 1.0f;
	}
};

var() instanced array<SkeletalMeshCueEntry>   SkeletalMeshes;

simulated native function SkeletalMesh Pick();
