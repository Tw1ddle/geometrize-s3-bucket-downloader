package util;

// Represents metadata listing info for a file in an S3 bucket
typedef S3File = {
	filePath:String,
	lastModified:String,
	size:String
}