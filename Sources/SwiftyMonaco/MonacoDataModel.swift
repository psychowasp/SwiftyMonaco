//
//  File.swift
//  
//
//  Created by MusicMaker on 03/08/2023.
//

import Foundation
import Combine
import WebKit

public enum SuggestionRequestType {
    case object
    case properties
    case globals
}

public protocol MonacoDataModel: AnyObject {
    
    //var currentProperties: CurrentValueSubject<[MonacoSuggestion], Never> { get }
    
    var webConfiguration: WKWebViewConfiguration { get }
}

