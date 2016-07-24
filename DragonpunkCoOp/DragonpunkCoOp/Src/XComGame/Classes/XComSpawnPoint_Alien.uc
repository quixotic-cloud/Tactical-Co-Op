//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComSpawnPoint_Alien extends XComSpawnPoint;

// Defines the behavior of the alien created at this spawn point
enum EBehavior
 {
	EAIBehavior_None<DisplayName=None>,
	EAIBehavior_Hunt<DisplayName=Hunt>,
	EAIBehavior_SeekActor<DisplayName=SeekActor>
 };

var() EBehavior     m_eBehavior;
var() Actor         kSeekActor; // Actor to pursue, until we encounter an enemy, or until we are within fSeekRadius of the actor's location. Used only for SeekActor behavior.
var() float         fSeekRadius; // Distance in units before we have 'reached' kSeekActor.  Used only for SeekActor behavior.  Default is 640 units (= 10 meters)
/** This spawn point will always be selected to drop an alien down **/
var() bool          m_bForcePlacement;
var() bool          bKismetSpawnOnly<ToolTip="This spawn point is not to be used when spawning units at level start.">;

var protected bool    m_bUseAltLocation;      //  allows game code to override the Location
var protected Vector  m_vAltLocation;         //  the real vector to use instead of Location

function SetAlternateLocation(Vector vLoc)
{
	m_bUseAltLocation = true;
	m_vAltLocation = vLoc;
}

function ClearAlternateLocation()
{
	m_bUseAltLocation = false;
}

function Vector GetSpawnPointLocation()
{
	if (m_bUseAltLocation)
		return m_vAltLocation;

	return super.GetSpawnPointLocation();
}

defaultproperties
{
	UnitType=UNIT_TYPE_Alien
	bKismetSpawnOnly=false

	m_eBehavior=EAIBehavior_Hunt
	fSeekRadius=640
}
