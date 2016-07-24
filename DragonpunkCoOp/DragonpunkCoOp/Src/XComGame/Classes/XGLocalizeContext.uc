class XGLocalizeContext extends Object native(Core);

var array<XGLocalizeTag> LocalizeTags;

native function XGLocalizeTag FindTag(string TagName);
native function bool Expand(string TagName, string OptName, out string OutString);
