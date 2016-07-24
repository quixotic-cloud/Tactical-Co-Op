//-----------------------------------------------------------
// Works like PointInSpace, except that it can be spawned at runtime
//-----------------------------------------------------------
class DynamicPointInSpace extends Actor native(Core);

var transient vector				Forward, Right, Up;

//These actors are used for remote viewers
var transient privatewrite int ObjectID; //Unique identifier for this object - used for network serialization and game state searches

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	GetAxes( Rotation, Forward, Right, Up );
}

function SetObjectID(int InObjectID)
{
	ObjectID = InObjectID;
}

DefaultProperties
{	
	bStatic=false
	ObjectID=-1
}
