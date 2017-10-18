package;

/**
 * Utility functions
 * @author Sam Twidale (http://www.geometrize.co.uk/)
 */
class Util {
	// TODO
	function formatBytes(bytes:Int, decimals:Int):String {
		if (bytes == 0) return '0 Bytes';
		var k = 1024;
		var dm = decimals || 2,
		var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
		var i = Math.floor(Math.log(bytes) / Math.log(k));
		return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
	}
}