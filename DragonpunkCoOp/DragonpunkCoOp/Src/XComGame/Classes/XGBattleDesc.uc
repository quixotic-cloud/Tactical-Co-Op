//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGBattleDesc extends Actor	
	dependson(XComContentManager,XComMapManager)
	native(Core);

struct native TMissionReward
{
	var int iScientistSkill;
	var int iEngineerSkill;
	var int iSoldierClass;
	var int iSoldierLevel;
	var int iCredits;
	var int iData;
	var int iSupplies;
	var int iIntel;
	var int iClue;
	var int iItem;
	var int iCountry;
	var int iCity;
};

struct native TAlienInfo
{
	var int iMissionDifficulty;
	var int iNumAliens;
	var int iNumStaticPods;

	var float fSecondaryAlienRatio;

	// Alien Types
	var name    nMissionCommander;          // CharacterTemplate Name
	var name    nMissionCommanderSupporter; // CharacterTemplate Name

	var name    nPodLeaderType;             // CharacterTemplate Name
	var name    nPodSupporterType;          // CharacterTemplate Name

	var name    nSecondaryPodLeaderType;    // CharacterTemplate Name
	var name    nSecondaryPodSupporterType; // CharacterTemplate Name

	var name    nRoamingType;               // CharacterTemplate Name
	var name    nRoamingSupporterType;      // CharacterTemplate Name

	var int     iNumRoaming;
	var bool    bProcedural;        // Pull all aliens out of pods.
	var int     iNumRandomAI;       // Pull N aliens out of pods.  

	var int     iUFOType;           // EShipType
};

var repnotify int m_iNumPlayers;


//------------STRATEGY GAME DATA -----------------------------------------------
// ------- Please no touchie ---------------------------------------------------
var string              m_strLocation;          // The city and country where this mission is taking place
var string              m_strOpName;            // Operation name
var string              m_strObjective;         // Squad objective
var string              m_strDesc;              // Type of mission string
var string              m_strMapName;           // Map display name, mostly just for looking up content -- jboswell
var string              m_strMapCommand;        // Name of map
var string              m_strTime;              // Time of Day string
var int				    m_iMissionID;           // Mission ID in the strategy layer
var int                 m_iMissionType;         // CHENG - eMission_TerrorSite
var int                 m_iNumTerrorCivilians;  // How many civilians on this map (only if this is a terror map.)
var TAlienSquad         m_kAlienSquad;
var EShipType           m_eUFOType;
var EContinent          m_eContinent;
var ETOD          m_eTimeOfDay;
var bool                m_bOvermindEnabled;
var bool                m_bIsFirstMission;      // Is this the player's very first mission?
var bool                m_bIsTutorial;          // Is this the tutorial
var bool                m_bDisableSoldierChatter; // Disable Soldier Chatter
var bool                m_bScripted;            // Is this mission the scripted first mission?
var float               m_fMatchDuration;
var array<int>          m_arrSecondWave;
var int                 m_iPlayCount;
var bool                m_bSilenceNewbieMoments;
//------------------------------------------------------------------------------
//------------END STRATEGY GAME DATA -------------------------------------------

var bool                m_bUseAlienInfo;
var TAlienInfo          m_kAlienInfo;

replication
{
	if(bNetDirty && Role == ROLE_Authority)
		m_iNumPlayers;
}

function string GetTimeString()
{
	return m_strTime;
}

function string GetBattleDescription()
{
	return m_strDesc;
}

function string GetBattleObjective()
{
	return m_strObjective;
}

function string GetOpName()
{
	return m_strOpName;
}

defaultproperties
{
	m_strDesc="Alien Abduction Site"
	//m_strObjective="Explore landing site and, if possible, gain entry to the UFO.  Mission will be successful when all enemy units have been eliminated or neutralized."
	m_strObjective="Explore the abduction site and eliminate any alien opposition. All targets hostile."


	m_iMissionType=eMission_Abduction
	m_iNumTerrorCivilians=18

	bTickIsDisabled=true

	// network variables -tsmith 
	//bAlwaysRelevant = true
	//RemoteRole=ROLE_SimulatedProxy
	RemoteRole=ROLE_None
	bAlwaysRelevant=false
}
