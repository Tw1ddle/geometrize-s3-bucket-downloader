package;

/**
 * Bucket/bucket listing config/preferences
 * @author Sam Twidale (http://www.geometrize.co.uk/)
 */
class BucketConfig {
	public function new() {
	}
	public var BUCKET_URL(default, null):String = "https://geometrize-installer-bucket.s3.amazonaws.com/";
	public var EXCLUDE_FILES(default, null):Array<String> = ["index.html", "geometrize-s3-bucket-downloader.js", "style.min.css", "sortable.min.js"];
	public var EXCLUDE_DIRECTORIES(default, null):Array<String> = [];
}