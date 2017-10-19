package;

// Externs for sortable.js, a drop-in script to make tables sortable (https://github.com/HubSpot/sortable)
@:native("Sortable")
extern class Sortable {
	public static function init():Void;
	public static function initTable(id:String):Void;
}