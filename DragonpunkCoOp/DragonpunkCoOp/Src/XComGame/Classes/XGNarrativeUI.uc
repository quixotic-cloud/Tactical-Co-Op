class XGNarrativeUI extends XGTacticalScreenMgr;
// DEPRECATED - REMOVE ME
//
// This class has been deprecated and all Narrative moments should be using Final UI.
// Please use the Narrative() function in XGScreenMgr.uc to instance the Narrative moments.
//
// -sbatista

/*
enum EBriefingView
{
	eNarrativeView_Main
};

var TNarrativeMoment        m_kMoment;
var AudioComponent          Sound;

//------------------------------------------------------
//------------------------------------------------------
function Init( int iView )
{
	super.Init( iView );
}
//------------------------------------------------------
// Input Events
//------------------------------------------------------
//------------------------------------------------------
function OnFinishNarrative()
{
	Owner.owner.PopState();
}

//------------------------------------------------------
function UpdateView()
{

	switch( m_iCurrentView )
	{
	case eNarrativeView_Main:
		UpdateNarrative();
		break;
	}

	super.UpdateView();

	GetUIScreen().Narrative( m_kMoment );
}

//------------------------------------------------------
function UpdateNarrative()
{
}

/*
//------------------------------------------------------
simulated function OnReceiveFocus()
{
	if( !GetUIScreen().IsVisible() )
		GetUIScreen().Show();
	UpdateView();
}
//------------------------------------------------------
simulated function OnLoseFocus()
{
	GetUIScreen().Hide();
}*/


defaultproperties
{
}
*/
