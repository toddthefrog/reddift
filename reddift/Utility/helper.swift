//
//  helper.swift
//  reddift
//
//  Created by sonson on 2015/04/27.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

func commaSeparatedStringFromList(list:[String]) -> String {
    var string = ""
    for element in list {
        string = string + element + ","
    }
    if count(string) > 1 {
        var range = Range<String.Index>(start: advance(string.endIndex, -1), end: string.endIndex)
        string.removeRange(range)
    }
    return string
}