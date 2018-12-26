package;

/**
 * Represents info relating to a listing of a "directory" within an S3 bucket
 * @author Sam Twidale (http://www.geometrize.co.uk/)
 */
class DirectoryInfo {
	public function new(prefix:String, files:Array<S3File>, directories:Array<S3Directory>) {
		this.prefix = prefix;
		this.files = files;
		this.directories = directories;
	}
	public var prefix(default, null):String;
	public var files(default, null):Array<S3File>;
	public var directories(default, null):Array<S3Directory>;
}