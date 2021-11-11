# S3 Bucket Browser

[![License](https://img.shields.io/:license-mit-blue.svg?style=flat-square)](https://github.com/Tw1ddle/geometrize-s3-bucket-downloader/blob/master/LICENSE)
[![Travis S3 Bucket Downloader Build Status](https://img.shields.io/travis/Tw1ddle/geometrize-s3-bucket-downloader.svg?style=flat-square)](https://travis-ci.org/Tw1ddle/geometrize-s3-bucket-downloader)

Haxe code that creates navigable listings of S3 buckets. View a production bucket [here](https://s3.amazonaws.com/geometrize-installer-bucket/index.html), or a minimal unstyled example bucket [here](https://s3.amazonaws.com/minimal-example-bucket/index.html).

Made for providing access to installers for [Geometrize](https://www.geometrize.co.uk/), an app for recreating images with geometric primitives.

## How It Works
The generated Javascript requests bucket listings using the Amazon GET Bucket (List Objects) Version 2 API operation, parses the XML response to get a list of browsable files and directories, and simulates a file browser via a table on a webpage.

## Screenshots

Styled production example:

[![Styled S3 downloader example for Geometrize](https://github.com/Tw1ddle/geometrize-s3-bucket-downloader/blob/master/screenshots/s3_downloader_styled_for_geometrize.png?raw=true "Styled S3 downloader example for Geometrize")](https://s3.amazonaws.com/geometrize-installer-bucket/index.html)

Minimal unstyled example:

[![Minimal unstyled S3 downloader example](https://github.com/Tw1ddle/geometrize-s3-bucket-downloader/blob/master/screenshots/s3_downloader_unstyled.png?raw=true "Minimal unstyled S3 downloader example")](https://s3.amazonaws.com/minimal-example-bucket/index.html)

## Notes
 * Got an idea or suggestion? Open an issue on GitHub, or send Sam a message on [Twitter](https://twitter.com/Sam_Twidale).
 * Inspired by [S3-bucket-listing](https://github.com/rufuspollock/s3-bucket-listing) by Rufus Pollock.
 * Uses [sortable](https://github.com/HubSpot/sortable) to make the table of downloads sortable.