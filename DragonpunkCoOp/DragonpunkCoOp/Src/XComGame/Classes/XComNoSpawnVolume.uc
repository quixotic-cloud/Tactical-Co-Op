/* XComNoSpawnVolume
 * Volumes placed in editor to specify cover points that are unpathable from the start of the game,
 * i.e. inside large containers w/ no doors, etc.
 * When spawning or selecting overmind destinations, filter these cover points out.
 */
class XComNoSpawnVolume extends Volume
	placeable
	native;

var() bool CivilianNoSpawnZone;
var() bool AlienNoSpawnZone;

DefaultProperties
{
	CivilianNoSpawnZone=true
	AlienNoSpawnZone=true
}