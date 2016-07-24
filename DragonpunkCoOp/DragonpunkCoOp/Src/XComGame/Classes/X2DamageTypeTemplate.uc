class X2DamageTypeTemplate extends X2DataTemplate config(GameCore);

var(X2DamageTypeTemplate) int  FireChance;	 //Percent chance that this damage type will set a fire
var(X2DamageTypeTemplate) int  MaxFireCount; //How many secondary fires can this damage type set?
var(X2DamageTypeTemplate) int  MinFireCount; //How many secondary fires can this damage type set?
var(X2DamageTypeTemplate) bool bCauseFracture;
var(X2DamageTypeTemplate) bool bAllowAnimatedDeath;

DefaultProperties
{	
}