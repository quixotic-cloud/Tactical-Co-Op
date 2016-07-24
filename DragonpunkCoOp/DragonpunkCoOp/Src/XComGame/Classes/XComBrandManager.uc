class XComBrandManager extends Object
	dependson(XComParcelManager)
	native(Core)
	config(Brands);

struct native PlotBrandDefinition
{
	var string strPlot;
	var array<string> arrBrands;
};

struct native BrandDefinition
{
	var string strBrand;
	var array<string> strTextures;
};

var private config array<PlotBrandDefinition> arrPlotDefinitions;
var private config array<BrandDefinition> arrBrandDefinitions;

static native function SwapBrandsForParcels(const out StoredMapData MapData);
static native function int GetRandomBrandForMap(string MapName);
