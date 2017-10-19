package;

import js.Browser;
import js.html.ButtonElement;
import js.html.DivElement;

// Automatic HTML code completion, point this at your HTML
@:build(CodeCompletion.buildLocalFile("bin/release/index.html"))
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
	private static var navigation:DivElement = getElement(ID.navigation);
	private static var listing:DivElement = getElement(ID.listing);
	private static var loadingSpinner:DivElement = getElement(ID.loadingspinner);
	private static var refreshButton:ButtonElement = getElement(ID.refreshbutton);
	
	// Entity that populates the bucket and drives the listing table, loading spinner and refresh button
	private var bucket:BucketListing = new BucketListing(new BucketConfig(), navigation, listing, loadingSpinner, refreshButton);
	
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
		bucket.requestData(bucket.getQueryUrlForRootDirectory());
	}
}