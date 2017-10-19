package;

/**
 * Utility functions
 * @author Sam Twidale (http://www.geometrize.co.uk/)
 */
class Util {
	/**
	 * Formats a number of bytes into a human-readable string.
	 * @param bytes A number of bytes.
	 * @param decimals The decimal precision e.g. 2 => 10.21, 3 => 10.213 etc.
	 * @return A human-readable representation of the bytes e.g. 1024 => 1.00KB
	 */
	public static function formatBytes(bytes:Float, decimals:Int):String {
		if (bytes == 0) {
			return '0 Bytes';
		}
		var k:Int = 1024;
		var sizes:Array<String> = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
		var i:Int = Math.floor(Math.log(bytes) / Math.log(k));
		return Std.string(floatToStringPrecision(bytes / Math.pow(k, i), decimals)) + ' ' + sizes[i];
	}
	
	private static function floatToStringPrecision(n:Float, prec:Int) {
		n = Math.round(n * Math.pow(10, prec));
		var str:String = '' + n;
		var len:Int = str.length;
		if(len <= prec) {
			while(len < prec) {
				str = '0' + str;
				len++;
			}
			return '0.' + str;
		}
		return str.substr(0, str.length - prec) + '.' + str.substr(str.length - prec);
	}
}