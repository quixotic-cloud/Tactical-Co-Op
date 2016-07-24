class XComAnimatedWeapon extends XComWeapon;

var XComAnimTreeController AnimTreeController;

function XComAnimTreeController GetAnimTreeController()
{
	return AnimTreeController;
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	if (SkelComp == SkeletalMeshComponent(Mesh))
	{
		AnimTreeController = new class'XComAnimTreecontroller';
		AnimTreeController.InitializeNodes(SkelComp);
	}
}