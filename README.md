# S3 Bucket Browser

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](https://github.com/Tw1ddle/geometrize-s3-bucket-downloader/blob/master/LICENSE)
[![Travis S3 Bucket Downloader Build Status](https://img.shields.io/travis/Tw1ddle/geometrize-s3-bucket-downloader.svg?style=flat-square)](https://travis-ci.org/Tw1ddle/geometrize-s3-bucket-downloader)

Haxe code that creates navigable listings of S3 buckets. View a minimal example bucket [here](https://s3.amazonaws.com/minimal-example-bucket/index.html).

Made for providing access to installers for [Geometrize](http://www.geometrize.co.uk/), an app for recreating images with geometric primitives.

## How It Works
The script requests bucket listings using the Amazon GET Bucket (List Objects) Version 2 API operation, parses the XML response, and simulates a file browser via a table on a webpage.

## Screenshots

Coming soon.

## Notes
 * Got an idea or suggestion? Open an issue on GitHub, or send Sam a message on [Twitter](https://twitter.com/Sam_Twidale).
 * Inspired by [S3-bucket-listing](https://github.com/rufuspollock/s3-bucket-listing) by Rufus Pollock.
 * Uses [sortable](https://github.com/HubSpot/sortable) to make the table of downloads sortable.