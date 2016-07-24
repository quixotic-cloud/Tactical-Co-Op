//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComGameState_DropShipTipStore extends XComGameState_BaseObject;

struct TipsSeen
{
	var array<int> Tips;
};

var array<TipsSeen> AllTipsSeen;


DefaultProperties
{
	AllTipsSeen[eTip_Tactical] = ()
	AllTipsSeen[eTip_Strategy] = ()
}