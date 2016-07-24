/***************************************************
 X2AbilityMultiTarget_AllAllies
 
 This multi target script grabs all allies of the PRIMARY TARGET of the ability.
 So if your ability is friendly, it will be all your friends.
 If your ability is hostile, it will be all your enemies.
 And so on.
 **************************************************/
class X2AbilityMultiTarget_AllAllies extends X2AbilityMultiTarget_AllUnits native(Core);

defaultproperties
{
	bAcceptFriendlyUnits = true
}