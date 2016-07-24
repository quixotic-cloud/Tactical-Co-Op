//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeBlendTurning extends AnimNodeBlendList
	native(Animation);


// Start Turning towards Focal Point
native function StartTurning();

// Query whether finished turning to focal point
native function bool FinishedTurning();

// Force Stop Turning, regardless of current facing
native function StopTurning();

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
}
