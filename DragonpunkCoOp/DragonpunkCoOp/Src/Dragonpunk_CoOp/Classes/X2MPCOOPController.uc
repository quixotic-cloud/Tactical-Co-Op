// This is an Unreal Script
                           
Class X2MPCOOPController extends XComShellController;

var privatewrite bool               m_bIsClientTraveling;
var privatewrite bool               m_bSentReplicationInfoProperties;


simulated event PreBeginPlay()
{
	Super.PreBeginPlay();
}

simulated event Cleanup()
{
	super.Cleanup();
}

simulated function InitPres()
{
	local LocalPlayer kLocalPC;

	super.InitPres();

	if(!WorldInfo.IsConsoleBuild())
	{
		kLocalPC = LocalPlayer(Player);
		ServerChangeName(OnlineSub.PlayerInterface.GetPlayerNickname(kLocalPC.ControllerId));
	}
	else
	{
		kLocalPC = LocalPlayer(Player);
		if (kLocalPC != None &&
			OnlineSub.GameInterface != None &&
			OnlineSub.PlayerInterface != None)
		{
			// Check to see if they are logged in locally or not
			if (OnlineSub.PlayerInterface.GetLoginStatus(kLocalPC.ControllerId) == LS_LoggedIn &&
				OnlineSub.GameInterface.GetGameSettings('Game') != None)
			{
				// Ignore what ever was specified and use the profile's nick
				ServerChangeName(OnlineSub.PlayerInterface.GetPlayerNickname(kLocalPC.ControllerId));
			}
		}
	}
}
simulated event ReceivedPlayer()
{
	super.ReceivedPlayer();
}

event PreClientTravel( string PendingURL, ETravelType TravelType, bool bIsSeamlessTravel )
{
	super.PreClientTravel(PendingURL, TravelType, bIsSeamlessTravel);
	`log(`location @ "StartMPLoadTimeout", true, 'XCom_Online');
	`ONLINEEVENTMGR.StartMPLoadTimeout();
	m_bIsClientTraveling = true;
	// we are traveling to the map, need to keep the longer timeout -tsmith 
	if(bShortConnectTimeOut)
	{
		bShortConnectTimeOut = false;
		ServerShortTimeout(false);
	}
}

event PlayerTick( float DeltaTime )
{

	if(m_bIsClientTraveling)
	{
		// we are traveling to the map, need to keep the longer timeout -tsmith 
		if(bShortConnectTimeOut)
		{
			bShortConnectTimeOut = false;
			ServerShortTimeout(false);
		}

	}
	if ( Pawn != AcknowledgedPawn )
	{
		if ( Role < ROLE_Authority )
		{
			// make sure old pawn controller is right
			if ( (AcknowledgedPawn != None) && (AcknowledgedPawn.Controller == self) )
				AcknowledgedPawn.Controller = None;
		}
		AcknowledgePossession(Pawn);
	}

	PlayerInput.PlayerInput(DeltaTime);
	if ( bUpdatePosition )
	{
		ClientUpdatePosition();
	}
	PlayerMove(DeltaTime);

	AdjustFOV(DeltaTime);

	// If XCOM again has focus after ALT+Pause away, this ensures input can again
	// be utilized.
	if( m_fAltTabTime > 0 )
	{
		m_fAltTabTime -= DeltaTime;
		if( m_fAltTabTime <= 0 )
		{
			m_fAltTabTime = 0;
		}
	}
}

function bool IsInLobby()
{
	return true;
}

simulated event Destroyed()
{
	super.Destroyed();
}

defaultproperties
{
	CheatClass=class'XComGame.X2MPLobbyCheatManager'
	PresentationLayerClass=class'Dragonpunk_CoOp.X2MPCOOPPresentationLayer'
	InputClass=class'XComGame.X2MPLobbyInput'
}