class XComAutoTestManager extends AutoTestManager;

var XComTacticalController TacticalController;

var int iSecondsRemaining;
var int iNextMapIndex;
var bool bPlayGame;
//var bool bStressTestReactionFire;

// PlayGame specific vars
var Vector TargetLoc;
// End PlayGame specific vars

var private transient int iRand; // used to store random rolls
var private transient int iCnt, iDPadPresses; // used to fake d-pad inputs for abilities

/**
  * Base AutoTestManager timer ticks once per second
  * Checks if perf test timer has run out
  */
event Timer()
{

		if (iNextMapIndex == 0 && iSecondsRemaining > 10)
		{
			iSecondsRemaining = 5;
			iNextMapIndex = 2; // Hack in to start on map 1, cuz I said so
		}

		iSecondsRemaining--;
		if( iSecondsRemaining <= 0 )
		{			
			ClearAllTimers();
			GotoNextMap();			
		}
}

function RequestUnitContent(const out XComMapMetaData MapData)
{
	`CONTENT.RequestContent();
}

function GotoNextMap()
{
	local array<string> arrMapList;
	local string strCmdLine;
	local XComMapMetaData MapData;

	`MAPS.GetMapDisplayNames(eMission_All, arrMapList, true, false);

	if (iNextMapIndex < arrMapList.Length)
	{
		`MAPS.GetMapInfoFromDisplayName(arrMapList[iNextMapIndex], MapData);

		`log( "XComAutoTestManager: Opening Map "@iNextMapIndex@","@arrMapList[iNextMapIndex] );
		strCmdLine = "open";
		strCmdLine = strCmdLine@MapData.Name;
		strCmdLine = strCmdLine$"?game=XComGame.XComTacticalGame";
		strCmdLine = strCmdLine$"?AutoTests=1";
		strCmdLine = strCmdLine$"?MapIndex="$iNextMapIndex;
		RequestUnitContent(MapData);
		ConsoleCommand( strCmdLine );
	}
	else
	{
		`log( "XComAutoTestManager: COMPLETED!!!!!!!" );
		ConsoleCommand( "exit" );
	}

}

function InitializeOptions(string Options)
{

	AutomatedPerfRemainingTime = 60 * WorldInfo.Game.TimeLimit;

	iNextMapIndex = int(WorldInfo.Game.ParseOption( Options, "MapIndex" ));
	iNextMapIndex++;

	//if (bStressTestReactionFire)
	//	`CHEATMGR.AIAbilityForceEnable( "eAbility_Overwatch");
}

function StartMatch()
{
	foreach WorldInfo.AllControllers(class'XComTacticalController', TacticalController)
	{
		TacticalController.IncrementNumberOfMatchesPlayed();
		if (bPlayGame)
		{
			XComInputBase(TacticalController.PlayerInput).bAutoTest=true;
			GotoState('PlayGame');
			//MoveCursor();
		}
		break;
	}
}

function MoveCursor()
{
	XComInputBase(TacticalController.PlayerInput).fAutoBaseY = 0.0f;
	XComInputBase(TacticalController.PlayerInput).fAutoStrafe = 0.9f;
}

function vector GetClosestEnemyLocation()
{
	local XGUnit kNearestEnemy;
	local float outClosestDist;

	kNearestEnemy = XGBattle_SP(`BATTLE).GetHumanPlayer().GetNearestEnemy(XGBattle_SP(`BATTLE).GetHumanPlayer().GetActiveUnit().Location, outClosestDist);
	
	return kNearestEnemy.Location;
}

function vector GetCloseShieldLocation(vector vLoc)
{
	local XComCoverPoint kCover;

	`XWORLD.GetClosestCoverPoint(vLoc +VRand()*300, 960, kCover, true);

	return kCover.ShieldLocation;
}

function ClearInput()
{
	XComInputBase(TacticalController.PlayerInput).fAutoBaseY = 0;
	XComInputBase(TacticalController.PlayerInput).fAutoStrafe = 0;
}

function bool BattleOver()
{
	return false;
}

state PlayGame
{
	event Tick(float DeltaTime)
	{
	}

	function MoveCursorToLoc(Vector vLoc)
	{

	}


Begin:
	Sleep(10);

	while (!BattleOver())
	{
		while ( XGBattle_SP(`BATTLE).TurnIsComplete())
		{
			Sleep(1);
		}

		iRand = Rand(100);

		if (XGBattle_SP(`BATTLE).GetHumanPlayer().GetActiveUnit() != none && 
			XGBattle_SP(`BATTLE).GetHumanPlayer().GetActiveUnit().IsPanicked())
		{
			TacticalController.Back_Button_Press();
			TacticalController.Back_Button_Release();
		}

		if (iRand > 50) // Move
		{
			TargetLoc = GetClosestEnemyLocation();
			TargetLoc = GetCloseShieldLocation(TargetLoc);
			PushState('MoveCursorToTarget');
			PushState('MoveUnit');
		}
		else // Use ability
		{
			PushState('UseAbility');
			Sleep(2);
		}
	}

	Sleep(10);
	ClearAllTimers();
	GotoNextMap();

}

state MoveUnit
{
	event Tick(float DeltaTime)
	{
		if (BattleOver())
			PopState();
	}
Begin:
	TacticalController.A_Button_Press();
	TacticalController.A_Button_Release();
	Sleep(5);
	PopState();
}

state UseAbility
{
	event Tick(float DeltaTime)
	{
		if (BattleOver())
			PopState();
	}

Begin:

	//if (bStressTestReactionFire)
	//{
	//	TacticalController.Y_Button_Press();
	//	Sleep(0.1);
	//	TacticalController.Y_Button_Release();
	//	goto 'Done';
	//}

	TacticalController.Trigger_Right_Press();
	Sleep(0.1);
	TacticalController.Trigger_Right_Release();
	Sleep(1);

	iDPadPresses = Rand(10);

	//@TODO - rmcfall - XGUNIT VISIBILITY REFACTOR
	/*
	// If we have a visible enemy, we'll choose ability 0 50% of the time (0 DPadPresses);
	if (XGBattle_SP(`BATTLE).GetHumanPlayer().GetActiveUnit().m_arrVisibleEnemies.Length > 0)
	{
		if (Rand(100) > 50)
		{
			iDPadPresses = 0;
		}
	}
	*/

	for (iCnt = 0; iCnt < iDPadPresses; iCnt++)
	{
		TacticalController.DPad_Right_Press();
		Sleep(0.1);
		TacticalController.DPad_Right_Release();
		Sleep(0.25);
	}

	TacticalController.A_Button_Press();
	TacticalController.A_Button_Release();

	Sleep(1.0f);
Done:
	PopState();	
}

state MoveCursorToTarget
{
	event Tick(float DeltaTime)
	{
		local Vector X;
		local Vector Y;
		local Vector Z;

		local Vector vDelta;

		local float fScalar;

		vDelta = TargetLoc - TacticalController.GetCursor().Location;

		if (VSize2D(vDelta) < 8)
		{
			ClearInput();
			PopState();
		}
		else
		{
			GetAxes(XComCamera(TacticalController.PlayerCamera).GetCameraRotation(),X,Y,Z);

			XComInputBase(TacticalController.PlayerInput).fAutoBaseY = NoZDot(X, vDelta);
			XComInputBase(TacticalController.PlayerInput).fAutoStrafe = NoZDot(Y, vDelta);

			fScalar = abs(VSize2D(vDelta)) / 100;
			fScalar = FMin(fScalar, 1.0f);

			fScalar = fScalar*(0.03f/WorldInfo.DeltaSeconds); // Compensate for framerate

			XComInputBase(TacticalController.PlayerInput).fAutoBaseY *= 0.10f*fScalar;
			XComInputBase(TacticalController.PlayerInput).fAutoStrafe *= 0.10f*fScalar;
		}

		if (BattleOver())
			PopState();
	}
}


defaultproperties
{
	iSecondsRemaining=600
	iNextMapIndex=0
	bPlayGame=true
	//bStressTestReactionFire=true;
}
