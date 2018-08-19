//
// Copyright 2015 Backblaze Inc. All Rights Reserved.
//
// License https://www.backblaze.com/using_b2_code.html
//

/*:
## Playground - noun: a place where people can play

This playground walks one through creating a B2 bucket, listing your buckets, uploading a file, and downloading a file.
*/


import Cocoa
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely()

//: Set your B2 account ID and application key. You can find this information on your accounts 

var config = B2StorageConfig()
config.accountId = nil // <YOUR B2 ACCOUNT ID>
config.applicationKey = nil // <YOUR B2 APPLICATION KEY>

/*:
### B2 Authorize Account
Before you can do anything with B2 Cloud Storage APIs you need to get an authorization token by calling [b2_authorize_account.](https://www.backblaze.com/b2/docs/b2_authorize_account.html)
*/
var authorizeJson: String? = nil
if (config.accountId != nil && config.applicationKey != nil) {
    authorizeJson = b2AuthorizeAccount(config)
}

/*:
A successful call to b2_authorize_account should return the B2 account JSON.
    
    {
        "accountId": "<YOUR B2 ACCOUNT ID>",
        "apiUrl": "https://api900.backblaze.com",
        "authorizationToken": "2_20150807002553_443e98bf57f978fa58c284f8_24d25d99772e3ba927778b39c9b0198f412d2163_acct",
        "downloadUrl": "https://f900.backblaze.com"
    }

*/
if let authorizeJsonStr = authorizeJson {
    config.processAuthorization(authorizeJsonStr)
}

/*:
### B2 Create Bucket
Before you upload any files you need to create a B2 bucket by calling [b2_create_bucket.](https://www.backblaze.com/b2/docs/b2_create_bucket.html)

NOTE: Choose your bucket own bucket name. B2 bucket names are globally unique.  Find out more about buckets [here.](https://www.backblaze.com/b2/docs/buckets.html)
*/
let yourBucketName = ""
var createBucketJson: String? = nil
if (!yourBucketName.isEmpty && config.accountAuthorizationToken != nil) {
    createBucketJson = b2CreateBucket(yourBucketName, config: config)
}

/*:
### B2 List Buckets
Now that you have a bucket you can list your buckets by calling [b2_list_buckets.](https://www.backblaze.com/b2/docs/b2_list_buckets.html)
*/
var listBucketsJson: String? = nil
if (!yourBucketName.isEmpty && createBucketJson != nil) {
    listBucketsJson = b2ListBuckets(config)
}

/*:
Here we parse the list of buckets looking for your bucket.
*/
var yourBucketInfoTuple: (bucketId: String, bucketName: String, bucketType: String)?
if (listBucketsJson != nil) {
    yourBucketInfoTuple = config.findBucketWithName(yourBucketName, jsonStr: listBucketsJson!)
}

/*:
### Get Upload URL
Before you upload a file you need to get an upload URL by calling [b2_get_upload_url.](https://www.backblaze.com/b2/docs/b2_get_upload_url.html)
*/
var yourUploadUrl: String? = nil
if let bucket = yourBucketInfoTuple {
    let getUploadUrlJson = b2GetUploadUrl(bucket.bucketId, config: config)
    config.processGetUploadUrl(getUploadUrlJson)
}

/*:
### Upload File
Now you can upload the file by calling [b2_upload_file.](https://www.backblaze.com/b2/docs/b2_upload_file.html)
*/
if (config.uploadUrl != nil) {
    let uploadJson = b2UploadFile(NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("yawning_cat", ofType: "jpg")!), fileName: "yawning_cat.jpg", contentType: "image/jpeg", sha1: "a01a21253a07fb08a354acd30f3a6f32abb76821", config: config)
}

/*:
### List File Names
The JSON returned from a successful call to b2_upload_file will have your files meta-data. You can learn more about B2 files [here.](https://www.backblaze.com/b2/docs/files.html)
*/
var fileId: String? = nil
if let bucket = yourBucketInfoTuple {
    let fileNames = b2ListFileNames(bucket.bucketId, startFileName: nil, maxFileCount: -1, config: config)
    fileId = config.findFirstFileIdForName("yawning_cat.jpg", jsonStr: fileNames)
}

/*: 
### Downloading Files
B2 has supports two APIs to download files: [b2_download_file_by_id](https://www.backblaze.com/b2/docs/b2_download_file_by_id.html) and [b2_download_file_by_name](https://www.backblaze.com/b2/docs/b2_download_file_by_name.html)
*/
if (fileId != nil) {
    let downloadFile = b2DownloadFileByIdEx(fileId!, config: config)
    let img = NSImage(data: downloadFile!)
    let imgView = NSImageView(frame:NSMakeRect(0, 0, 640, 640))
}

