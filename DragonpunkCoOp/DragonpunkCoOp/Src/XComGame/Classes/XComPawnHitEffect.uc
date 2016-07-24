/**
 * Hit effects that are attached to pawns, e.g blood splatters, flames, etc...
 */
class XComPawnHitEffect extends GenericHitEffect;

simulated function AttachTo(Pawn P, name BoneName)
{
	local Vector ShotPosition;
	local Rotator ShotRotation;

	//Remain unattached if there's no way to get a mesh
	if (P == None || P.Mesh == None)
		return;

	//If we're trying to attach to an invalid bone, attach to the nearest instead
	if (BoneName == '' || P.Mesh.MatchRefBone(BoneName) == INDEX_NONE)
		BoneName = P.Mesh.FindClosestBone(ParticleSystemComponent.GetPosition());
	
	//If we still don't have a valid bone, abort
	if (BoneName == '' || P.Mesh.MatchRefBone(BoneName) == INDEX_NONE)
		return;

	P.Mesh.TransformToBoneSpace(BoneName, ParticleSystemComponent.GetPosition(), ParticleSystemComponent.GetRotation(), ShotPosition, ShotRotation);
	P.Mesh.AttachComponent(self.ParticleSystemComponent, BoneName, ShotPosition, ShotRotation, , );
}

DefaultProperties
{

}
