//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeCover extends AnimNodeBlendList
	native(Animation);

var bool bCanSwitchSides;
var bool bSwitchSidesBegun;
var bool bSwitchSidesLeftToRight;

// MHU - Utilize the below for full control over cover state handling.
var bool bProcessTickAnim; // <ToolTip="When enabled, this node will automatically activate the appropriate child nodes depending on the cover state. Disable if you want full control.">;

var() bool bCanUseOnlyLowCoverAnims<Tooltip="If checked this node will use low cover anims only if the unit has bAllowOnlyLowCoverAnims">;

enum EAnimCover
{
	eAnimCover_None,
 	eAnimCover_LowLeft,
	eAnimCover_LowRight,
	eAnimCover_HighLeft,
	eAnimCover_HighRight,
	eAnimCover_SwitchSidesLL2LR,
	eAnimCover_SwitchSidesHL2HR,
};

cpptext 
{
	virtual	void TickAnim( FLOAT DeltaSeconds );
}

DefaultProperties
{
	Children(eAnimCover_None)=(Name="No Cover")
	Children(eAnimCover_LowLeft)=(Name="Low Left")
	Children(eAnimCover_LowRight)=(Name="Low Right")
	Children(eAnimCover_HighLeft)=(Name="High Left")
	Children(eAnimCover_HighRight)=(Name="High Right")
	Children(eAnimCover_SwitchSidesLL2LR)=(Name="SwitchSides LL to LR (Optional)")
	Children(eAnimCover_SwitchSidesHL2HR)=(Name="SwitchSides HL to HR (Optional)")
	bFixNumChildren=true
	bPlayActiveChild=true

	bCanSwitchSides=false
	bSwitchSidesBegun=false
	bSwitchSidesLeftToRight=false
	bProcessTickAnim=true
	bCanUseOnlyLowCoverAnims=true
}
