package;

import haxe.Http;
import haxe.io.Path;
import haxe.xml.Parser;
import js.Browser;
import js.html.AnchorElement;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.Element;
import js.html.TableCellElement;
import js.html.TableRowElement;

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
			requestData(getQueryUrlForRootDirectory()); // NOTE should really retry current directory not the base directory
		};
	}
	
	/**
	 * Requests the directory listing data from Amazon S3 and manages the UI while it waits for a response.
	 * onDirectoryInfoCreated callback triggers after the request completes.
	 * synchronous Whether the request is performed synchronously or asynchronously.
	 */
	public function requestData(bucketRequestUrl:String, onDirectoryInfoCreated:DirectoryInfo->Void = null, synchronous:Bool = false):Void {
		// Make things look busy
		loadingSpinner.className = "spinner";
		listingTableContainer.style.display = "none";
		refreshButton.style.display = "none";
		
		var onGetFailed = function(errorMessage:String) {
			// Failed to fetch listing - so show the retry button and hide the rest
			refreshButton.style.display = "";
			refreshButton.innerText = errorMessage;
			loadingSpinner.className = "";
			listingTableContainer.style.display = "none";
		}
		
		var http = new Http(bucketRequestUrl);
		http.onData = function(data:String) {
			if (data == null || data.length == 0) {
				onGetFailed("Query failed, no data received. Click to retry...");
				return;
			}
			
			var xml:Xml = Parser.parse(data);
			var info:DirectoryInfo = getInfoFromS3ListingData(xml);
			
			if (onDirectoryInfoCreated != null) {
				onDirectoryInfoCreated(info);
			}
			
			var nav:DivElement = buildNavigation(info);
			navigationContainer.innerHTML = '';
			navigationContainer.appendChild(nav);
			
			var table:DivElement = generateListingTable(info);
			listingTableContainer.innerHTML = '';
			listingTableContainer.appendChild(table);
			
			// Make the newly created table sortable
			#if !minimal_example // Minimal example table is not sortable
			Sortable.init();
			
			// Force sorting on the bucket listing item modified column, so newest items appear first
			// there should be a better way to do this, but I don't know what it is...
			Browser.document.getElementById("bucket_listing_item_modified_date_header_cell_id").click();
			Browser.document.getElementById("bucket_listing_item_modified_date_header_cell_id").click();
			#end
			
			loadingSpinner.className = "";
			listingTableContainer.style.display = "";
			
			// Note single request caps out at MaxKeys item listings (~1000)
			// Could make further requests using continuation request and grow the table more (ignoring this for the time being)
		};
		http.onError = function(error:String) {
			onGetFailed("Query failed, encountered error:" + error);
		};
		http.onStatus = function (status:Int) {
		}
		http.request(false);
	}
	
	/**
	 * Builds the Amazon S3 GET Bucket (List Objects) Version 2 query URL, based on the root of the bucket.
	 * @return A query URL for a GET operation, which can be used to request an XML response describing some or all of the objects in a bucket.
	 */
	public function getQueryUrlForRootDirectory():String {
		var baseUrl = config.bucketUrl + '?list-type=2' + '&delimiter=/';
		return baseUrl;
	}
	
	/**
	 * Builds the Amazon S3 GET Bucket (List Objects) Version 2 query URL for the given item in the bucket.
	 * @param itemPath The item within the bucket to create the query URL for e.g. "windows/". Must end with a forward slash if a directory.
	 * @return A query URL for a GET operation, which can be used to request an XML response describing some or all of the objects in a bucket.
	 */
	private function getQueryUrlForItem(itemPath:String):String {
		var url = getQueryUrlForRootDirectory();
		if (itemPath.length == 0) {
			return url;
		}
		
		url += '&prefix=' + StringTools.urlEncode(itemPath);
		return url;
	}
	
	/**
	 * Makes a link that downloads the given file when clicked.
	 * @param text The text to show on the link.
	 * @param filePath The path to the file.
	 * @return The new link element.
	 */
	private function makeAnchorLinkForFile(text:String, filePath:String):AnchorElement {
		var anchor = Browser.document.createAnchorElement();
		anchor.innerText = text;
		anchor.href = makeHrefForFile(filePath);
		anchor.download = Path.withoutDirectory(filePath);
		return anchor;
	}
	
	/**
	 * Makes a href for downloading the file at the given filepath.
	 * @param	filePath The path to the file.
	 * @return Href to the file, suitable for setting as href on anchor links etc.
	 */
	public function makeHrefForFile(filePath:String):String {
		return config.bucketUrl + StringTools.replace(StringTools.urlEncode(filePath), "%2F", "/"); // Avoid encoding forward slashes in file path, as it causes browsers to use the full path as the filename
	}
	
	/**
	 * Makes a button that navigates to the given directory when clicked.
	 * @param text The text to show on the button.
	 * @param directoryPath The path to the directory, must end with a "/".
	 * @return The new button element.
	 */
	private function makeButtonForDirectory(text:String, directoryPath:String):ButtonElement {
		var button = Browser.document.createButtonElement();
		button.innerText = text;
		button.onclick = function() {
			requestData(getQueryUrlForItem(directoryPath));
		}
		return button;
	}
	
	/**
	 * Builds the Amazon S3 href for a file within the bucket (for download-on-click type behavior).
	 * @param directoryPath The directory within the bucket to create the query URL for e.g. "windows/". Must end with a forward slash.
	 * @param fileName The name of the file within the directory.
	 * @return A URL pointing to the file in the bucket.
	 * @return A URL pointing to the file in the bucket.
	 */
	private function getUrlForFile(directoryPath:String, fileName:String):String {
		return getQueryUrlForItem(directoryPath);
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
	
	/**
	 * Constructs a navigation element in style of classic server/file browser i.e: "root >> subfolder >> subsubfolder" with hyperlinks.
	 * @param info The directory listing info to use.
	 * @return An element containing a navigation element containing a chain of links that simplifies bucket navigation.
	 */
	private function buildNavigation(info:DirectoryInfo):DivElement {
		var prefix = info.prefix;
		
		var navigation = Browser.document.createDivElement();
		
		var addButton = function(text:String, directoryPath:String):Void {
			var button = makeButtonForDirectory(text, directoryPath);
			button.className = "bucket_navigation_segment";
			navigation.appendChild(button);
		}
		
		var parts:Array<String> = prefix.length == 0 ? [""] : prefix.split("/");
		
		addButton("root/", "");
		
		var partsChain:String = "";
		var i = 0;
		while (i < parts.length - 1) {
			partsChain += parts[i] + "/";
			
			addButton(parts[i] + "/", partsChain);
			
			i++;
		}
		
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
			
			var nameCell:Element = cast Browser.document.createElement("th");
			nameCell.setAttribute("data-sortable-type", "alpha");
			nameCell.textContent = "Name";
			nameCell.className = "bucket_listing_item_name_header_cell";
			
			var modifiedDateCell:Element = cast Browser.document.createElement("th");
			modifiedDateCell.setAttribute("data-sortable-type", "date");
			modifiedDateCell.textContent = "Modified";
			modifiedDateCell.className = "bucket_listing_item_modified_date_header_cell";
			modifiedDateCell.id = "bucket_listing_item_modified_date_header_cell_id";
			
			var sizeCell:Element = cast Browser.document.createElement("th");
			sizeCell.setAttribute("data-sortable-type", "numeric");
			sizeCell.textContent = "Size";
			sizeCell.className = "bucket_listing_item_size_header_cell";
			
			row.appendChild(nameCell);
			row.appendChild(modifiedDateCell);
			row.appendChild(sizeCell);
			
			return header;
		};
		
		// Make a row for file entry
		var makeRowForFile = function(file:S3File) {
			var row = Browser.document.createTableRowElement();
			
			var nameCell:TableCellElement = Browser.document.createTableCellElement();
			nameCell.className = "bucket_listing_file_name_cell";
			
			var fileLink:AnchorElement = makeAnchorLinkForFile("🖹 " + Path.withoutDirectory(file.filePath), file.filePath);
			nameCell.appendChild(fileLink);
			
			var modifiedDateCell:TableCellElement = Browser.document.createTableCellElement();
			modifiedDateCell.textContent = StringTools.replace(file.lastModified, "T", " ");
			modifiedDateCell.className = "bucket_listing_file_modified_date_cell";
			
			var sizeCell:TableCellElement = Browser.document.createTableCellElement();
			sizeCell.textContent = Util.formatBytes(Std.parseFloat(file.size), 2);
			sizeCell.setAttribute("data-value", file.size);
			sizeCell.className = "bucket_listing_file_size_cell";
			
			row.appendChild(nameCell);
			row.appendChild(modifiedDateCell);
			row.appendChild(sizeCell);
			
			return row;
		};
		
		// Make a row for a directory entry
		var makeRowForDir = function(dir:S3Directory) {
			var row = Browser.document.createTableRowElement();
			
			var nameCell:TableCellElement = Browser.document.createTableCellElement();
			nameCell.className = "bucket_listing_dir_name_cell";
			
			var dirLink:ButtonElement = makeButtonForDirectory("📁 " + dir.prefix, dir.prefix);
			nameCell.appendChild(dirLink);
			
			var modifiedDateCell:TableCellElement = Browser.document.createTableCellElement();
			modifiedDateCell.textContent = "-";
			modifiedDateCell.className = "bucket_listing_dir_modified_date_cell";
			
			var sizeCell:TableCellElement = Browser.document.createTableCellElement();
			sizeCell.textContent = "-";
			sizeCell.className = "bucket_listing_dir_size_cell";
			
			row.appendChild(nameCell);
			row.appendChild(modifiedDateCell);
			row.appendChild(sizeCell);
			
			return row;
		};
		
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
			if (Lambda.has(config.excludeDirectories, dir.prefix)) {
				continue;
			}
			tableBody.appendChild(makeRowForDir(dir));
		}
		for (file in info.files) {
			if (Lambda.has(config.excludeFiles, file.filePath)) {
				continue;
			}
			if (Path.withoutDirectory(file.filePath).length == 0) {
				continue;
			}
			tableBody.appendChild(makeRowForFile(file));
		}
		
		return container;
	}
}