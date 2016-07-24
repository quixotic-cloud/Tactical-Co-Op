// Purpose: Interface for actors that need to update building visibility over time. 
// Author: Jeremy Shopf 3/19/2012
// 
// 
interface IXComBuildingVisInterface
	native
	dependson(XComPawnIndoorOutdoorInfo);


function XComPawnIndoorOutdoorInfo GetIndoorOutdoorInfo()
{
}

function Actor GetActor()
{
}

event XComBuildingVolume GetCurrentBuildingVolumeIfInside()
{
}

event bool IsInside()
{
}
