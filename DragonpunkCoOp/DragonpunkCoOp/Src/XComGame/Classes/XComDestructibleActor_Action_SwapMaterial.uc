class XComDestructibleActor_Action_SwapMaterial extends XComDestructibleActor_Action
	native(Destruction);

enum MaterialSwapType
{
	SWAP_SingleIndexOnly,
	SWAP_AllIndices
};

struct native MaterialSwap
{
	var() MaterialInterface SwapMaterial;
	var() MaterialSwapType  SwapType;
	var() int               MaterialIndex;	
};

var (XComDestructibleActor_Action) array<MaterialSwap>    MaterialsToSwap;

native function Activate();

defaultproperties
{
}
