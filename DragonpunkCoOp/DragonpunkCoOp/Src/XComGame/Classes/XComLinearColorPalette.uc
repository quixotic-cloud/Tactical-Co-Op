class XComLinearColorPalette extends object
	native(Core);

struct native XComLinearColorPaletteEntry
{
	var() LinearColor Primary;
	var() LinearColor Secondary;
};

var() array<XComLinearColorPaletteEntry> Entries;
var() int BaseOptions;

defaultproperties
{
	
}
