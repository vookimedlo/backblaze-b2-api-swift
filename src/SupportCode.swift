//
// Copyright 2015 Backblaze Inc. All Rights Reserved.
//
// License https://www.backblaze.com/using_b2_code.html
//
// This file (and all other Swift source files in the Sources directory of this playground) will be precompiled into a framework which is automatically made available to MyPlayground.playground.
//
import Foundation
import Cocoa
import XCPlayground

public enum BucketType : String {
    case AllPublic = "allPublic", AllPrivate = "allPrivate"
}

public struct B2StorageConfig {
    public init() {} 
    public let authServerStr = "api.backblazeb2.com"
    public var emailAddress: String?
    public var accountId: String?
    public var applicationKey: String?
    public var apiUrl: NSURL?
    public var downloadUrl: NSURL?
    public var uploadUrl: NSURL?
    public var accountAuthorizationToken: String?
    public var uploadAuthorizationToken: String?
    public mutating func processAuthorization(jsonStr: String) {
        if let jsonData = jsonStr.dataUsingEncoding(NSUTF8StringEncoding) {
            if let dict = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers)) as? NSDictionary {
                if let downloadStr = dict["downloadUrl"] as? String {
                    self.downloadUrl = NSURL(string: downloadStr)
                }
                if let apiStr = dict["apiUrl"] as? String {
                    self.apiUrl = NSURL(string: apiStr)
                }
                if let authTokenStr = dict["authorizationToken"] as? String {
                    self.accountAuthorizationToken = authTokenStr
                }
            }
        }
    }
    public mutating func processBucketAuthorization(jsonStr: String) {
        if let jsonData = jsonStr.dataUsingEncoding(NSUTF8StringEncoding) {
            if let dict = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers)) as? NSDictionary {
                if let token = dict["authorizationToken"] as? String {
                    self.accountAuthorizationToken = token
                }
            }
        }
    }
    public mutating func processGetUploadUrl(jsonStr: String) {
        if let jsonData = jsonStr.dataUsingEncoding(NSUTF8StringEncoding) {
            if let dict = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers)) as? NSDictionary {
                if let uploadUrlStr = dict["uploadUrl"] as? String {
                    self.uploadUrl = NSURL(string: uploadUrlStr)
                }
                if let uploadAuthTokenStr = dict["authorizationToken"] as? String {
                    self.uploadAuthorizationToken = uploadAuthTokenStr
                }
            }
        }
    }
    public func firstBucketId(jsonStr: String) -> (bucketId: String, bucketName: String, bucketType: String) {
        var bucketInfo = (bucketId:"", bucketName:"", bucketType:"")
        if let jsonData = jsonStr.dataUsingEncoding(NSUTF8StringEncoding) {
            if let dict = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers)) as? NSDictionary {
                if let buckets = dict["buckets"] as? NSArray {
                    if let firstBucket = buckets[0] as? NSDictionary {
                        bucketInfo.bucketId = (firstBucket["bucketId"] as? String)!
                        bucketInfo.bucketName = (firstBucket["bucketName"] as? String)!
                        bucketInfo.bucketType = (firstBucket["bucketType"] as? String)!
                    }
                }
            }
        }
        return bucketInfo
    }
    public func findBucketWithName(searchBucketName: String, jsonStr: String) -> (bucketId: String, bucketName: String, bucketType: String) {
        var bucketInfo: (bucketId: String, bucketName: String, bucketType: String) = ("","","")
        if let jsonData = jsonStr.dataUsingEncoding(NSUTF8StringEncoding) {
            if let dict = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers)) as? NSDictionary {
                if let buckets = dict["buckets"] as? NSArray {
                    for bucket in buckets {
                        if let bucketNameStr = bucket["bucketName"] as? String where ((bucketNameStr as NSString).caseInsensitiveCompare(searchBucketName as String) == NSComparisonResult.OrderedSame)   {
                            bucketInfo.bucketId = (bucket["bucketId"] as? String)!
                            bucketInfo.bucketName = (bucket["bucketName"] as? String)!
                            bucketInfo.bucketType = (bucket["bucketType"] as? String)!
                            break
                        }
                    }
                }
            }
        }
        return bucketInfo
    }
    public func getFileId(jsonStr: String) -> String {
        var fileId = ""
        if let jsonData = jsonStr.dataUsingEncoding(NSUTF8StringEncoding){
            if let dict = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers)) as? NSDictionary {
                if let fileIdFromDict = dict["fileId"] as? String {
                    fileId = fileIdFromDict
                }
            }
        }
        return fileId
    }
    public func findFirstFileIdForName(searchFileName: String, jsonStr: String) -> String {
        var fileId = ""
        if let jsonData = jsonStr.dataUsingEncoding(NSUTF8StringEncoding){
            if let dict = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .MutableContainers)) as? NSDictionary {
                if let files = dict["files"] as? NSArray {
                    for file in files {
                        if let fileName = file["fileName"] as? String where ((fileName as NSString).caseInsensitiveCompare(searchFileName as String) == NSComparisonResult.OrderedSame)   {
                            fileId = (file["fileId"] as? String)!
                        }
                    }
                }
            }
        }
        return fileId
    }
}

public func executeRequest(request: NSMutableURLRequest, withSessionConfig sessionConfig: NSURLSessionConfiguration?) -> NSData? {
    let session: NSURLSession
    if (sessionConfig != nil) {
        session = NSURLSession(configuration: sessionConfig!)
    } else {
        session = NSURLSession.sharedSession()
    }    
    var requestData: NSData?
    let task = session.dataTaskWithRequest(request, completionHandler:{ (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
        if error != nil {
            print("error: \(error!.localizedDescription): \(error!.userInfo)")
        }
        else if data != nil {
            requestData = data
        }
    })
    task.resume()
    // We need to sleep so that the task can finish.  It is a little
    // contrived I suppose.
    while (task.state != .Completed && task.state != .Canceling) {
        sleep(1)
    }
    return requestData
}

public func executeUploadRequest(request: NSMutableURLRequest, uploadData: NSData, withSessionConfig sessionConfig: NSURLSessionConfiguration?) -> NSData? {
    let session: NSURLSession
    if (sessionConfig != nil) {
        session = NSURLSession(configuration: sessionConfig!)
    } else {
        session = NSURLSession.sharedSession()
    }
    var requestData: NSData?
    let task = session.uploadTaskWithRequest(request, fromData: uploadData, completionHandler:{ (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
        if error != nil {
            print("error: \(error!.localizedDescription): \(error!.userInfo)")
        }
        else if data != nil {
            requestData = data
        }
    })
    task.resume()
    // We need to sleep so that the task can finish.  It is a little
    // contrived I suppose.
    while (task.state != .Completed && task.state != .Canceling) {
        sleep(1)
    }
    return requestData
}

public func b2AuthorizeAccount(config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = NSURL(string: "https://\(config.authServerStr)/b2api/v1/b2_authorize_account") {
        _ = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url)
        let authStr = "\(config.accountId!):\(config.applicationKey!)"
        let authData = authStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let base64Str = authData!.base64EncodedStringWithOptions(.Encoding76CharacterLineLength)
        request.HTTPMethod = "GET"
        let authSessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        authSessionConfig.HTTPAdditionalHeaders = ["Authorization":"Basic \(base64Str)"]
        if let requestData = executeRequest(request, withSessionConfig: authSessionConfig) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}

public func b2CreateBucket(bucketName: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        _ = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_create_bucket"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(["accountId":"\(config.accountId!)", "bucketName":"\(bucketName)", "bucketType":"allPrivate"], options: .PrettyPrinted)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}

public func b2ListBuckets(config: B2StorageConfig) -> String  {
    var jsonStr = ""
    if let url = config.apiUrl {        
        _ = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_list_buckets"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(["accountId":"\(config.accountId!)"], options: .PrettyPrinted)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}

public func b2UpdateBucket(bucketId: String, bucketType: BucketType, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_update_bucket"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.HTTPBody = "{\"bucketId\":\"\(bucketId)\", \"bucketType\":\"\(bucketType.rawValue)\"}".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}

public func b2GetUploadUrl(bucketId: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_get_upload_url"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(["bucketId":"\(bucketId)"], options: .PrettyPrinted)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}

public func b2UploadFile(fileUrl: NSURL, fileName: String, contentType: String, sha1: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.uploadUrl {
        if let fileData = NSData(contentsOfURL: fileUrl) {
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.addValue(config.uploadAuthorizationToken!, forHTTPHeaderField: "Authorization")
            request.addValue(fileName, forHTTPHeaderField: "X-Bz-File-Name")
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            request.addValue(sha1, forHTTPHeaderField: "X-Bz-Content-Sha1")
            if let requestData = executeUploadRequest(request, uploadData: fileData, withSessionConfig: nil) {
                jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
            }
        }
    }
    return jsonStr
}

public func b2DownloadFileById(fileId: String, config: B2StorageConfig) -> NSData? {
    var downloadedData: NSData? = nil
    if let url = config.downloadUrl {
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_download_file_by_id"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(["fileId":"\(fileId)"], options: .PrettyPrinted)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            downloadedData = requestData
        }
    }
    return downloadedData
}

public func b2DownloadFileByIdEx(fileId: String, config: B2StorageConfig) -> NSData? {
    var downloadedData: NSData? = nil
    if let url = config.downloadUrl {
        if let urlComponents = NSURLComponents(string: "\(url.absoluteString)/b2api/v1/b2_download_file_by_id") {
            urlComponents.query = "fileId=\(fileId)"
            let request = NSMutableURLRequest(URL: urlComponents.URL!)
            request.HTTPMethod = "GET"
            request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
            if let requestData = executeRequest(request, withSessionConfig: nil) {
                downloadedData = requestData
            }
        }
    }
    return downloadedData
}

public func b2ListFileNames(bucketId: String, startFileName: String?, maxFileCount: Int, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_list_file_names"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        var params = "{\"bucketId\":\"\(bucketId)\""
        if let startFileStr = startFileName {
            params += ",\"startFileName\":\"\(startFileStr)\""
        }
        if (maxFileCount > -1) {
            params += ",\"maxFileCount\":" + String(maxFileCount)
        }
        params += "}"
        request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}

public func b2ListFileVersions(bucketId: String, startFileName: String?, startFileId: String?, maxFileCount: Int, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_list_file_versions"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        var params = "{\"bucketId\":\"\(bucketId)\""
        if let startFileNameStr = startFileName {
            params += ",\"startFileName\":\"\(startFileNameStr)\""
        }
        if let startFileIdStr = startFileId {
            params += ",\"startFileId\":\"\(startFileIdStr)\""
        }
        if (maxFileCount > -1) {
            params += ",\"maxFileCount\":" + String(maxFileCount)
        }
        params += "}"
        request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}

public func b2GetFileInfo(fileId: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_get_file_info"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.HTTPBody = "{\"fileId\":\"\(fileId)\"}".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}

public func b2DeleteFileVersion(fileId: String, fileName: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_delete_file_version"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.HTTPBody = "{\"fileName\":\"\(fileName)\",\"fileId\":\"\(fileId)\"}".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}

public func b2HideFile(bucketId: String, fileName: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        let request = NSMutableURLRequest(URL: url.URLByAppendingPathComponent("/b2api/v1/b2_hide_file"))
        request.HTTPMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.HTTPBody = "{\"fileName\":\"\(fileName)\",\"bucketId\":\"\(bucketId)\"}".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        if let requestData = executeRequest(request, withSessionConfig: nil) {
            jsonStr = NSString(data: requestData, encoding: NSUTF8StringEncoding) as String!
        }
    }
    return jsonStr
}
