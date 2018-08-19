//
// Copyright 2015 Backblaze Inc. All Rights Reserved.
//
// License https://www.backblaze.com/using_b2_code.html
//
// This file (and all other Swift source files in the Sources directory of this playground) will be precompiled into a framework which is automatically made available to MyPlayground.playground.
//
//
// 2018 - Michal Duda - updated to Swift 4.1.2
// 
//
import Foundation
import Cocoa

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
        if let jsonData = jsonStr.data(using: String.Encoding.utf8) {
            if let dict = (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)) as? NSDictionary {
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
        if let jsonData = jsonStr.data(using: String.Encoding.utf8) {
            if let dict = (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)) as? NSDictionary {
                if let token = dict["authorizationToken"] as? String {
                    self.accountAuthorizationToken = token
                }
            }
        }
    }
    public mutating func processGetUploadUrl(jsonStr: String) {
        if let jsonData = jsonStr.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
            if let dict = (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)) as? NSDictionary {
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
        if let jsonData = jsonStr.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
            if let dict = (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)) as? NSDictionary {
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
        
        if let jsonData = jsonStr.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
            if let dict = (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)) as? Dictionary<String, Any> {
                if let buckets = dict["buckets"] as? [[String: Any]] {
                    for bucket in buckets {
                        if let bucketNameStr = bucket["bucketName"], ((bucketNameStr as AnyObject).caseInsensitiveCompare(searchBucketName) == ComparisonResult.orderedSame)   {
                            bucketInfo.bucketId = bucket["bucketId"]! as! String
                            bucketInfo.bucketName = bucket["bucketName"]! as! String
                            bucketInfo.bucketType = bucket["bucketType"]! as! String
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
        if let jsonData = jsonStr.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
            if let dict = (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)) as? NSDictionary {
                if let fileIdFromDict = dict["fileId"] as? String {
                    fileId = fileIdFromDict
                }
            }
        }
        return fileId
    }
    
    public func findFirstFileIdForName(searchFileName: String, jsonStr: String) -> String {
        var fileId = ""
        if let jsonData = jsonStr.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
            if let dict = (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)) as? Dictionary<String, Any> {
                if let files = dict["files"] as? [[String: Any]] {
                    for file in files {
                        if let fileName = file["fileName"], ((fileName as AnyObject).caseInsensitiveCompare(searchFileName) == ComparisonResult.orderedSame)   {
                            fileId = file["fileId"]! as! String
                        }
                    }
                }
            }
        }
        return fileId
    }

}

private func executeRequest(request: URLRequest, withSessionConfig sessionConfig: URLSessionConfiguration?) -> Data? {
    let session: URLSession
    if (sessionConfig != nil) {
        session = URLSession(configuration: sessionConfig!)
    } else {
        session = URLSession.shared
    }
    var requestData: Data?
    let task = session.dataTask(with: request as URLRequest, completionHandler:{ (data: Data?, response: URLResponse?, error: Error?) -> Void in
        if error != nil {
            print("error: \(error!.localizedDescription): \(error!.localizedDescription)")
        }
        else if data != nil {
            requestData = data
        }
    })
    task.resume()
    // We need to sleep so that the task can finish.  It is a little
    // contrived I suppose.
    while (task.state != .completed && task.state != .canceling) {
        sleep(1)
    }
    return requestData
}

private func executeUploadRequest(request: URLRequest, uploadData: Data, withSessionConfig sessionConfig: URLSessionConfiguration?) -> Data? {
    let session: URLSession
    if (sessionConfig != nil) {
        session = URLSession(configuration: sessionConfig!)
    } else {
        session = URLSession.shared
    }
    var requestData: Data?
    let task = session.uploadTask(with: request, from: uploadData, completionHandler:{ (data: Data?, response: URLResponse?, error: Error?) -> Void in
        if error != nil {
            print("error: \(error!.localizedDescription): \(error!.localizedDescription)")
        }
        else if data != nil {
            requestData = data
        }
    })
    task.resume()
    // We need to sleep so that the task can finish.  It is a little
    // contrived I suppose.
    while (task.state != .completed && task.state != .canceling) {
        sleep(1)
    }
    return requestData
}

public func b2AuthorizeAccount(config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = NSURL(string: "https://\(config.authServerStr)/b2api/v1/b2_authorize_account") {
        _ = URLSession.shared
        var request = URLRequest(url: url as URL)
        let authStr = "\(config.accountId!):\(config.applicationKey!)"
        let authData = authStr.data(using: String.Encoding.utf8, allowLossyConversion: false)
        let base64Str = authData!.base64EncodedString(options: Data.Base64EncodingOptions.lineLength76Characters)
        request.httpMethod = "GET"
        let authSessionConfig = URLSessionConfiguration.default
        authSessionConfig.httpAdditionalHeaders = ["Authorization":"Basic \(base64Str)"]
        if let requestData = executeRequest(request: request, withSessionConfig: authSessionConfig) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}

public func b2CreateBucket(bucketName: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        _ = URLSession.shared
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_create_bucket")!)
        request.httpMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["accountId":"\(config.accountId!)", "bucketName":"\(bucketName)", "bucketType":"allPrivate"], options: .prettyPrinted)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}

public func b2ListBuckets(config: B2StorageConfig) -> String  {
    var jsonStr = ""
    if let url = config.apiUrl {
        _ = URLSession.shared
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_list_buckets")!)
        request.httpMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["accountId":"\(config.accountId!)"], options: .prettyPrinted)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}

public func b2UpdateBucket(bucketId: String, bucketType: BucketType, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_update_bucket")!)
        request.httpMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.httpBody = "{\"bucketId\":\"\(bucketId)\", \"bucketType\":\"\(bucketType.rawValue)\"}".data(using: String.Encoding.utf8, allowLossyConversion: false)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}

public func b2GetUploadUrl(bucketId: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_get_upload_url")!)
        request.httpMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["bucketId":"\(bucketId)"], options: .prettyPrinted)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}

public func b2UploadFile(fileUrl: URL, fileName: String, contentType: String, sha1: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.uploadUrl {
        if let fileData = NSData(contentsOf: fileUrl) {
            var request = URLRequest(url: url as URL)
            request.httpMethod = "POST"
            request.addValue(config.uploadAuthorizationToken!, forHTTPHeaderField: "Authorization")
            request.addValue(fileName, forHTTPHeaderField: "X-Bz-File-Name")
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            request.addValue(sha1, forHTTPHeaderField: "X-Bz-Content-Sha1")
            if let requestData = executeUploadRequest(request: request, uploadData: fileData as Data, withSessionConfig: nil) {
                jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
            }
        }
    }
    return jsonStr
}

public func b2DownloadFileById(fileId: String, config: B2StorageConfig) -> Data? {
    var downloadedData: Data? = nil
    if let url = config.downloadUrl {
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_download_file_by_id")!)
        request.httpMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["fileId":"\(fileId)"], options: .prettyPrinted)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            downloadedData = requestData
        }
    }
    return downloadedData
}

public func b2DownloadFileByIdEx(fileId: String, config: B2StorageConfig) -> Data? {
    var downloadedData: Data? = nil
    if let url = config.downloadUrl {
        if let urlComponents = NSURLComponents(string: "\(url.absoluteString)/b2api/v1/b2_download_file_by_id") {
            urlComponents.query = "fileId=\(fileId)"
            var request = URLRequest(url: urlComponents.url!)
            request.httpMethod = "GET"
            request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
            if let requestData = executeRequest(request: request, withSessionConfig: nil) {
                downloadedData = requestData
            }
        }
    }
    return downloadedData
}

public func b2ListFileNames(bucketId: String, startFileName: String?, maxFileCount: Int, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_list_file_names")!)
        request.httpMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        var params = "{\"bucketId\":\"\(bucketId)\""
        if let startFileStr = startFileName {
            params += ",\"startFileName\":\"\(startFileStr)\""
        }
        if (maxFileCount > -1) {
            params += ",\"maxFileCount\":" + String(maxFileCount)
        }
        params += "}"
        request.httpBody = params.data(using: String.Encoding.utf8, allowLossyConversion: false)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}

public func b2ListFileVersions(bucketId: String, startFileName: String?, startFileId: String?, maxFileCount: Int, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_list_file_versions")!)
        request.httpMethod = "POST"
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
        request.httpBody = params.data(using: String.Encoding.utf8, allowLossyConversion: false)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}

public func b2GetFileInfo(fileId: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_get_file_info")!)
        request.httpMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.httpBody = "{\"fileId\":\"\(fileId)\"}".data(using: String.Encoding.utf8, allowLossyConversion: false)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}

public func b2DeleteFileVersion(fileId: String, fileName: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_delete_file_version")!)
        request.httpMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.httpBody = "{\"fileName\":\"\(fileName)\",\"fileId\":\"\(fileId)\"}".data(using: String.Encoding.utf8, allowLossyConversion: false)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}

public func b2HideFile(bucketId: String, fileName: String, config: B2StorageConfig) -> String {
    var jsonStr = ""
    if let url = config.apiUrl {
        var request = URLRequest(url: url.appendingPathComponent("/b2api/v1/b2_hide_file")!)
        request.httpMethod = "POST"
        request.addValue(config.accountAuthorizationToken!, forHTTPHeaderField: "Authorization")
        request.httpBody = "{\"fileName\":\"\(fileName)\",\"bucketId\":\"\(bucketId)\"}".data(using: String.Encoding.utf8, allowLossyConversion: false)
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        }
    }
    return jsonStr
}
