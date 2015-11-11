//
//  Session+subreddits.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
 The type of voting direction.
 */
public enum SubredditAbout : String {
    case Banned             = "banned"
    case Muted              = "muted"
    case Wikibanned         = "wikibanned"
    case Contributors       = "contributors"
    case Wikicontributors   = "wikicontributors"
    case Moderators         = "moderators"
}

extension Session {
    /**
     This endpoint is a listing.
    */
    public func about(subreddit:Subreddit?, paginator:Paginator?, aboutWhere:SubredditAbout, user:String = "", count:Int = 0, limit:Int = 25, completion:(Result<Listing>) -> Void) throws -> NSURLSessionDataTask {
        let paginator = paginator ?? Paginator()
        let parameter = paginator.addParametersToDictionary([
            "count"    : "\(count)",
            "limit"    : "\(limit)",
            "show"     : "all",
//          "sr_detail": "true",
//          "user"     :"username"
            ])
        var path = ""
        if let subreddit = subreddit { path = "/r/\(subreddit.displayName)/about/\(aboutWhere.rawValue)" }
        else { path = "/about/\(aboutWhere.rawValue)" }
        print(path)
        
        guard let request:NSMutableURLRequest = NSMutableURLRequest.mutableOAuthRequestWithBaseURL(baseURL, path:path, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.URLError.error }
        let task = URLSession.dataTaskWithRequest(request, completionHandler: { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            self.updateRateLimitWithURLResponse(response)
            let result = resultFromOptionalError(Response(data: data, urlResponse: response), optionalError:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Listing)
            completion(result)
        })
        task.resume()
        return task
    }
    
    /**
    Subscribe to or unsubscribe from a subreddit. The user must have access to the subreddit to be able to subscribe to it.
    
    - parameter subreddit: Subreddit obect to be subscribed/unsubscribed
    - parameter subscribe: If you want to subscribe it, set true.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
    */
    public func setSubscribeSubreddit(subreddit:Subreddit, subscribe:Bool, completion:(Result<JSON>) -> Void) throws -> NSURLSessionDataTask {
        var parameter:[String:String] = ["sr":subreddit.name]
        parameter["action"] = (subscribe) ? "sub" : "unsub"
        guard let request:NSMutableURLRequest = NSMutableURLRequest.mutableOAuthRequestWithBaseURL(baseURL, path:"/api/subscribe", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.URLError.error }
        return handleAsJSONRequest(request, completion:completion)
    }
    
    /**
    Get all subreddits.
    
    - parameter subredditsWhere: Chooses the order in which the subreddits are displayed among SubredditsWhere.
    - parameter paginator: Paginator object for paging.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
    */
    public func getSubreddit(subredditWhere:SubredditsWhere, paginator:Paginator?, completion:(Result<RedditAny>) -> Void) throws -> NSURLSessionDataTask {
        let parameter = paginator?.addParametersToDictionary([:])
        guard let request = NSMutableURLRequest.mutableOAuthRequestWithBaseURL(baseURL, path:subredditWhere.path, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.URLError.error }
        return handleRequest(request, completion:completion)
    }
    
    /**
    Get subreddits the user has a relationship with. The where parameter chooses which subreddits are returned as follows:
    
    - subscriber - subreddits the user is subscribed to
    - contributor - subreddits the user is an approved submitter in
    - moderator - subreddits the user is a moderator of
    
    - parameter mine: The type of relationship with the user as SubredditsMineWhere.
    - parameter paginator: Paginator object for paging contents.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
    */
    public func getUserRelatedSubreddit(mine:SubredditsMineWhere, paginator:Paginator?, completion:(Result<Listing>) -> Void) throws -> NSURLSessionDataTask {
        guard let request = NSMutableURLRequest.mutableOAuthRequestWithBaseURL(baseURL, path:mine.path, parameter:paginator?.parameterDictionary, method:"GET", token:token)
            else { throw ReddiftError.URLError.error }
        let task = URLSession.dataTaskWithRequest(request, completionHandler: { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            self.updateRateLimitWithURLResponse(response)
            let result = resultFromOptionalError(Response(data: data, urlResponse: response), optionalError:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Listing)
            completion(result)
        })
        task.resume()
        return task
    }
    
    // MARK: BDT does not cover following methods.
    
    /**
    Search subreddits by title and description.
    
    - parameter query: The search keywords, must be less than 512 characters.
    - parameter paginator: Paginator object for paging.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
    */
    public func getSubredditSearch(query:String, paginator:Paginator?, completion:(Result<Listing>) -> Void) throws -> NSURLSessionDataTask? {
        let parameter = paginator?.addParametersToDictionary(["q":query])
        guard let request = NSMutableURLRequest.mutableOAuthRequestWithBaseURL(baseURL, path:"/subreddits/search", parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.URLError.error }
        let task = URLSession.dataTaskWithRequest(request, completionHandler: { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            self.updateRateLimitWithURLResponse(response)
            let result = resultFromOptionalError(Response(data: data, urlResponse: response), optionalError:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Listing)
            completion(result)
        })
        task.resume()
        return task
    }
    
    /**
    DOES NOT WORK... WHY?
    */
    public func getSticky(subreddit:Subreddit, completion:(Result<RedditAny>) -> Void) throws -> NSURLSessionDataTask {
        guard let request = NSMutableURLRequest.mutableOAuthRequestWithBaseURL(baseURL, path:"/r/" + subreddit.displayName + "/sticky", method:"GET", token:token)
            else { throw ReddiftError.URLError.error }
        return handleRequest(request, completion:completion)
    }
}