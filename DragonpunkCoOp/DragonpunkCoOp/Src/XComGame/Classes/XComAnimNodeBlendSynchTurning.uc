//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeBlendSynchTurning extends AnimNodeBlendList
	native(Animation);

enum ESynchTurnChild
{
 	eSynchTurn_Left45,
	eSynchTurn_Left90,
	eSynchTurn_Left180,
	eSynchTurn_Right180,
	eSynchTurn_Right90,
	eSynchTurn_Right45,
	eSynchTurn_NotTurning // For playing a just a simple animation sequence
};

var bool m_bIsTurnZeroValid;
var float m_fPreviousTargetDirAngle;

// Start Turning towards Focal Point
native function StartTurning();

// Query whether finished turning to focal point
native function bool FinishedTurning();

// Force Stop Turning, regardless of current facing
native function StopTurning(optional bool bSetRotationToFocalPoint = true);

cpptext
{
	virtual	void TickAnim( FLOAT DeltaSeconds );
	virtual void InitAnim( USkeletalMeshComponent* meshComp, UAnimNodeBlendBase* Parent );

	virtual INT GetNumSliders() const { return 1; }
	virtual FLOAT GetSliderPosition(INT SliderIndex, INT ValueIndex);
	virtual void HandleSliderMove(INT SliderIndex, INT ValueIndex, FLOAT NewSliderValue);
	virtual FString GetSliderDrawValue(INT SliderIndex);
}

defaultproperties
{
	Children(0)=(Name="Left 45")
	Children(1)=(Name="Left 90")
	Children(2)=(Name="Left 180")
	Children(3)=(Name="Right 180")
	Children(4)=(Name="Right 90")
	Children(5)=(Name="Right 45")
	Children(6)=(Name="Not Turning")
}
