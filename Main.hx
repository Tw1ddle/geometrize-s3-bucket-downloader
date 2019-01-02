package;

import haxe.Http;
import haxe.xml.Parser;
import js.Browser;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.URL;

using StringTools;

// Automatic HTML code completion, point this at your HTML
#if geometrize_installer
@:build(CodeCompletion.buildLocalFile("bin/geometrize_installer/index.html"))
#end
#if geometrize_lib_example
@:build(CodeCompletion.buildLocalFile("bin/geometrize_lib_example/index.html"))
#end
#if dataslinger_example
@:build(CodeCompletion.buildLocalFile("bin/dataslinger_example/index.html"))
#end
#if minimal_example
@:build(CodeCompletion.buildLocalFile("bin/minimal_example/index.html"))
#end
@:keep
class ID {}

/**
 * Code that creates nice directory listings/download pages for Amazon S3 buckets - compiling to only JavaScript and HTML.
 * @author Sam Twidale (http://www.geometrize.co.uk/)
 */
class Main {
	// References to the HTML page elements
	private static inline function getElement(id:String):Dynamic {
		return Browser.document.getElementById(id);
	}
	private static var navigation:DivElement = getElement(ID.bucket_navigation); // The container that will hold the navigation chain from the root of the bucket i.e. "root->folder->subfolder"
	private static var listing:DivElement = getElement(ID.bucket_listing); // The container that will hold the table containing the actual bucket listing of files/directories etc
	private static var loadingSpinner:DivElement = getElement(ID.bucket_loadingspinner); // The container for the loading spinner
	private static var retryButton:ButtonElement = getElement(ID.bucket_retrybutton); // The container for the retry button
	
	private static function main():Void {
		var main = new Main();
	}

	private inline function new() {
		Browser.window.onload = onWindowLoaded;
	}

	private inline function onWindowLoaded():Void {
		init();
	}

	private inline function init():Void {
		// Setup the custom configurations for different build targets/S3 buckets
		#if geometrize_installer
		var config = new BucketConfig("https://geometrize-installer-bucket.s3.amazonaws.com/", ["index.html", "s3-bucket-downloader.js", "s3-bucket-downloader.min.js", "style.css", "sortable.min.js", "favicon.png"], []);
		#end
		#if geometrize_lib_example
		var config = new BucketConfig("https://geometrize-lib-example-bucket.s3.amazonaws.com/", ["index.html", "s3-bucket-downloader.js", "s3-bucket-downloader.min.js", "style.css", "sortable.min.js", "favicon.png"], []);
		#end
		#if dataslinger_example
		var config = new BucketConfig("https://dataslinger-bucket.s3.amazonaws.com/", ["index.html", "s3-bucket-downloader.js", "s3-bucket-downloader.min.js", "style.css", "sortable.min.js", "favicon.png"], []);
		#end
		#if minimal_example
		var config = new BucketConfig("https://minimal-example-bucket.s3.amazonaws.com/", ["index.html", "s3-bucket-downloader.js", "s3-bucket-downloader.min.js"], []);
		#end
		
		var url = new URL(Browser.window.location.href);
		var breadCrumb = url.searchParams.get("breadcrumb");
		var downloadLatest = url.searchParams.get("dl_latest");
		
		// Create entity that populates the bucket, drives the listing table, loading spinner and retry button
		var bucket:BucketListing = new BucketListing(config, navigation, listing, loadingSpinner, retryButton);
		
		var queryUrl = bucket.getQueryUrlForRootDirectory();
		
		// If there is a breadcrumb in the link, use it to set the initial directory
		if (breadCrumb != null && breadCrumb.length != 0) {
			queryUrl += ("&prefix=" + breadCrumb);
		}
		
		// If the download latest flag is set, set a callback to download the latest file in the directory - when the request completes
		var doDownload = null;
		if (downloadLatest != null) {
			doDownload = function(info:DirectoryInfo) {
				var files = info.files;
				if (files.length == 0) {
					return;
				}
				
				// Sort newest-oldest
				files.sort(function(first:S3File, second:S3File):Int {
				    var a = first.lastModified;
					var b = second.lastModified;
					if (a > b) {
						return -1;
					}
					if (a < b) {
						return 1;
					}
					
					return 0;
				});
				
				// Hacky code to work around files with name __latest used to mark builds
				// I want to use for CI testing for some configurations
				var newestFile:S3File = files[0].filePath.endsWith("__latest") ? files[1] : files[0];
				
				var downloadHref = bucket.makeHrefForFile(newestFile.filePath);
				Browser.window.location.href = downloadHref;
			}
		}
		
		// Start by requesting the directory listing
		bucket.requestData(queryUrl, doDownload, doDownload != null);
	}
	
	/**
	 * Parses the XML from the Amazon S3 GET Bucket (List Objects) Version 2 query response and returns easily-used info about the bucket contents.
	 * @param xml The XML response to parse.
	 * @return Easily-used info about the bucket contents.
	 */
	public static function getInfoFromS3ListingData(xml:Xml):DirectoryInfo {
		var files:Array<S3File> = [];
		var dirs:Array<S3Directory> = [];
		var prefix:String = "";
		
		var resultNodes = xml.elementsNamed("ListBucketResult");
		while (resultNodes.hasNext()) {
			var result = resultNodes.next();
			
			var prefixNodes = result.elementsNamed("Prefix");
			while (prefixNodes.hasNext()) {
				var prefixNode = prefixNodes.next();
				
				prefix = prefixNode.firstChild().nodeValue;
			}
			
			var fileNodes = result.elementsNamed("Contents");
			while (fileNodes.hasNext()) {
				var fileNode = fileNodes.next();
				
				var filePath:String = fileNode.elementsNamed("Key").next().firstChild().nodeValue;
				var lastModified:String = fileNode.elementsNamed("LastModified").next().firstChild().nodeValue;
				var sizeBytes:String = fileNode.elementsNamed("Size").next().firstChild().nodeValue;
				
				files.push({ filePath:filePath, lastModified: lastModified, size: sizeBytes });
			}
			
			var directoryNodes = result.elementsNamed("CommonPrefixes");
			while (directoryNodes.hasNext()) {
				var directoryNode = directoryNodes.next();
				
				var prefix:String = directoryNode.elementsNamed("Prefix").next().firstChild().nodeValue;
				
				dirs.push({ prefix: prefix });
			}
		}
		
		return new DirectoryInfo(prefix, files, dirs);
	}
	
	public function requestData(bucketRequestUrl:String):Void {
		var onGetFailed = function(errorMessage:String) {

		}
		
		var http = new Http(bucketRequestUrl);
		http.onData = function(data:String) {
			if (data == null || data.length == 0) {
				onGetFailed("Query failed, no data received. Click to retry...");
				return;
			}
			
			var xml:Xml = Parser.parse(data);
			var info = Main.getInfoFromS3ListingData(xml);
			var files = info.files;
			
			if (files == null) {
				return;
			}
			
			// Note single request caps out at MaxKeys item listings (~1000)
		};
		http.onError = function(error:String) {
			onGetFailed("Query failed, encountered error:" + error);
		};
		http.onStatus = function (status:Int) {
		}
		http.request(false);
	}
}