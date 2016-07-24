class X2Effect_OverrideDeathAnimOnLoad extends X2Effect_Persistent;

var name OverrideAnimNameOnLoad;

function bool HasOverrideDeathAnimOnLoad(out Name DeathAnim)
{
	local bool HasOverrideAnim;

	HasOverrideAnim = OverrideAnimNameOnLoad != '';
	if( HasOverrideAnim )
	{
		DeathAnim = OverrideAnimNameOnLoad;
	}

	return HasOverrideAnim;
}

defaultproperties
{
	Name="OverrideDeathAnimOnLoad"
	OverrideAnimNameOnLoad=""
}