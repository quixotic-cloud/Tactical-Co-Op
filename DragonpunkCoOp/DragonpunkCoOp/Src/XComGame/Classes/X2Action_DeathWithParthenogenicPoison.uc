//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_DeathWithParthenogenicPoison extends X2Action_Death;

function bool ShouldRunDeathHandler()
{
	return false;
}