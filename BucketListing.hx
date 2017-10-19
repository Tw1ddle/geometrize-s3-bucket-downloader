package;

import haxe.Http;
import haxe.xml.Parser;
import js.Browser;
import js.html.AnchorElement;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.TableCellElement;
import js.html.TableRowElement;
import js.html.Element;

// Represents metadata listing info for a file in an S3 bucket
typedef S3File = {
	fileName:String,
	lastModified:String,
	size:String
}

// Represents metadata listing info for a directory in an S3 bucket
typedef S3Directory = {
	prefix:String
};

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

/**
 * Populates a table with S3 bucket directory listings, presents a table that acts as a bucket file/subdirectory browser, with loading spinner and retry button
 */
class BucketListing {
	private var config:BucketConfig;
	
	private var navigationContainer:DivElement;
	private var listingTableContainer:DivElement;
	private var loadingSpinner:DivElement;
	private var refreshButton:ButtonElement;
	
	public function new(config:BucketConfig, navigationContainer:DivElement, listingTableContainer:DivElement, loadingSpinner:DivElement, refreshButton:ButtonElement) {
		this.config = config;
		
		this.navigationContainer = navigationContainer;
		this.listingTableContainer = listingTableContainer;
		this.loadingSpinner = loadingSpinner;
		this.refreshButton = refreshButton;
		
		this.refreshButton.onclick = function() {
			// Request the data again if the retry button gets pressed (retry button is hidden once this happens)
			requestData();
		};
	}
	
	/**
	 * Requests the directory listing data from Amazon S3 and manages the UI while it waits for a response.
	 */
	public function requestData():Void {
		// Make things look busy
		loadingSpinner.className = "spinner";
		listingTableContainer.style.display = "none";
		refreshButton.style.display = "none";
		
		var url:String = buildQueryUrl();
		
		var onGetFailed = function(errorMessage:String) {
			// Failed to fetch listing - so show the retry button and hide the rest
			refreshButton.style.display = "";
			refreshButton.innerText = errorMessage;
			loadingSpinner.className = "";
			listingTableContainer.style.display = "none";
		}

		var http = new Http(url);
		http.onData = function(data:String) {
			if (data == null || data.length == 0) {
				onGetFailed("Query failed, no data received. Click to retry...");
				return;
			}
			
			var xml:Xml = Parser.parse(data);
			var info = getInfoFromS3ListingData(xml);
			
			var nav:DivElement = buildNavigation(info);
			navigationContainer.innerHTML = '';
			navigationContainer.appendChild(nav);
			
			var table:DivElement = generateListingTable(info);
			listingTableContainer.innerHTML = '';
			listingTableContainer.appendChild(table);
			
			// Make the newly created table sortable
			Sortable.init();
			
			loadingSpinner.className = "";
			listingTableContainer.style.display = "";
			
			// Note single request caps out at MaxKeys item listings (~1000)
			// Could make further requests using continuation request and grow the table more (ignoring this for the time being)
		};
		http.onError = function(error:String) {
			onGetFailed("Query failed, received error:" + error);
		};
		http.onStatus = function (status:Int) {
		}
		http.request(false);
	}
	
	/**
	 * Parses the XML from the Amazon S3 GET Bucket (List Objects) Version 2 query response and returns easily-used info about the bucket contents.
	 * @param xml The XML response to parse.
	 * @return Easily-used info about the bucket contents.
	 */
	private function getInfoFromS3ListingData(xml:Xml):DirectoryInfo {
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
				
				var fileName:String = fileNode.elementsNamed("Key").next().firstChild().nodeValue;
				var lastModified:String = fileNode.elementsNamed("LastModified").next().firstChild().nodeValue;
				var sizeBytes:String = fileNode.elementsNamed("Size").next().firstChild().nodeValue;
				
				files.push({ fileName:fileName, lastModified: lastModified, size: sizeBytes });
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
	
	/**
	 * Builds the Amazon S3 GET Bucket (List Objects) Version 2 query URL, based on the current location being browsed in the bucket.
	 * @return A query URL for a GET operation, which can be used to request an XML response describing some or all of the objects in a bucket.
	 */
	private function buildQueryUrl():String {
		var url = config.BUCKET_URL + '?list-type=2&delimiter=/';
		// TODO
		return url;
	}
	
	/**
	 * Constructs a navigation element in style of classic server/file browser i.e: "root -> subfolder -> subsubfolder" with hyperlinks.
	 * @param info The directory listing info to use.
	 * @return An element containing a navigation element containing a chain of links that simplifies bucket navigation.
	 */
	private function buildNavigation(info:DirectoryInfo):DivElement {
		var navigation = Browser.document.createDivElement();
		
		var prefix = info.prefix;
		var p = Browser.document.createParagraphElement();
		
		var parts:Array<String> = prefix.split("/");
		
		var paragraphText:String = config.BUCKET_NAME + " > ";
		var i = 0;
		while (i < parts.length) {
			var anchor = Browser.document.createAnchorElement();
			anchor.href = "TODO";
			anchor.innerText = parts[i];
			paragraphText += anchor;
			
			if(i != parts.length - 1) {
				paragraphText += " > ";
			}
			i++;
		}
		p.innerHTML = paragraphText;
		
		navigation.appendChild(p);
		return navigation;
	}
	
	/**
	 * Generates a table containing the file and directory listing for the given S3 bucket "directory" info provided.
	 * @param info Info describing the files and subdirectories at a particular level in the bucket.
	 * @return An element containing a table containing a file and directory listing.
	 */
	private function generateListingTable(info:DirectoryInfo):DivElement {
		// Make the table header
		var makeHeader = function() {
			var header = Browser.document.createElement("thead");
			var row:TableRowElement = Browser.document.createTableRowElement();
			header.appendChild(row);
			
			var iconTypeCell:Element = cast Browser.document.createElement("th");
			iconTypeCell.setAttribute("data-sortable", "false");
			iconTypeCell.textContent = "";
			iconTypeCell.className = "bucket_listing_item_icon_header_cell";
			
			var nameCell:Element = cast Browser.document.createElement("th");
			nameCell.setAttribute("data-sorted", "true");
			nameCell.setAttribute("data-sorted-direction", "descending");
			nameCell.setAttribute("data-sortable-type", "alpha");
			nameCell.textContent = "Name";
			nameCell.className = "bucket_listing_item_name_header_cell";
			
			var modifiedDateCell:Element = cast Browser.document.createElement("th");
			modifiedDateCell.setAttribute("data-sortable-type", "date");
			modifiedDateCell.textContent = "Modified";
			modifiedDateCell.className = "bucket_listing_item_modified_date_header_cell";
			
			var sizeCell:Element = cast Browser.document.createElement("th");
			sizeCell.setAttribute("data-sortable-type", "numeric");
			sizeCell.textContent = "Size";
			sizeCell.className = "bucket_listing_item_size_header_cell";
			
			row.appendChild(iconTypeCell);
			row.appendChild(nameCell);
			row.appendChild(modifiedDateCell);
			row.appendChild(sizeCell);
			
			return header;
		};
		
		// Make a row for file entry
		var makeRowForFile = function(file:S3File) {
			var row = Browser.document.createTableRowElement();
			
			var iconTypeCell:TableCellElement = Browser.document.createTableCellElement();
			iconTypeCell.innerText = "🖹";
			iconTypeCell.className = "bucket_listing_file_icon_cell";
			
			var nameCell:TableCellElement = Browser.document.createTableCellElement();
			nameCell.className = "bucket_listing_file_name_cell";
			
			var fileLink:AnchorElement = Browser.document.createAnchorElement();
			fileLink.href = Browser.location.protocol + '//' + Browser.location.hostname + Browser.location.pathname + "?prefix=" + file.fileName;
			fileLink.textContent = file.fileName;
			nameCell.appendChild(fileLink);
			
			var modifiedDateCell:TableCellElement = Browser.document.createTableCellElement();
			modifiedDateCell.textContent = file.lastModified;
			modifiedDateCell.className = "bucket_listing_file_modified_date_cell";
			
			var sizeCell:TableCellElement = Browser.document.createTableCellElement();
			sizeCell.textContent = Util.formatBytes(Std.parseFloat(file.size), 2);
			sizeCell.className = "bucket_listing_file_size_cell";
			
			row.appendChild(iconTypeCell);
			row.appendChild(nameCell);
			row.appendChild(modifiedDateCell);
			row.appendChild(sizeCell);
			
			return row;
		};
		
		// Make a row for a directory entry
		var makeRowForDir = function(dir:S3Directory) {
			var row = Browser.document.createTableRowElement();
			
			var iconTypeCell:TableCellElement = Browser.document.createTableCellElement();
			iconTypeCell.innerText = "📁";
			iconTypeCell.className = "bucket_listing_dir_icon_cell";
			
			var nameCell:TableCellElement = Browser.document.createTableCellElement();
			nameCell.className = "bucket_listing_dir_name_cell";
			
			var dirLink:AnchorElement = Browser.document.createAnchorElement();
			dirLink.href = "TODO";
			dirLink.textContent = dir.prefix;
			nameCell.appendChild(dirLink);
			
			var modifiedDateCell:TableCellElement = Browser.document.createTableCellElement();
			modifiedDateCell.textContent = "-";
			modifiedDateCell.className = "bucket_listing_dir_modified_date_cell";
			
			var sizeCell:TableCellElement = Browser.document.createTableCellElement();
			sizeCell.textContent = "-";
			sizeCell.className = "bucket_listing_dir_size_cell";
			
			row.appendChild(iconTypeCell);
			row.appendChild(nameCell);
			row.appendChild(modifiedDateCell);
			row.appendChild(sizeCell);
			
			return row;
		}
		
		// Create the table, put it in a container, and populate it
		var container = Browser.document.createDivElement();
		container.className = "bucket_listing_table_container";
		
		var table = Browser.document.createTableElement();
		table.setAttribute("data-sortable", "");
		table.className = "bucket_listing_table";
		
		var tableBody = Browser.document.createElement("tbody");
		tableBody.className = "bucket_listing_table_body";
		
		table.appendChild(tableBody);
		container.appendChild(table);
		
		table.appendChild(makeHeader());
		for (dir in info.directories) {
			if (Lambda.has(config.EXCLUDE_DIRECTORIES, dir.prefix)) {
				continue;
			}
			tableBody.appendChild(makeRowForDir(dir));
		}
		for (file in info.files) {
			if (Lambda.has(config.EXCLUDE_FILES, file.fileName)) {
				continue;
			}
			tableBody.appendChild(makeRowForFile(file));
		}
		
		return container;
	}
}