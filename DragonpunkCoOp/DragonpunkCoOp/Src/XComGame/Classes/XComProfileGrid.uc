//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------
class XComProfileGrid extends Actor
	native
	notplaceable
	transient;

var transient float LocalTime;
var transient float DelayTime;
var transient int Index;

var transient int Heading;
var transient int Pitch;
var transient int Roll;
var transient float Fov;

struct native StatItem
{
	var IntPoint Tile;
	var float Fps;
	var float MS;
};

var array<StatItem> StatItems;

auto state Idle
{
Begin:
	Sleep(4.0f);
	`CHEATMGR.ToggleFOW("");
	GotoState('Processing');
}

state Processing
{
	function Update(float dt)
	{
		local StatItem Stat;
		local Vector Pos;
		local TTile Tile;

		LocalTime += dt;
		if (LocalTime >= DelayTime)
		{
			Tile.X = Index % `XWorld.NumX;
			Tile.Y = Index / `XWorld.NumX;
			Tile.Z = 0;
			Pos = `XWORLD.GetPositionFromTileCoordinates(Tile);
			SetCamera(Pos);

			Stat.Tile.X = Tile.X;
			Stat.Tile.Y = Tile.Y;
			Stat.Fps = class'Engine'.static.GetAverageFPS();
			Stat.MS = class'Engine'.static.GetAverageMS();
			StatItems.AddItem(Stat);
			
			LocalTime = 0.0f;
			Index++;
			if (Tile.Y >= `XWorld.NumY)
			{
				GotoState('Complete');
			}
		}
	}
}


state Complete
{
	simulated event BeginState( name PrevStateName )
	{
		
	}

Begin:
	SaveStatItems("stat.json");
	ConsoleCommand("exit");
}


simulated function Update(float dt);
native function SaveStatItems(string FileName);

simulated event Tick(float dt)
{
	super.Tick(dt);

	Update(dt);
}


function SetCamera(Vector pos)
{
	local XComTacticalController PC;
	local XComCamera camera;

	foreach WorldInfo.AllControllers(class'XComTacticalController', PC)
	{
		camera = XComCamera(PC.PlayerCamera);
		camera.GotoState('ProfileGridView');

		pos.Z = camera.CameraCache.POV.Location.Z;
		camera.CameraCache.POV.Location = pos;
		camera.CameraCache.POV.Rotation.Pitch = Pitch;
		camera.CameraCache.POV.Rotation.Roll = Roll;
		camera.CameraCache.POV.Rotation.Yaw = Heading;
		camera.CameraCache.POV.FOV = Fov;
	}
}


defaultproperties
{
	LocalTime = 0.0f
	DelayTime = 0.05f
	Index = 0

	Heading = 27693
	Pitch = -8563
	Roll = 0
	Fov = 70.0f
}