interface XComCoverInterface
	native(Cover);

enum ECoverForceFlag
{
	CoverForce_Default,
	CoverForce_High,
	CoverForce_Low,
};

simulated native function bool ConsiderForOccupancy();
simulated native function bool ShouldIgnoreForCover();
simulated native function bool CanClimbOver();
simulated native function bool CanClimbOnto();
simulated native function bool UseRigidBodyCollisionForCover();
simulated native function ECoverForceFlag GetCoverForceFlag();
simulated native function ECoverForceFlag GetCoverIgnoreFlag();
