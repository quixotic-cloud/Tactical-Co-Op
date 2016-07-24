//----------------------------------------------------------------------------
//  Copyright 2011, Firaxis Games
//
//  Manager for 2D HUD ui movie 
//

class UIMovie_2D extends UIMovie;


// Globally accessible (to anything that wants to make a message.)
var UIMessageMgr            MessageMgr;
var UIAnchoredMessageMgr    AnchoredMessageMgr; 
var UINarrativeCommLink     CommLink; 
var UIDialogueBox           DialogBox;

// Support for ForceShowUI
var bool bShownNormally;
var int  ForceShowCount;

//----------------------------------------------------------------------------
//  CALLBACK from Flash
//  Occurs when Flash sends an "OnInit" fscommand. 
//
simulated function OnInit()
{
	super.OnInit();

	MessageMgr = Pres.Spawn( class'UIMessageMgr', Pres );
	MessageMgr.InitScreen( XComPlayerController(Pres.Owner), self );
	LoadScreen(MessageMgr);

	AnchoredMessageMgr = Pres.Spawn( class'UIAnchoredMessageMgr', Pres );
	AnchoredMessageMgr.InitScreen( XComPlayerController(Pres.Owner), self );
	LoadScreen( AnchoredMessageMgr ); 

	CommLink = Pres.Spawn( class'UINarrativeCommLink', Pres );
	CommLink.InitScreen( XComPlayerController(Pres.Owner), self);
	LoadScreen( CommLink ); 

	DialogBox = Pres.Spawn( class'UIDialogueBox', Pres );
	DialogBox.InitScreen(XComPlayerController(Pres.Owner), self );	
	LoadScreen( DialogBox );

	Pres.OnMovieInitialized();
}

//----------------------------------------------------------------------------

// Turn on entire User Interface
simulated function Show()
{
	bShownNormally = true;

	super.Show(); 
	
	if (MessageMgr != none)
		MessageMgr.Show();

	if (AnchoredMessageMgr != none)
		AnchoredMessageMgr.Show();
}

// Turn off entire User Interface
simulated function Hide()
{
	bShownNormally = false;

	if( ForceShowCount == 0 )
	{
		super.Hide();
	
		// jboswell: these can be none when the UI is in a transition map
		if (MessageMgr != none)
			MessageMgr.Hide();

		if (AnchoredMessageMgr != none)
			AnchoredMessageMgr.Hide();

		if (CommLink != none)
			CommLink.Hide();

		if (Pres != none && Pres.m_kUIMouseCursor != None)
			Pres.m_kUIMouseCursor.HideMouseCursor();
	}
}

simulated function PushForceShowUI()
{
	ForceShowCount++;
	Show();
	bShownNormally = false;
}

simulated function PopForceShowUI()
{
	if( ForceShowCount > 0 )
	{
		ForceShowCount--;

		if( ForceShowCount == 0 && !bShownNormally )
			Hide();
	}
}

//----------------------------------------------------------------------------

defaultproperties
{
	ForceShowCount=0
}
