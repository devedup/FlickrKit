//
//  FKFlickrPandaGetPhotos.h
//  FlickrKit
//
//  Generated by FKAPIBuilder.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved. http://www.devedup.com
//
//  DO NOT MODIFY THIS FILE - IT IS MACHINE GENERATED


#import "FKFlickrAPIMethod.h"

typedef NS_ENUM(NSInteger, FKFlickrPandaGetPhotosError) {
	FKFlickrPandaGetPhotosError_RequiredParameterMissing = 1,		 /* One or more required parameters was not included with your request. */
	FKFlickrPandaGetPhotosError_UnknownPanda = 2,		 /* You requested a panda we haven't met yet. */
	FKFlickrPandaGetPhotosError_InvalidAPIKey = 100,		 /* The API key passed was not valid or has expired. */
	FKFlickrPandaGetPhotosError_ServiceCurrentlyUnavailable = 105,		 /* The requested service is temporarily unavailable. */
	FKFlickrPandaGetPhotosError_WriteOperationFailed = 106,		 /* The requested operation failed due to a temporary issue. */
	FKFlickrPandaGetPhotosError_FormatXXXNotFound = 111,		 /* The requested response format was not found. */
	FKFlickrPandaGetPhotosError_MethodXXXNotFound = 112,		 /* The requested method was not found. */
	FKFlickrPandaGetPhotosError_InvalidSOAPEnvelope = 114,		 /* The SOAP envelope send in the request could not be parsed. */
	FKFlickrPandaGetPhotosError_InvalidXMLRPCMethodCall = 115,		 /* The XML-RPC request document could not be parsed. */
	FKFlickrPandaGetPhotosError_BadURLFound = 116,		 /* One or more arguments contained a URL that has been used for abuse on Flickr. */

};

/*

Ask the <a href="http://www.flickr.com/explore/panda">Flickr Pandas</a> for a list of recent public (and "safe") photos.
<br/><br/>
More information about the pandas can be found on the <a href="http://code.flickr.com/blog/2009/03/03/panda-tuesday-the-history-of-the-panda-new-apis-explore-and-you/">dev blog</a>.

When calling this API method please ensure that your code uses the <strong>lastupdate</strong> and <strong>interval</strong> attributes to determine when to request new photos. <em>lastupdate</em> is a Unix timestamp indicating when the list of photos was generated and <em>interval</em> is the number of seconds to wait before polling the Flickr API again.

Response:

<photos interval="60000" lastupdate="1235765058272" total="120" panda="ling ling">
    <photo title="Shorebirds at Pillar Point" id="3313428913" secret="2cd3cb44cb"
        server="3609" farm="4" owner="72442527@N00" ownername="Pat Ulrich"/>
    <photo title="Battle of the sky" id="3313713993" secret="3f7f51500f"
        server="3382" farm="4" owner="10459691@N05" ownername="Sven Ericsson"/>
    <!-- and so on -->
</photos>

*/
@interface FKFlickrPandaGetPhotos : NSObject <FKFlickrAPIMethod>

/* The name of the panda to ask for photos from. There are currently three pandas named:<br /><br />

<ul>
<li><strong><a href="http://flickr.com/photos/ucumari/126073203/">ling ling</a></strong></li>
<li><strong><a href="http://flickr.com/photos/lynnehicks/136407353">hsing hsing</a></strong></li>
<li><strong><a href="http://flickr.com/photos/perfectpandas/1597067182/">wang wang</a></strong></li>
</ul>

<br />You can fetch a list of all the current pandas using the <a href="/services/api/flickr.panda.getList.html">flickr.panda.getList</a> API method. */
@property (nonatomic, copy) NSString *panda_name; /* (Required) */

/* A comma-delimited list of extra information to fetch for each returned record. Currently supported fields are: <code>description</code>, <code>license</code>, <code>date_upload</code>, <code>date_taken</code>, <code>owner_name</code>, <code>icon_server</code>, <code>original_format</code>, <code>last_update</code>, <code>geo</code>, <code>tags</code>, <code>machine_tags</code>, <code>o_dims</code>, <code>views</code>, <code>media</code>, <code>path_alias</code>, <code>url_sq</code>, <code>url_t</code>, <code>url_s</code>, <code>url_q</code>, <code>url_m</code>, <code>url_n</code>, <code>url_z</code>, <code>url_c</code>, <code>url_l</code>, <code>url_o</code> */
@property (nonatomic, copy) NSString *extras;

/* Number of photos to return per page. If this argument is omitted, it defaults to 100. The maximum allowed value is 500. */
@property (nonatomic, copy) NSString *per_page;

/* The page of results to return. If this argument is omitted, it defaults to 1. */
@property (nonatomic, copy) NSString *page;


@end
