//-----------------------------------------------------------
// FIRAXIS GAMES: Blend IK notify
//
// Allows blending of IK into/out of animations
//
// (c) 2008 Firaxis Games
//-----------------------------------------------------------
class AnimNotify_BlendIK extends AnimNotify
	native(Animation);

enum BlendIKType
{
	eBlendIKFootUp,
	eBlendIKFootDown,
	eBlendIKLeftHandOverrideOn,
	eBlendIKLeftHandOverrideOff,
	eBlendIKLeftHandOverrideDisable,
};

var() name IKControlName;
var() float fBlendTime;
var() float fBlendTarget;
var() BlendIKType eBlendType;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment();
}

defaultproperties
{

}
