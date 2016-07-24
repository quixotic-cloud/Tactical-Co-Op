class XComWeaponComponent extends ActorComponent
	hidecategories(Object)
	editinlinenew
	abstract
	collapsecategories
	native(core);

// projectile system is already hacked to shit so need to add hack flag to let the systems know its a mind merge death so we correctly replicate. -tsmith 
simulated function CustomFire(optional bool bCanDoDamage = true, optional bool HACK_bMindMergeDeathProjectile = false) {}

simulated event vector GetMuzzleLoc(bool bPreview)
{
	local vector pt3Loc;
	SkeletalMeshComponent(XComWeapon(Outer).mesh).GetSocketWorldLocationAndRotation('gun_fire', pt3Loc);
	return pt3Loc;
}

simulated event rotator GetMuzzleRotation()
{
	local vector pt3Loc;
	local rotator pt3Rot;
	SkeletalMeshComponent(XComWeapon(Outer).mesh).GetSocketWorldLocationAndRotation('gun_fire', pt3Loc ,pt3Rot);
	return pt3Rot;
}