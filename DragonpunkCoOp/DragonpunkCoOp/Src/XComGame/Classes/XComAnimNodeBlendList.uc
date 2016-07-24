//-----------------------------------------------------------
// MHU - Used to update mirroring status. When returning from
//       ConstantCombat, we need to reset mirroring when
//       a non-mirrored anim is ready for playback. This is why
//       the check and mirror reset is done here.
//-----------------------------------------------------------
class XComAnimNodeBlendList extends AnimNodeBlendList
	abstract
	native(Animation);

/*
// MHU - Use this to debug animation issues.
function Debugging(int newchildindex)
{
	local int Check;
	local int EnumInt;
	
	if( IsA('XComAnimNodeBlendByMovementType') )
	{
		EnumInt = eMoveType_Action;
		if( newchildindex != EnumInt )
		{
			Check = 0;
		}
	}
}*/

function SetActiveChild(int ChildIndex, FLOAT BlendTime)
{
	local AnimNodeSequence LocalSequence;
//	Debugging(ChildIndex);
	LocalSequence = AnimNodeSequence(Children[ChildIndex].Anim);
	if( ChildIndex != ActiveChildIndex || (LocalSequence != none && !LocalSequence.bPlaying) )
	{
		super.SetActiveChild(ChildIndex, BlendTime);
	}
}

DefaultProperties
{
	bFixNumChildren=true
	bPlayActiveChild=true
}
