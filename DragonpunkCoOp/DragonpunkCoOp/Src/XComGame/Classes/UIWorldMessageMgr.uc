//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWorldMessageMgr
//  AUTHOR:  Brit Steiner, Tronster
//  PURPOSE: Controls 2d message box that act in 3d "world" space.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIWorldMessageMgr extends UIMessageMgrBase;

enum EHUDMessageType
{
	eHUDMessage_World,
	eHUDMessage_Damage,
	eHUDMessage_Blade,
};

// OPTIMIZATION
const NUM_INITIAL_INACTIVE_MESSAGES                     = 8;

// GENERAL MESSAGE BEHAVIOR
const FXS_MSG_BEHAVIOR_FLOAT                            = 0;
const FXS_MSG_BEHAVIOR_STEADY                           = 1;
const FXS_MSG_BEHAVIOR_READY							= 2;

// QUASI CONSTANTS
var const string        DAMAGE_DISPLAY_DEFAULT_ID;
var const bool          DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM;
var const Vector2D      DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC;
var const float         DAMAGE_DISPLAY_DEFAULT_DISPLAY_TIME;

var XComGameStateHistory History; 

struct THUDMsg
{
	var string              m_sId;
	var string              m_txtMsg;
	var int                 m_eColor;
	var Vector              m_vLocation;
	var StateObjectReference m_kFollowObject;
	var bool                m_bFollowWorldLocation; //Specifies that m_vLocation is world and mmust be translated to screen space 
	var bool                m_bVisible;
	var bool                m_bIsImportantMessage; // Lets us keep track of messages that are important and shouldn't be pooled to be reused once deactivated.
	var int                 m_eBehavior;
	var float               m_fVertDiff; // push a message up vertically, if it overlaps an earlier message at same location
	var float               m_fDisplayTime;
	var bool                m_bIsArmor;

	var string				m_sIconPath;		// Dynamically loading path 
	var int					m_iDamagePrimary;	// Will trigger using a damage-style message 
	var int					m_iDamageModified;	// Optional, will trigger modifier animation and display value updates
	var int                 m_iDamageType;      
	var string              m_sCritLabel;       // Optional, if not empty, the message will style crit yellow 

	var EHUDMessageType		m_eType;
	structdefaultproperties
	{
		m_sIconPath = ""; 
		m_iDamagePrimary = 0;
		m_iDamageModified = 0;
		m_sCritLabel = "";
		m_eType = eHUDMessage_World;
	}
};

struct TFlashMsg
{
	var string          m_sFlashFunctionCall;
	var array<ASValue>  m_arrMessageValues;
};

var float m_fVertDiff;

var Array<TFlashMsg> m_arrQueuedMessages;
var float            m_fMessageDelay;
var bool             m_bDelayMessages;

var array<THUDMsg> m_arrMsgs;
// OPT: Keep track of indicies into the above array for the messages that need to be updated.
var array<int> m_arrActiveMessages;
// OPT: Keep track of indicies of messages not currently being used, so they can be reused.
var array<int> m_arrInactiveMessages;

// Used for the anchored version of the tutorial blade message. 
var UIPanel BladeHUDMessage;

// If true, hides the blade when we enter the shot hud
var bool HideBladeMessageInShotHud;

//==============================================================================
// 		GENERAL FUNCTIONS:
//==============================================================================

simulated function OnInit()
{
	local int i;
	local THUDMsg kMsg;

	super.OnInit();	
	History = `XCOMHISTORY; 

	Show();

	// Set the visible flag to false, so we can distinguish between
	kMsg.m_bVisible = false;

	// Create a cache of messages to be used by the game
	for(i = 0; i < NUM_INITIAL_INACTIVE_MESSAGES; ++i)
	{
		kMsg.m_sId = "worldMessageBox" $ m_arrMsgs.Length;
		CreateNewMessage(kMsg);
	}
}

// Callback from Flash
simulated function OnCommand(string cmd, string arg)
{
	local int i;

	if (cmd == "DeactivateMessage")
	{
		if(arg != "")
			DeactivateMessage( int(arg) );
		else
			`warn("UIWorldMessageMgr - DeactivateMessage called without a valid argument. CATASTROPHIC ERROR");
	}
	else if(cmd == "InitialItemsLoaded")
	{
		// Add all messages that were initially marked as invisible to the inactive messages list - messages added during initialization.
		for(i = 0; i < m_arrMsgs.Length; ++i)
		{
			m_arrInactiveMessages.AddItem(i);
		}

		GotoState('Active');
	}
	else
		`warn("Unhandled fscommand '" $ cmd $ "," $ arg $ "' sent to '" $ MCPath $ "'.",,'uicore' );
}

// Creates a 2d message that tracks in 3d space.
// Passing [ < 0 ] for the display time will make message stay on-screen until "RemoveMessage" is called.
simulated function XComUIBroadcastWorldMessage Message( 
							string                  _sMsg, 
							vector                  _vLocation,
							optional StateObjectReference _TargetObject,
							optional int            _eColor = eColor_Xcom,
							optional int            _eBehavior = FXS_MSG_BEHAVIOR_FLOAT,
							optional string         _sId = "",
							optional ETeam          _eBroadcastToTeams = eTeam_None,
							optional bool           _bUseScreenLocationParam = false,
							optional Vector2D       _vScreenLocationParam,
							optional float          _displayTime = 5.0,
							optional class<XComUIBroadcastWorldMessage> _cBroadcastMessageClass = none,
							optional string			_sIcon = class'UIUtilities_Image'.const.UnitStatus_Default,
							optional int			_iDamagePrimary = 0,
							optional int			_iDamageModified = 0,
							optional string			_sCritLabel = "", 
							optional EHUDMessageType _eType = eHUDMessage_World,
							optional int 	        _damageType = -1)
{
	local THUDMsg kMsg;
	local int i, j, iNumVerticalOffsets, reuseIndex;
	local bool bDisplayMessage, bBroadcastMessage;
	local int ibDisplayMessage, ibBroadcastMessage;
	local XComUIBroadcastWorldMessage kBroadcastWorldMessage;
	local X2VisualizerInterface VisualizedObject;

	if( !bIsInited && m_arrMsgs.Length == 0 ) 
		return none; 

	if (XComTacticalCheatManager(`XCOMGRI.GetALocalPlayerController().CheatManager) != none && 
		XComTacticalCheatManager(`XCOMGRI.GetALocalPlayerController().CheatManager).bDisableWorldMessages) 
		return none;

	ShouldDisplayAndBroadcastMessage(
		ibDisplayMessage, 
		ibBroadcastMessage, 
		_eBroadcastToTeams, 
		`ShowVar(_sMsg) @ `ShowVar(_vLocation) @ `ShowVar(_sId) @ `ShowVar(_eColor) @ `ShowVar(_eBehavior) @ `ShowVar(_eBroadcastToTeams));

	// unrealscript is teh suck and doesn't allow 'out bool' parameters to function hence the int hacks -tsmith 
	bDisplayMessage = ibDisplayMessage > 0;
	bBroadcastMessage = ibBroadcastMessage > 0;

	// Forcibly use the default icon, because there should never be no icon at all. 
	if( _sIcon == "" )
		_sIcon = class'UIUtilities_Image'.const.UnitStatus_Default;

	if(bDisplayMessage)
	{
		// Is message referencing an already existing message? (aka, is this a Gameplay Managed message / Important message?)
		i = m_arrMsgs.Find('m_sId', _sId);
		if( i  > -1 )
		{
			kMsg = m_arrMsgs[i];
			kMsg.m_vLocation = _vLocation;

			VisualizedObject = X2VisualizerInterface( History.GetVisualizer(_TargetObject.ObjectID) );
			if( VisualizedObject != none )
			{
				kMsg.m_kFollowObject = _TargetObject;
				kMsg.m_vLocation = VisualizedObject.GetUnitFlagLocation();
			}
			else if( _TargetObject.ObjectID > 0 )
			{
				`Redscreen("You passed in an object to the UIWorldMessageManager, but it's not a valid X2VisualizerInterface. This message will not follow your object as intended."); 
			}
			else if( _bUseScreenLocationParam )
			{
				kMsg.m_vLocation.X += _vScreenLocationParam.X * class'UIMovie'.default.UI_RES_X;
				kMsg.m_vLocation.Y += _vScreenLocationParam.Y * class'UIMovie'.default.UI_RES_Y;
			}
			else
			{
				// No target actor specified, but the vector is not screen location, so it must be a world location. Translate the location out to screenspace. 
				kMsg.m_bFollowWorldLocation = true; 
			}

			// Add the message to be updated during the Tick (do not duplicate entries).
			if(m_arrActiveMessages.Find(i) < 0)
				m_arrActiveMessages.AddItem(i);
			
			// Only update the message contents if they change
			if( kMsg.m_txtMsg != _sMsg ||
				kMsg.m_eColor != _eColor ||
				//kMsg.m_fDisplayTime != _displayTime || // No need to compare, almost always a constant
				kMsg.m_eBehavior != _eBehavior ||
				kMsg.m_sIconPath != _sIcon ||
				kMsg.m_iDamagePrimary != _iDamagePrimary || 
				kMsg.m_iDamageModified != _iDamageModified ||
				kMsg.m_sCritLabel != _sCritLabel ||
				kMsg.m_iDamageType != _damageType)
			{
				kMsg.m_txtMsg = _sMsg;
				kMsg.m_eColor = _eColor;
				kMsg.m_fDisplayTime = _displayTime;
				kMsg.m_eBehavior = _eBehavior;
				kMsg.m_sIconPath = _sIcon;
				kMsg.m_iDamagePrimary = _iDamagePrimary;
				kMsg.m_iDamageModified = _iDamageModified;
				kMsg.m_sCritLabel = _sCritLabel;
				kMsg.m_iDamageType = _damageType;

				UpdateExistingMessageContents(kMsg);
			}

			// Forcing visibility to false in order to update Sync up Flash's data with our data.
			// This should only occur for important messages, those that have "m_bIsImportantMessage" set to true.
			if(!kMsg.m_bIsImportantMessage)
				`warn("UI ERROR: Forcing a non important message to refresh it's visibility data. This is bad for perf, please let UI team know if you see this.");

			kMsg.m_bVisible = false;
			m_arrMsgs[i] = kMsg;

			// Leave actual update to the update loop.
			return none;
		}

		// CREATE A NEW MESSAGE
		
		// Set Message Data
		kMsg.m_txtMsg = _sMsg;
		kMsg.m_eColor = _eColor;
		kMsg.m_vLocation = _vLocation;
		kMsg.m_fDisplayTime = _displayTime;
		kMsg.m_eBehavior = _eBehavior;
		kMsg.m_bVisible = false;
		kMsg.m_sIconPath = _sIcon;
		kMsg.m_iDamagePrimary = _iDamagePrimary;
		kMsg.m_iDamageModified = _iDamageModified;
		kMsg.m_sCritLabel = _sCritLabel;
		kMsg.m_iDamageType = _damageType;

		if( kMsg.m_iDamagePrimary > 0 ) // Only needs to be set initially. 
			kMsg.m_eType = eHUDMessage_Damage;
		else
			kMsg.m_eType = EHUDMessageType(_eType); 

		VisualizedObject = X2VisualizerInterface( History.GetVisualizer(_TargetObject.ObjectID) );
		if( VisualizedObject != none )
		{
			kMsg.m_kFollowObject = _TargetObject;
			kMsg.m_vLocation = VisualizedObject.GetUnitFlagLocation();
		}
		else if( _TargetObject.ObjectID > 0 )
		{
			`Redscreen("You passed in an object to the UIWorldMessageManager, but it's not a valid X2VisualizerInterface. This message will not follow your object as intended.");
		}

		if( _bUseScreenLocationParam ) 
		{
			kMsg.m_vLocation.X += _vScreenLocationParam.X * class'UIMovie'.default.UI_RES_X;
			kMsg.m_vLocation.Y += _vScreenLocationParam.Y * class'UIMovie'.default.UI_RES_Y;
		}
		else if(VisualizedObject == none) 
		{
			// No target actor specified, but the vector is not screen location, so it must be a world location. Translate the location out to screenspace. 
			kMsg.m_bFollowWorldLocation = true; 
		}

		//If other messages are tagged to the same location, add a vertical offset, so they don't ovelap. 
		if( !kMsg.m_bFollowWorldLocation )
		{
			iNumVerticalOffsets = 0;
			for( i = 0; i < m_arrActiveMessages.Length; i++)
			{
				if( m_arrMsgs[m_arrActiveMessages[i]].m_vLocation == kMsg.m_vLocation
					|| VSizeSq(m_arrMsgs[m_arrActiveMessages[i]].m_vLocation - kMsg.m_vLocation) < Square(64) ) 
					iNumVerticalOffsets++;
			}
			kMsg.m_fVertDiff = m_fVertDiff * iNumVerticalOffsets;
		}

		// If an ID is not specifically required (they don't want to keep track of the message)
		if( _sId == "")
		{
			reuseIndex = -1;
			for( j = 0; j < m_arrInactiveMessages.Length; j++ )
			{
				//We only want to reuse the same type of message, so that we don't have to create and 
				//destroy these messages on the flash side. 
				if( m_arrMsgs[m_arrInactiveMessages[j]].m_eType == kMsg.m_eType )
				{
					reuseIndex = j; 
					break; // we have our index
				}
			}
			// Check if we can reuse an existing inactive message
			if(m_arrInactiveMessages.Length > 0 && reuseIndex > -1)
			{
				// Get the index into the 'm_arrMsgs' array, remove index from inactive messages array
				i = m_arrInactiveMessages[reuseIndex];
				m_arrInactiveMessages.Remove(reuseIndex, 1); 

				// Copy the message ID, necessary to access the message box in Flash
				kMsg.m_sId = m_arrMsgs[i].m_sId;

				// Update the stored message data.
				m_arrMsgs[i] = kMsg;

				// Update the Message Box in Flash
				UpdateExistingMessageContents(kMsg);
			}
			else
			{
				// Did not find an inactive message to update, generate a new one. 
				kMsg.m_sId = "worldMessageBox" $ m_arrMsgs.Length;
				
				// Create the message
				CreateNewMessage(kMsg);
				// Store the index to add to the active messages array
				i = m_arrMsgs.Length - 1;
			}
		}
		else
		{
			kMsg.m_sId = _sId;

			// When the game passes in an ID, it means they want to keep track of it and want to manipulate it after it's created.
			// This boolean prevents the message from being pooled and recycled once it dissappears.
			kMsg.m_bIsImportantMessage = true;

			// Create the message
			CreateNewMessage(kMsg);
			// Store the index to add to the active messages array
			i = m_arrMsgs.Length - 1;
		}

		m_arrActiveMessages.AddItem(i);
	}
	if(bBroadcastMessage)
	{
		kBroadcastWorldMessage = Spawn((_cBroadcastMessageClass != none ? _cBroadcastMessageClass : class'XComUIBroadcastWorldMessage'),,,,,,, _eBroadcastToTeams);
		kBroadcastWorldMessage.Init(_vLocation, _TargetObject, _sMsg, _eColor, _eBehavior, _bUseScreenLocationParam, _vScreenLocationParam, _displayTime, _eBroadcastToTeams, _sIcon, _iDamagePrimary, _iDamageModified, _sCritLabel, _damageType);
	}

	return kBroadcastWorldMessage;
}

simulated function CreateNewMessage(out THUDMsg kMsg)
{
	if( m_arrMsgs.Find('m_sId', kMsg.m_sId) > -1 )
	{
		`log( "Problem in the UIWorldMessageMgr: trying to CREATE new message (id=" $kMsg.m_sId $"), but that id already exists in the tracking array.", , 'uixcom');
		return;
	}

	if( kMsg.m_eType == eHUDMessage_Damage )
		CreateNewDamageMessage(kMsg);
	else if( kMsg.m_eType == eHUDMessage_Blade )
		CreateNewBladeMessage(kMsg);
	else
		CreateNewWorldMessage(kMsg);
}

simulated function CreateNewDamageMessage(out THUDMsg kMsg)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local TFlashMsg myMessage;
	
	// Store the message data
	m_arrMsgs.AddItem(kMsg);

	//worldMessageIndex - for faster message deactivation
	myValue.Type = AS_Number;
	myValue.n = m_arrMsgs.Length - 1;
	myArray.AddItem(myValue);

	//MC Name
	myValue.Type = AS_String;
	myValue.s = kMsg.m_sId;
	myArray.AddItem(myValue);

	//Display string 
	if( kMsg.m_txtMsg == "" || kMsg.m_eColor == eColor_Xcom )
		myValue.s = kMsg.m_txtMsg;
	else
		myValue.s = class'UIUtilities_Colors'.static.ColorString(kMsg.m_txtMsg, class'UIUtilities_Colors'.static.CreateColor(kMsg.m_eColor));
	myArray.AddItem(myValue);

	//X loc
	myValue.Type = AS_Number;
	myValue.n = -5000; // Create it off-screen, repositioned when UpdateMessages gets called
	myArray.AddItem(myValue);

	//Y loc
	myValue.Type = AS_Number;
	myValue.n = -5000; // Create it off-screen, repositioned when UpdateMessages gets called
	myArray.AddItem(myValue);

	//Display Time
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_fDisplayTime;
	myArray.AddItem(myValue);

	// How animation behaves.
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_eBehavior;
	myArray.AddItem(myValue);

	// damage 1 
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_iDamagePrimary;
	myArray.AddItem(myValue);

	// damage 2
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_iDamageModified;
	myArray.AddItem(myValue);

	// Crit
	myValue.Type = AS_String;
	myValue.s = kMsg.m_sCritLabel;
	myArray.AddItem(myValue);

	myValue.Type = AS_Number;
	myValue.n = kMsg.m_iDamageType;
	myArray.AddItem(myValue);

	myMessage.m_arrMessageValues = myArray;
	myMessage.m_sFlashFunctionCall = "CreateDamageMessageBox";
	m_arrQueuedMessages.AddItem(myMessage);

	if(m_bDelayMessages)
	{
		if(!IsTimerActive('DisplayMessageBox'))
		{
			SetTimer(m_fMessageDelay, true, 'DisplayMessageBox');
		}
	}
	else
	{
		DisplayMessageBox();
	}
	//Invoke("CreateDamageMessageBox", myArray);
}

simulated function DisplayMessageBox()
{
	local string FlashFunction;
	local Array<ASValue> MessageValues;
	FlashFunction = m_arrQueuedMessages[0].m_sFlashFunctionCall;
	MessageValues = m_arrQueuedMessages[0].m_arrMessageValues;
	
	Invoke(FlashFunction, MessageValues);
	m_arrQueuedMessages.Remove(0, 1);

	if(!m_bDelayMessages || m_arrQueuedMessages.Length <= 0)
	{
		ClearTimer('DisplayMessageBox');
	}
}

simulated function CreateNewWorldMessage(out THUDMsg kMsg)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local TFlashMsg myMessage;

	// Store the message data
	m_arrMsgs.AddItem(kMsg);

	//worldMessageIndex - for faster message deactivation
	myValue.Type = AS_Number;
	myValue.n = m_arrMsgs.Length - 1;
	myArray.AddItem(myValue);

	//MC Name
	myValue.Type = AS_String;
	myValue.s = kMsg.m_sId;
	myArray.AddItem(myValue);

	//Display string 
	if( kMsg.m_txtMsg == "" )
		myValue.s = kMsg.m_txtMsg;
	else
		myValue.s = class'UIUtilities_Colors'.static.ColorString(kMsg.m_txtMsg, class'UIUtilities_Colors'.static.CreateColor(kMsg.m_eColor));
	myArray.AddItem(myValue);

	//X loc
	myValue.Type = AS_Number;
	myValue.n = -5000; // Create it off-screen, repositioned when UpdateMessages gets called
	myArray.AddItem(myValue);

	//Y loc
	myValue.Type = AS_Number;
	myValue.n = -5000; // Create it off-screen, repositioned when UpdateMessages gets called
	myArray.AddItem(myValue);

	//Display Time
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_fDisplayTime;
	myArray.AddItem(myValue);

	// How animation behaves.
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_eBehavior;
	myArray.AddItem(myValue);

	// Image 
	myValue.Type = AS_String;
	myValue.s = kMsg.m_sIconPath;
	myArray.AddItem(myValue);

	// color 
	myValue.Type = AS_String;
	myValue.s = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(EWidgetColor(kMsg.m_eColor));
	myArray.AddItem(myValue);

	myMessage.m_arrMessageValues = myArray;
	myMessage.m_sFlashFunctionCall = "CreateWorldMessageBox";
	m_arrQueuedMessages.AddItem(myMessage);

	if(m_bDelayMessages)
	{
		if(!IsTimerActive('DisplayMessageBox'))
		{
			SetTimer(m_fMessageDelay, true, 'DisplayMessageBox');
		}
	}
	else
	{
		DisplayMessageBox();
	}

	//Invoke("CreateWorldMessageBox", myArray);

}

simulated function CreateNewBladeMessage(out THUDMsg kMsg)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local TFlashMsg myMessage;

	// Store the message data
	m_arrMsgs.AddItem( kMsg );

	//worldMessageIndex - for faster message deactivation
	myValue.Type = AS_Number;
	myValue.n = m_arrMsgs.Length - 1;
	myArray.AddItem( myValue );

	//MC Name
	myValue.Type = AS_String;
	myValue.s = kMsg.m_sId;
	myArray.AddItem( myValue );

	//Display string 
	if( kMsg.m_txtMsg == "" || kMsg.m_eColor == eColor_Xcom )
		myValue.s = kMsg.m_txtMsg;
	else
		myValue.s = class'UIUtilities_Colors'.static.ColorString(kMsg.m_txtMsg, class'UIUtilities_Colors'.static.CreateColor(kMsg.m_eColor));
	myArray.AddItem( myValue );
	
	//X loc
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_vLocation.X; 
	myArray.AddItem( myValue );
	
	//Y loc
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_vLocation.Y;
	myArray.AddItem( myValue );

	//should resize? 
	myValue.Type = AS_Boolean;
	myValue.b = kMsg.m_bFollowWorldLocation;
	myArray.AddItem(myValue);

	myMessage.m_arrMessageValues = myArray;
	myMessage.m_sFlashFunctionCall = "CreateBladeMessageBox";
	m_arrQueuedMessages.AddItem(myMessage);

	if(m_bDelayMessages)
	{
		if(!IsTimerActive('DisplayMessageBox'))
		{
			SetTimer(m_fMessageDelay, true, 'DisplayMessageBox');
		}
	}
	else
	{
		DisplayMessageBox();
	}

	//Invoke("CreateBladeMessageBox", myArray);
}

simulated function UpdateExistingMessageContents(out THUDMsg kMsg)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local TFlashMsg myMessage;

	//MC Name
	myValue.Type = AS_String;
	myValue.s = kMsg.m_sId;
	myArray.AddItem( myValue );

	//Display string 
	if( kMsg.m_txtMsg == "" )
		myValue.s = kMsg.m_txtMsg;
	else
		myValue.s = class'UIUtilities_Colors'.static.ColorString(kMsg.m_txtMsg, class'UIUtilities_Colors'.static.CreateColor(kMsg.m_eColor));
	myArray.AddItem( myValue );
	
	//X loc
	myValue.Type = AS_Number;
	myValue.n = -5000; // Create it off-screen, repositioned when UpdateMessages gets called
	myArray.AddItem( myValue );
	
	//Y loc
	myValue.Type = AS_Number;
	myValue.n = -5000; // Create it off-screen, repositioned when UpdateMessages gets called
	myArray.AddItem( myValue );

	//Display Time
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_fDisplayTime;
	myArray.AddItem( myValue );

	// How animation behaves.
	myValue.Type = AS_Number;
	myValue.n = kMsg.m_eBehavior;
	myArray.AddItem( myValue );
	
	if( kMsg.m_iDamagePrimary == 0 )
	{
		// Image 
		myValue.Type = AS_String;
		myValue.s = kMsg.m_sIconPath;
		myArray.AddItem( myValue );

		// color 
		myValue.Type = AS_String;
		myValue.s = class'UIUtilities_Colors'.static.ConvertWidgetColorToHTML(  EWidgetColor(kMsg.m_eColor) );
		myArray.AddItem( myValue );

		myMessage.m_arrMessageValues = myArray;
		myMessage.m_sFlashFunctionCall = "UpdateWorldMessageBox";
		m_arrQueuedMessages.AddItem(myMessage);

		if(m_bDelayMessages)
		{
			if(!IsTimerActive('DisplayMessageBox'))
			{
				SetTimer(m_fMessageDelay, true, 'DisplayMessageBox');
			}
		}
		else
		{
			DisplayMessageBox();
		}

		//Invoke("UpdateWorldMessageBox", myArray);
	}
	else
	{
		// damage 1 
		myValue.Type = AS_Number;
		myValue.n = kMsg.m_iDamagePrimary;
		myArray.AddItem( myValue );

		// damage 2
		myValue.Type = AS_Number;
		myValue.n = kMsg.m_iDamageModified;
		myArray.AddItem( myValue );
		
		// Crit
		myValue.Type = AS_String;
		myValue.s = kMsg.m_sCritLabel;
		myArray.AddItem( myValue );

		myValue.Type = AS_Number;
		myValue.n = kMsg.m_iDamageType;
		myArray.AddItem(myValue);

		myMessage.m_arrMessageValues = myArray;
		myMessage.m_sFlashFunctionCall = "UpdateDamageMessageBox";
		m_arrQueuedMessages.AddItem(myMessage);

		if(m_bDelayMessages)
		{
			if(!IsTimerActive('DisplayMessageBox'))
			{
				SetTimer(m_fMessageDelay, true, 'DisplayMessageBox');
			}
		}
		else
		{
			DisplayMessageBox();
		}

		//Invoke("UpdateDamageMessageBox", myArray);
	}
}

simulated function SetDamageMessageDelay(float fDelay)
{
	m_fMessageDelay = fDelay;
	m_bDelayMessages = fDelay > 0.0f;
}

simulated function UpdateMessages()
{
	local int i;
	local Vector2D vScreenLocation;
	// Optimizations
	local int len;
	local THUDMsg kMsg;
	local ASValue myValue;
	local Array<ASValue> myArray;
	local X2VisualizerInterface VisualizedObject;

	len = m_arrActiveMessages.Length;
	
	if(len == 0)
		return;

	// It's not worth batch updating locations if there's only one.
	if(len == 1)
	{
		kMsg = m_arrMsgs[m_arrActiveMessages[0]];

		VisualizedObject = X2VisualizerInterface( History.GetVisualizer(kMsg.m_kFollowObject.ObjectID) );
		if( VisualizedObject != none )
			kMsg.m_vLocation = VisualizedObject.GetUnitFlagLocation();

		// Note: Blade type check is done *second*, so that the screen location is always registered first. 
		if( class'UIUtilities'.static.IsOnscreen(kMsg.m_vLocation, vScreenLocation) || kMsg.m_eType == eHUDMessage_Blade || kMsg.m_bFollowWorldLocation )
		{
			if( VisualizedObject != none)
			{
				vScreenLocation.X += class'UIUnitFlag'.default.WorldMessageAnchorX / class'UIMovie'.default.UI_RES_X;
				vScreenLocation.Y += class'UIUnitFlag'.default.WorldMessageAnchorY / class'UIMovie'.default.UI_RES_Y;
			}
			else if( !kMsg.m_bFollowWorldLocation )
			{
				//We aren't following anything, so use the data straight from the loc settings. 
				vScreenLocation.X = kMsg.m_vLocation.X;
				vScreenLocation.Y = kMsg.m_vLocation.Y;
			}

			// If this function modified the contents of kMsg, store the results back into the array
			if(UpdateMessageLocation(kMsg, vScreenLocation))
				m_arrMsgs[m_arrActiveMessages[0]].m_bVisible = kMsg.m_bVisible;
		}
		// HAX: Special messages get their visibility forced to false when the Gameplay Updates their position.
		//      We need to ignore their visibility and just hide them anyways, if they're out of the screen they're not visible.
		else if(kMsg.m_bVisible == true || kMsg.m_bIsImportantMessage)
		{
			HideMessage( kMsg );
			// Message contents get modified, store the results
			m_arrMsgs[m_arrActiveMessages[0]].m_bVisible = kMsg.m_bVisible;
		}
	}
	else
	{
		// BEGIN OPT: Batch update locations, with variable arguments, woo!
		for( i=0; i < len; i++)
		{
			kMsg = m_arrMsgs[m_arrActiveMessages[i]];

			//If we're tracking an actor, update the message's location.
			VisualizedObject = X2VisualizerInterface( History.GetVisualizer(kMsg.m_kFollowObject.ObjectID) );
			if( VisualizedObject != none )
				kMsg.m_vLocation = VisualizedObject.GetUnitFlagLocation();

			// Updates screen location coordinates.
			if( class'UIUtilities'.static.IsOnscreen(kMsg.m_vLocation, vScreenLocation) || VisualizedObject == none )
			{
				myValue.Type = AS_String;
				myValue.s = kMsg.m_sId;
				myArray.AddItem(myValue);

				if( VisualizedObject != none )
				{
					vScreenLocation.X += class'UIUnitFlag'.default.WorldMessageAnchorX / class'UIMovie'.default.UI_RES_X;
					vScreenLocation.Y += class'UIUnitFlag'.default.WorldMessageAnchorY / class'UIMovie'.default.UI_RES_Y;

					myValue.Type = AS_Number;
					myValue.n = vScreenLocation.X * Movie.UI_RES_X; // Convert from 0-1 into 0-1280
					myArray.AddItem(myValue);

					myValue.Type = AS_Number;
					myValue.n = (vScreenLocation.Y + kMsg.m_fVertDiff) * Movie.UI_RES_Y; // Convert from 0-1 into 0-720
					myArray.AddItem(myValue);

				}
				else if( kMsg.m_bFollowWorldLocation )
				{
					myValue.Type = AS_Number;
					myValue.n = vScreenLocation.X * Movie.UI_RES_X; // Convert from 0-1 into 0-1280
					myArray.AddItem(myValue);

					myValue.Type = AS_Number;
					myValue.n = vScreenLocation.Y * Movie.UI_RES_Y; // Convert from 0-1 into 0-720
					myArray.AddItem(myValue);

				}
				else if( kMsg.m_eType == eHUDMessage_Blade )
				{
					//Use straight location 
					myValue.Type = AS_Number;
					myValue.n = kMsg.m_vLocation.X;
					myArray.AddItem(myValue);

					myValue.Type = AS_Number;
					myValue.n = kMsg.m_vLocation.Y;
					myArray.AddItem(myValue);
				}

				// Need to let flash know if we were previously hidden
				myValue.Type = AS_Boolean;
				myValue.b = !kMsg.m_bVisible; // previously hidden?
				if(kMsg.m_bVisible == false)
				{
					// Need to access array directly since kMsg is just a local copy
					m_arrMsgs[m_arrActiveMessages[i]].m_bVisible = true;
				}

				myArray.AddItem(myValue);
				
			}
			// HAX: Special messages get their visibility forced to false when the Gameplay Updates their position.
			//      We need to ignore their visibility and just hide them anyways, if they're out of the screen they're not visible.
			else if(kMsg.m_bVisible == true || kMsg.m_bIsImportantMessage)
			{
				HideMessage( kMsg );
				// Message contents get modified, store the results
				m_arrMsgs[m_arrActiveMessages[i]].m_bVisible = kMsg.m_bVisible;
			}
		}
	
		if(myArray.Length > 0)
		{
			// TODO: Profile difference in speed between baching operation and doing individual invokes.
			Invoke("UpdateMessageLocations", myArray);
		}
	}
}

// For individual message location updating (used if there's only 1 message to update)
// Returns whether kMsg was modified internally or not
simulated function bool UpdateMessageLocation( out THUDMsg kMsg, out Vector2D vScreenLocation )
{
	local bool bModifiedContents;
	local ASValue myValue;
	local Array<ASValue> myArray;
	local StateObjectReference NoneRef;

	if( kMsg.m_kFollowObject != NoneRef || kMsg.m_bFollowWorldLocation )
		vScreenLocation = Movie.ConvertNormalizedScreenCoordsToUICoords(vScreenLocation.X, vScreenLocation.Y + kMsg.m_fVertDiff);

	//MovieClip Identifier
	myValue.Type = AS_String;
	myValue.s = kMsg.m_sId;
	myArray.AddItem( myValue );
	
	//X loc
	myValue.Type = AS_Number;
	myValue.n = vScreenLocation.X; // Convert from 0-1 into 0-1280
	myArray.AddItem( myValue );
	
	//Y loc
	myValue.Type = AS_Number;
	myValue.n = vScreenLocation.Y; // Convert from 0-1 into 0-720
	myArray.AddItem( myValue );

	//Previously Hidden
	myValue.Type = AS_Boolean;
	//Specifically hide the blades during cinematics. 
	if( kMsg.m_eType == eHUDMessage_Blade && bShowDuringCinematic )
	{
		bModifiedContents = true;
		kMsg.m_bVisible = false;
		myValue.b = false;
	}
	else if(kMsg.m_bVisible == false)
	{
		bModifiedContents = true;
		kMsg.m_bVisible = true;
		myValue.b = true;
	}
	myArray.AddItem( myValue );

	Invoke("UpdateLocation", myArray);
	return bModifiedContents;
}

simulated public function RemoveMessage( string _id )
{
	local int messageID;

	messageID = m_arrMsgs.Find('m_sId', _id);
	if(messageID != -1)
	{
		AS_HideMessage(_id);
		DeactivateMessage(messageID);
	}
	else if(_id == "")
	{
		// See if the blade was requested
		RemoveHUDBladeMessage();
	}
}

// CALLBACK from Flash when message is ready to be removed.
simulated function DeactivateMessage( int msgIndex )
{
	local int updateIndex;

	if( msgIndex >= 0 && msgIndex < m_arrMsgs.Length)
	{
		// OPT: Messages are now hidden in Flash. They only get removed when the screen gets destroyed.
		m_arrMsgs[msgIndex].m_bVisible = false;

		// Stop updating this message
		updateIndex = m_arrActiveMessages.Find(msgIndex);
		if(updateIndex > -1)
			m_arrActiveMessages.Remove(updateIndex, 1);
		else if(!m_arrMsgs[msgIndex].m_bIsImportantMessage)
			`warn("Message '" $ m_arrMsgs[msgIndex].m_sId $ "' is being Deactivated, but its index '" $ msgIndex $ "' is not in the Active Messages List");

		// Only reuse messages that the game doesn't care to keep track of.
		if(!m_arrMsgs[msgIndex].m_bIsImportantMessage)
			m_arrInactiveMessages.AddItem(msgIndex);
	}
	else
	{
		`warn("UIWorldMessageMgr cannot DeactivateMessage( '" $ m_arrMsgs[msgIndex].m_sId $ "' ) as id is not in array.");
	}
}

//Show and Hide are special on the flash side: they will handle pausing/resuming all of the tweens automatically. 

simulated function HideMessage( out THUDMsg kMsg )
{
	kMsg.m_bVisible = false;
	AS_HideMessage(kMsg.m_sId);
}

simulated function ShowMessage( out THUDMsg kMsg )
{
	kMsg.m_bVisible = true;
	AS_ShowMessage(kMsg.m_sId);
}

simulated function AS_HideMessage( string id ) {
	Movie.ActionScriptVoid(MCPath$".HideMessage");
}
simulated function AS_ShowMessage( string id ) {
	Movie.ActionScriptVoid(MCPath$".ShowMessage");
}

static function XComUIBroadcastWorldMessage DamageDisplay( vector vLocation, 
														  StateObjectReference VisualizerObjectRef, 
														  string strMessage, 
														  optional ETeam eBroadcastToTeams = eTeam_None, 
														  optional class<XComUIBroadcastWorldMessage> cBroadcastMessageClass, 
														  optional int iDamagePrimary = 0,
														  optional int iDamageModified = 0, 
														  optional string strCritLabel = "",
														  optional int damageType = -1)
{
	local XComPresentationLayerBase kPres;

	kPres = XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).Pres;
	return kPres.GetWorldMessenger().Message(  
					strMessage,  //string message 
					vLocation,          //location 
					VisualizerObjectRef,				// target unit to follow
					eColor_Bad,         //color
					class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT,                   //behavior
					class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID,                   //force ID
					eBroadcastToTeams,  // broadcast, eTeam_None --> dont broadcast, message is displayed locally 
					class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM,                   //bool use screen loc
					class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC,                   //screen loc
					class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_DISPLAY_TIME,               //display time
					cBroadcastMessageClass,
					,
					iDamagePrimary, 
					iDamageModified,
					strCritLabel,
					,
					damageType); 
}

simulated function XComUIBroadcastWorldMessage BladeMessage(
	string                  _sMsg,
	optional string         _sId = "",
	optional StateObjectReference _TargetObject,
	optional vector _AnchorLocation,
	optional bool HideInShotHud = false)
{
	local float displayTime; 
	local StateObjectReference NoneRef; 
	local string ParsedMsg; 
	
	//If named, then kismet will need to remove this manually. 
	displayTime = (_sId == "") ? 0.0 : 5.0;

	ParsedMsg = class'UIUtilities_Input'.static.InsertPCIcons(_sMsg);

	if( _TargetObject == NoneRef && _AnchorLocation == vect(0,0,0) )
	{
		//Non-tracking message will stay in a single location.
		//return Message(_sMsg, vect(0,0,0) , , , , _sID, , true, vect2D(1.0, 0.0), displayTime, , , , , , eHUDMessage_Blade);
		CreateHUDBladeMessage(ParsedMsg, _sId, HideInShotHud);
	}
	else
	{
		//Tracking messages will follow the target object or location
		return Message(ParsedMsg, _AnchorLocation, _TargetObject, , , _sID, , , , displayTime, , , , , , eHUDMessage_Blade);
	}
}

function CreateHUDBladeMessage(string _sMsg, string _sId, bool _bHideInShotHud)
{
	if( BladeHUDMessage == none )
	{
		BladeHUDMessage = Spawn(class'UIPanel', self).InitPanel('', 'TutorialBlade');
		BladeHUDMessage.AnchorBottomRight();
		BladeHUDMessage.SetY(-350);

		`SOUNDMGR.PlaySoundEvent("TacticalUI_Tutorial_Blade_Fly_In");
	}

	HideBladeMessageInShotHud = _bHideInShotHud;

	BladeHUDMessage.MC.FunctionString("SetText", _sMsg);
}

function RemoveHUDBladeMessage()
{
	if( BladeHUDMessage != none )
		BladeHUDMessage.Remove();

	BladeHUDMessage = none; 
}

function RemoveAllBladeMessages()
{
	local int Index;

	for(Index = m_arrMsgs.Length - 1; Index >= 0; Index--)
	{
		if(m_arrMsgs[Index].m_eType == eHUDMessage_Blade)
		{
			AS_HideMessage(m_arrMsgs[Index].m_sId);
			DeactivateMessage(Index);
		}
	}

	RemoveHUDBladeMessage();
}

function NotifyShotHudRaised()
{
	if(HideBladeMessageInShotHud)
	{
		RemoveHUDBladeMessage();
		HideBladeMessageInShotHud = false;
	}
}

//==============================================================================

simulated state Active
{
	simulated event Tick( float fDeltaT )
	{
		UpdateMessages();
	}
}

simulated function Remove()
{
	Movie.Pres.m_kWorldMessageManager = none; 
	super.Remove();
}

function SetShowDuringCinematic(bool bSetting)
{
	bShowDuringCinematic = bSetting;
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	Package = "/ package/gfxWorldMessageMgr/WorldMessageMgr";
	MCName = "theWorldMessageContainer";

	m_fVertDiff = 0.05f;
	m_fMessageDelay=0.0f;
	m_bDelayMessages=false;

	DAMAGE_DISPLAY_DEFAULT_ID=""
	DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM=false
    DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC=(X=0.0f,Y=0.0f)
	DAMAGE_DISPLAY_DEFAULT_DISPLAY_TIME=5.0f

	bShowDuringCinematic = true; //World messages should be visible in all situations except in matinee cameras
}
