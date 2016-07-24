//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeBlendMoveDirection extends AnimNodeBlendList
	native(Animation);

/** Allows control over how quickly the directional blend should be allowed to change. */
var()	float			DirDegreesPerSecond;

/** In radians. Between -PI and PI. 0.0 is running the way we are looking. */
var		float			DirAngle;

var vector 				MoveDir;

var bool                m_bLockDirection;
var bool                m_bPlayAnims;

native function EnableLockDirection(optional bool bResetAnims = false);
native function DisableLockDirection();
native function bool IsMoveStartStillPlaying(float fTimeFromEndToStopPlaying = 0.2f);
native function bool ValidateChildrenAsAnimNodeSequences();

cpptext
{
	virtual	void TickAnim( FLOAT DeltaSeconds );

	virtual INT GetNumSliders() const { return 1; }
	virtual FLOAT GetSliderPosition(INT SliderIndex, INT ValueIndex);
	virtual void HandleSliderMove(INT SliderIndex, INT ValueIndex, FLOAT NewSliderValue);
	virtual FString GetSliderDrawValue(INT SliderIndex);
}

defaultproperties
{
	Children(0)=(Name="Forward",Weight=1.0)
	Children(1)=(Name="Backward")
	Children(2)=(Name="Left")
	Children(3)=(Name="Right")
	Children(4)=(Name="Stationary")
	Children(5)=(Name="BackwardRight")
	bFixNumChildren=true

	DirDegreesPerSecond=360.0
	m_bLockDirection = false;
	m_bPlayAnims = false;
}
