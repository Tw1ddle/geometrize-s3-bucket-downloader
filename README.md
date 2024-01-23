# S3 Bucket Browser

[![License](https://img.shields.io/:license-mit-blue.svg?style=flat-square)](https://github.com/Tw1ddle/geometrize-s3-bucket-downloader/blob/master/LICENSE)

Haxe code that creates navigable listings of S3 buckets. I am no longering maintain this. I used it for hosting installers for [Geometrize](https://www.geometrize.co.uk/), an app for recreating images with geometric primitives, but now I upload builds directly to GitHub instead.

## How It Works
The generated Javascript requests bucket listings using the Amazon GET Bucket (List Objects) Version 2 API operation, parses the XML response to get a list of browsable files and directories, and simulates a file browser via a table on a webpage.

## Build
Open the project folder in VSCode, or build the desired project from the command line:

```
haxe dataslinger_example.hxml
haxe geometrize_installer.hxml
haxe geometrize_lib_example.hxml
haxe minimal_example.hxml
```

## Screenshots

Styled production example:

![Styled S3 downloader example for Geometrize](https://github.com/Tw1ddle/geometrize-s3-bucket-downloader/blob/master/screenshots/s3_downloader_styled_for_geometrize.png?raw=true "Styled S3 downloader example for Geometrize")

Minimal unstyled example:

![Minimal unstyled S3 downloader example](https://github.com/Tw1ddle/geometrize-s3-bucket-downloader/blob/master/screenshots/s3_downloader_unstyled.png?raw=true "Minimal unstyled S3 downloader example")

## Notes
 * Got an idea or suggestion? Open an issue on GitHub, or send Sam a message on [Twitter](https://twitter.com/Sam_Twidale).
 * Inspired by [S3-bucket-listing](https://github.com/rufuspollock/s3-bucket-listing) by Rufus Pollock.
 * Uses [sortable](https://github.com/HubSpot/sortable) to make the table of downloads sortable.
