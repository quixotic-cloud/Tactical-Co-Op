class XComGameStateNetworkManager extends Object
	inherits(FTickableObject)
	dependson(XComGameState, XComGameStateContext)
	config(Game)
	native(MP);

const HISTORY_OBJECT_INDEX = -2;
const MIRROR_HISTORY_INDEX = -3;

enum eConnectionValidationState
{
	eCVS_Unknown,
	eCVS_ValidationSent,
	eCVS_Validated,
	eCVS_Desynchronized,
	eCVS_GeneratingReport,
	eCVS_StartingSynchRepair,
	eCVS_RepairingSynch,
	eCVS_FinishingRepairs,
	eCVS_FinishedSynchRepair
};

enum eGameDataType
{
	eGDT_None,
	eGDT_History,
	eGDT_GameState,
	eGDT_MergeGameState,
	eGDT_ValidateConnection,
	eGDT_ValidateGameState,
	eGDT_GameStateContext,
	eGDT_HistoryDelta
};

enum ePendingDataState
{
	ePDS_NotHandled,
	ePDS_Sent,
	ePDS_Processed
};

struct native PendingGameData
{
	var int                 LastUpdateTick;

	var ePendingDataState   PendingState;
	var int                 ConnectionIndex;

	// Serialized Data
	var eGameDataType		GameDataType;
	var int					HistoryIndex;
	var int					OrderIndex;
	var int					TotalBunches;
	var int					BunchOffset;
	var array<byte>			GameStateRaw;

	structdefaultproperties
	{
		PendingState=ePDS_NotHandled
	}
};
var array<PendingGameData>	InGameData;
var array<PendingGameData>	OutGameData;

struct native HistoryContextData
{
	var int                 HistoryIndex;   // Game State History Index of when this Context was created, then used for processing
	var bool                bAddedLocally;
	var bool                bAddedRemotely;
	var XComGameStateContext ContextRef;
	var array<PendingGameData> GameData;    // Pre-processed game data easy for sending to a particular connection
};
var array<HistoryContextData> ContextHistory; // Keeps track of all Contexts - incoming / outgoing. Should be in order exactly like HistoryIndex
var array<BYTE> BaseHistoryData;              // Last sent history data used for binary Delta updates

struct native ConnectionInfo
{
	// Connection details
	var native pointer NetConnection{UNetConnection};
	var string ConnectedPlayerName;

	var XComGameStateHistory HistoryMirror;
	var X2EventManager  EventManagerMirror;

	var eConnectionValidationState CurrentConnectionState;

	var float LastSyncPointTime;
	var int CurrentSyncPoint;
	var int CurrentSyncPointHistoryIndex;

	var int LastSendHistoryContextIndex;    // Makes sure that all local contexts that have not been sent to this connection are sent
	var int LastRecvHistoryContextIndex;    // Makes sure that all remote contexts that have not been submitted to the ruleset are processed accordingly

	var array<int> HistorySentContexts;     // History of all Contexts sent to this connection
	var array<int> HistoryReceivedContexts; // History of all Contexts received from this connection

	// Current history frame index
	var int CurrentSendHistoryIndex;
	var int CurrentRecvHistoryIndex;
	var bool bHasFullHistory;       // Has been initialized
	var bool bValidated;            // Connection is at the same history position
	var float LastHeartbeatTime;    // Sending of a validation heartbeat
	var float LastValidationTime;   // Time the last full validation check was sent

	structcpptext
	{
		FConnectionInfo()
		{
			appMemzero(this, sizeof(FConnectionInfo));
		}

		FConnectionInfo(EEventParm)
		{
			appMemzero(this, sizeof(FConnectionInfo));
		}

		void ConstructMirrors(UObject* Outer)
		{
			EventManagerMirror = ConstructObject<UX2EventManager>(UX2EventManager::StaticClass(), Outer);
			HistoryMirror = ConstructObject<UXComGameStateHistory>(UXComGameStateHistory::StaticClass(), Outer);
		}
	}
};

var float TimeSinceLastNetworkSend;                 // Used in conjunction with the ResendTimeout to know if a bundle has been lost
var config float NetworkResendTimeout;              // Number of seconds to wait until resending a data bundle if an ACK is not received
var config bool bPauseGameStateSending;             // If true, this will keep the InputContext from being sent; otherwise it will send the whole History when necessary.
var array<ConnectionInfo> Connections;
var name ServerNetDriverName;
var name ClientNetDriverName;
//var array<delegate<OnCreateServer> >                CreateServerDelegates;
//var array<delegate<OnCreateClient> >                CreateClientDelegates;
var array<delegate<OnReceiveHistory> >	            ReceiveHistoryDelegates;
var array<delegate<OnReceivePartialHistory> >	    ReceivePartialHistoryDelegates;
var array<delegate<OnReceiveGameState> >	        ReceiveGameStateDelegates;
var array<delegate<OnReceiveMergeGameState> >	    ReceiveMergeGameStateDelegates;
var array<delegate<OnReceiveGameStateContext> >	    ReceiveGameStateContextDelegates;
var array<delegate<OnReceiveValidateConnection> >	ReceiveValidateConnectionDelegates;
var array<delegate<OnReceiveValidateGameState> >	ReceiveValidateGameStateDelegates;
var array<delegate<OnPlayerJoined> >	            PlayerJoinedDelegates;
var array<delegate<OnPlayerLeft> >	                PlayerLeftDelegates;
var array<delegate<OnReceiveLoadTacticalMap> >	    ReceiveLoadTacticalMapDelegates;
var array<delegate<OnReceivePlayerReady> >	        ReceivePlayerReadyDelegates;
var array<delegate<OnReceiveRemoteCommand> >	    ReceiveRemoteCommandDelegates;
var array<delegate<OnReceiveMirrorHistory> >	    ReceiveMirrorHistoryDelegates;
var array<delegate<OnReceiveSyncPoint> >	        ReceiveSyncPointDelegates;
var array<delegate<OnNotifyAcceptingConnection> >	NotifyAcceptingConnectionDelegates;
var array<delegate<OnNotifyAcceptedConnection> >	NotifyAcceptedConnectionDelegates;
var array<delegate<OnNotifyConnectionClosed> >	    NotifyConnectionClosedDelegates;


cpptext
{
	void Init();
	void Exit();
	void BuildQueueData(TArrayNoInit<struct FPendingGameData>& GameDataArray, const TArray<BYTE>& GameStateRaw, INT GameDataType, INT MaxSize, INT HistoryIndex=UCONST_HISTORY_OBJECT_INDEX);
	void QueueData(const TArrayNoInit<struct FPendingGameData>& GameDataArray); // Adds all data from array into the OutGameData array.
	void QueueData(const TArray<BYTE>& GameStateRaw, INT GameDataType, INT MaxSize, INT HistoryIndex=UCONST_HISTORY_OBJECT_INDEX); // Builds and adds data bunches to the OutGameData array.
	void SendData(UNetConnection* Conn, const struct FPendingGameData& PendingGameData);
	void ReceiveData(UNetConnection* Conn, FInBunch& Bunch);
	void ReceiveDataComplete(UNetConnection* Conn, FInBunch& Bunch);
	void UpdateConnectionContextHistory(INT ConnectionIdx);

	void TickInData(FLOAT DeltaTime);
	void TickHeartBeat(FLOAT DeltaTime);
	void TickOutData(FLOAT DeltaTime);

	void SendValidationTimeout(INT ConnectionIdx);
	void ReceiveValidationTimeout(INT ConnectionIdx, const TArray<BYTE>& RawParams);

	void Desynchronize(INT ConnectionIdx, const FString& Reason);
	void ReceiveDesynchronized(INT ConnectionIdx, const TArray<BYTE>& RawParams);

	UBOOL AreAllConnectionsValid();
	UBOOL IsConnectionValid(INT ConnectionIdx);

	void ReceiveRequestNewHistory(INT ConnectionIdx, const TArray<BYTE>& RawParams);
	void ReceiveRequestDelta(INT ConnectionIdx, const TArray<BYTE>& RawParams);
	void ProcessIncomingHistory(INT ConnectionIdx, const TArray<BYTE>& NewHistoryData);


//
// Setup the FNetworkNotify Interface
//
	virtual EAcceptConnection NotifyAcceptingConnection( UNetDriver* InNetDriver );
	virtual void NotifyAcceptedConnection( class UNetConnection* Connection );
	virtual void NotifyConnectionClosed( class UNetConnection* Connection );
	virtual UBOOL NotifyAcceptingChannel( class UChannel* Channel );
	virtual void NotifyControlMessage(UNetConnection* Connection, BYTE MessageType, class FInBunch& Bunch);
	virtual UBOOL NotifySendingFile( UNetConnection* Connection, FGuid GUID );
	virtual void NotifyReceivedFile( UNetConnection* Connection, INT PackageIndex, const TCHAR* Error, UBOOL Skipped );
	virtual void NotifyProgress( EProgressMessageType MessageType, const FString& Title, const FString& Message );

	virtual class UWorld* NotifyGetWorld();
	virtual void NotifyPeerControlMessage(UNetConnection* Connection, BYTE MessageType, class FInBunch& Bunch);
	virtual EAcceptConnection NotifyAcceptingPeerConnection( UNetDriver* InNetDriver );
	virtual void NotifyAcceptedPeerConnection( class UNetConnection* Connection );


//
// Setup FXS Channel Messages
//
	virtual UBOOL HandleFxsChannelMessage(UNetConnection* Connection, INT MessageType, class FInBunch& Bunch);


//
// FTickableObject interface
//
	/**
	 * Returns whether it is okay to tick this object. E.g. objects being loaded in the background shouldn't be ticked
	 * till they are finalized and unreachable objects cannot be ticked either.
	 *
	 * @return	TRUE if tickable, FALSE otherwise
	 */
	virtual UBOOL IsTickable() const;
	/**
	 * Used to determine if an object should be ticked when the game is paused.
	 *
	 * @return always TRUE as networking needs to be ticked even when paused
	 */
	virtual UBOOL IsTickableWhenPaused() const;
	/**
	 * Just calls the tick event
	 *
	 * @param DeltaTime The time that has passed since last frame.
	 */
	virtual void Tick(FLOAT DeltaTime);
}
var transient native pointer NetworkNotifyListener{FNetworkNotify};



static native final function XComGameStateNetworkManager GetGameStateNetworkManager();

static native function AddCommandParam_String(string InString, out array<byte> Params);
static native function AddCommandParam_Int(int InInt, out array<byte> Params);
static native function AddCommandParam_Bool(bool InBool, out array<byte> Params);

static native function string   GetCommandParam_String(out array<byte> Params);
static native function int      GetCommandParam_Int(out array<byte> Params);
static native function bool     GetCommandParam_Bool(out array<byte> Params);


native function bool CreateServer(URL InURL, out String Error);
//delegate OnCreateServer(bool bSuccess);
//`AddClearDelegates(CreateServer)

native function bool CreateClient(URL InURL, out String Error);
//delegate OnCreateClient(bool bSuccess);
//`AddClearDelegates(CreateClient)
native function bool ForceConnectionAttempt(); // Sends out a message to the server seeking to connect; needed because the old method of connection relied on Map Travel to seek out a connection to the server.


native function Disconnect();
native function ResetConnectionData();

native function bool HasServerConnection();
native function bool HasClientConnection();
native function bool HasConnections();

native function PrintDebugInformation(optional bool bIncludeDetailedHistory=true);

// Turns on and off the sending of all differing history frames to the known connections
event SetPauseGameStateSending(bool bPauseSending)
{
	bPauseGameStateSending = bPauseSending;
}

event bool HasPendingData()
{
	return (InGameData.Length + OutGameData.Length) > 0;
}

event string GetConnectionInfoDebugString(int ConnectionIdx)
{
	local string kStr;
	if (ConnectionIdx >= 0 && ConnectionIdx < Connections.Length)
	{
		kStr = "("$ConnectionIdx$"): '"$Connections[ConnectionIdx].ConnectedPlayerName$"'";
		kStr @= `ShowVar(Connections[ConnectionIdx].CurrentSendHistoryIndex, SendHistoryIndex);
		kStr @= `ShowVar(Connections[ConnectionIdx].CurrentRecvHistoryIndex, RecvHistoryIndex);
		kStr @= `ShowVar(Connections[ConnectionIdx].bHasFullHistory, bHasFullHistory);
	}
	return kStr;
}

native function RequestMirrorHistory(INT ConnectionIdx);
native function GenerateValidationReport(XComGameStateHistory ReportHistory, X2EventManager ReportEventManager);
native function GenerateOfflineValidationReport(string NameOfSaveFileOne, string NameOfSaveFileTwo, optional string Dir);
native function GenerateOfflineValidationReportForDirectory(string Dir);

// Adds the context to the Context History and will send to the correct connections at the right time.
native function QueueContextForSending(XComGameStateContext SendContext, int HistoryIndex);

event bool SubmitContextToRuleset(XComGameStateContext SendContext)
{
	local X2TacticalGameRuleset TacticalRuleset;
	TacticalRuleset = `TACTICALRULES;
	if (TacticalRuleset.AddNewStatesAllowed())
	{
		TacticalRuleset.SubmitGameStateContext(SendContext);
		return true;
	}
	return false;
}


//
// Send/Receive Remote Command
//
native function SendRemoteCommand(string Command, array<byte> RawParams);
native function ReceiveRemoteCommand(INT ConnectionIdx, string Command, array<byte> RawParams);
delegate OnReceiveRemoteCommand(string Command, array<byte> RawParams);
`AddClearDelegates(ReceiveRemoteCommand)


//
// Send/Receive History
//
native function SendHistory(XComGameStateHistory History, X2EventManager EventManager);
native function ReceiveHistory(int ConnectionIdx, array<byte> Raw);
delegate OnReceiveHistory(XComGameStateHistory History, X2EventManager EventManager);
`AddClearDelegates(ReceiveHistory)


//
// Send/Receive Partial History
//
native function SendPartialHistory(XComGameStateHistory History, X2EventManager EventManager);
native function ReceivePartialHistory(int ConnectionIdx, array<byte> Raw);
delegate OnReceivePartialHistory(XComGameStateHistory History, X2EventManager EventManager);
`AddClearDelegates(ReceivePartialHistory)


//
// Send/Receive Game State
//
native function SendGameState(XComGameState GameState, int HistoryIndex);
native function ReceiveGameState(int ConnectionIdx, array<byte> Raw, int HistoryIndex);
delegate OnReceiveGameState(XComGameState GameState);
`AddClearDelegates(ReceiveGameState)


//
// Send/Receive Merge Game State
//
native function SendMergeGameState(XComGameState GameState);
native function ReceiveMergeGameState(array<byte> Raw, int HistoryIndex);
delegate OnReceiveMergeGameState(XComGameState GameState);
`AddClearDelegates(ReceiveMergeGameState)


//
// Send/Receive Game State Context
//
native function SendGameStateContext(XComGameStateContext Context);
native function ReceiveGameStateContext(int ConnectionIdx, array<byte> Raw, int HistoryIndex);
delegate OnReceiveGameStateContext(XComGameStateContext Context);
`AddClearDelegates(ReceiveGameStateContext)


//
// Send/Receive Validate Connection
//
native function SendValidateConnection();
native function ReceiveValidateConnection(int ConnectionIdx, array<byte> Raw);
delegate OnReceiveValidateConnection();
`AddClearDelegates(ReceiveValidateConnection)


//
// Send/Receive Validate Game State
//
native function SendValidateGameState(XComGameState GameState);
native function ReceiveValidateGameState(int ConnectionIdx, array<byte> Raw, int HistoryIndex);
delegate OnReceiveValidateGameState(XComGameState GameState);
`AddClearDelegates(ReceiveValidateGameState)


//
// Player Join Event
//
delegate OnPlayerJoined(string RequestURL, string Address, const UniqueNetId UniqueId, bool bSupportsAuth);
`AddClearDelegates(PlayerJoined)


//
// Player Left Event
//
delegate OnPlayerLeft(const UniqueNetId UniqueId);
`AddClearDelegates(PlayerLeft)


//
// Send/Receive LoadTacticalMap
//
native function SendLoadTacticalMap();
native function ReceiveLoadTacticalMap();
delegate OnReceiveLoadTacticalMap();
`AddClearDelegates(ReceiveLoadTacticalMap)


//
// Send/Receive PlayerReady
//
native function SendPlayerReady();
native function ReceivePlayerReady();
delegate OnReceivePlayerReady();
`AddClearDelegates(ReceivePlayerReady)


//
// Send/Receive MirrorHistory
//
native function SendMirrorHistory(int ConnectionIdx);
native function ReceiveMirrorHistory(int ConnectionIdx, array<byte> Raw);
delegate OnReceiveMirrorHistory(XComGameStateHistory History, X2EventManager EventManager);
`AddClearDelegates(ReceiveMirrorHistory)


//
// Ruleset SyncPoints
//
native function SendSyncPoint(int SyncPoint);
native function ReceiveSyncPoint(int ConnectionIdx, array<byte> Raw);
delegate OnReceiveSyncPoint(int SyncPoint);
`AddClearDelegates(ReceiveSyncPoint)


//
// Connection Delegates
//
delegate OnNotifyAcceptingConnection( );
`AddClearDelegates(NotifyAcceptingConnection)
delegate OnNotifyAcceptedConnection(int ConnectionIdx);
`AddClearDelegates(NotifyAcceptedConnection)
delegate OnNotifyConnectionClosed(int ConnectionIdx);
`AddClearDelegates(NotifyConnectionClosed)

// called when NotifyConnectionClosed is called but there are no delegates. Failsalfe fallback -tsmith
private event OnNotifyConnectionClosed_NoDelegates()
{
	`log(`location @ "Returning to start screen",, 'XCom_Net');
	class'Engine'.static.GetCurrentWorldInfo().ConsoleCommand("open"@`Maps.SelectShellMap()$"?Game=XComGame.XComShell");
}

event Tick( float fDeltaT )
{
}

defaultproperties
{
	ServerNetDriverName="MPListenServer"
	ClientNetDriverName="MPClient"
	TimeSinceLastNetworkSend=0.0f
}