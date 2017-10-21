package;

import js.Browser;
import js.html.ButtonElement;
import js.html.DivElement;

// Automatic HTML code completion, point this at your HTML
#if geometrize_installer
@:build(CodeCompletion.buildLocalFile("bin/geometrize_installer/index.html"))
#end
#if geometrize_lib_example
@:build(CodeCompletion.buildLocalFile("bin/geometrize_lib_example/index.html"))
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
		var config = new BucketConfig("https://geometrize-installer-bucket.s3.amazonaws.com/", ["index.html", "s3-bucket-downloader.min.js", "style.css", "sortable.min.js", "favicon.png"], []);
		#end
		#if geometrize_lib_example
		var config = new BucketConfig("https://geometrize-lib-example-bucket.s3.amazonaws.com/", ["index.html", "s3-bucket-downloader.min.js", "style.css", "sortable.min.js", "favicon.png"], []);
		#end
		#if minimal_example
		var config = new BucketConfig("https://minimal-example-bucket.s3.amazonaws.com/", ["index.html", "s3-bucket-downloader.min.js"], []);
		#end
		
		// Create entity that populates the bucket, drives the listing table, loading spinner and retry button
		var bucket:BucketListing = new BucketListing(config, navigation, listing, loadingSpinner, retryButton);
		
		// Start by requesting the directory listing for the root/top level of the bucket
		bucket.requestData(bucket.getQueryUrlForRootDirectory());
	}
}