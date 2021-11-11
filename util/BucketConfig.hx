package util;

/**
 * Bucket/bucket listing config/preferences
 * @author Sam Twidale (http://www.geometrize.co.uk/)
 */
class BucketConfig {
	public function new(bucketUrl:String, excludeFiles:Array<String>, excludeDirectories:Array<String>) {
		this.bucketUrl = bucketUrl;
		this.excludeFiles = excludeFiles;
		this.excludeDirectories = excludeDirectories;
	}
	public var bucketUrl(default, null):String;
	public var excludeFiles(default, null):Array<String>;
	public var excludeDirectories(default, null):Array<String>;
}