/**
 * X2SpawnNode interface provides functions for actors which can serve as spawn locations for AIs in XCom2.
 */

interface X2SpawnNode
	native(Core);


cpptext
{
public:
	// Get the spawn location for pods based on this Spawn Node's placement
	virtual const FVector& GetSpawnLocation() const=0;

	// Create the group that will associate the units which spawn from this node during gameplay
	virtual AXGAIGroup* CreateSpawnGroup() const=0;
};