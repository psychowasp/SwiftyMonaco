//
//  File.swift
//  
//
//  Created by MusicMaker on 02/08/2023.
//

import Foundation


public enum MonacoEditorTypes: Int, Codable {
    case function = 1
    case constructor = 2
    case variable = 4
    case `class` = 5
    case interface = 7
    
    case property = 9
    case value = 13
    case constant = 14
    case `enum` = 15
    case enum_member = 16
    
    case snippet = 27
    
    
}
public struct MonacoCompletionItemInsertTextRule: Encodable {
    var InsertAsSnippet = 4
    var KeepWhitespace = 1
    var None = 0
    
    public init(InsertAsSnippet: Int = 4, KeepWhitespace: Int = 1, None: Int = 0) {
        self.InsertAsSnippet = InsertAsSnippet
        self.KeepWhitespace = KeepWhitespace
        self.None = None
    }
}

public struct IMarkdownString: Encodable, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    
    var value: String
    var isTrusted: Bool
    var supportHtml: Bool?
    
    
    public init(stringLiteral value: String) {
        self.value = value
        isTrusted = true
    }
    public init(value: String, isTrusted: Bool = true, supportHtml: Bool? = nil) {
        self.value = value
        self.isTrusted = isTrusted
        self.supportHtml = supportHtml
    }
}


public struct MonacoSuggestion: Encodable {
    var label: String
    var kind: MonacoEditorTypes
    var documentation: IMarkdownString
    var insertText: String
    var detail: String
    var insertTextRules: Int?
    
    public init(label: String, kind: MonacoEditorTypes, documentation: IMarkdownString, insertText: String, detail: String = "", insertTextRules: Int? = nil) {
        self.label = "\(label)"
        self.kind = kind
        self.documentation = documentation
        self.insertText = insertText
        self.detail = detail
        self.insertTextRules = insertTextRules
    }
}


public enum CompletionTriggerKind: Int, Decodable {
    case Invoke
    case TriggerCharactern
    case TriggerForIncompleteCompletions
}

public struct IWordAtPosition: Decodable {
    public let startColumn: Int
    public let endColumn: Int
    public let word: String
}

public struct MonacoCompletionContext: Decodable {
    public let triggerCharacter: String?
    public let triggerKind: CompletionTriggerKind
    public let lastWord: IWordAtPosition
    public let lastLetterBeforeWord: String
    public let currentLetters: IWordAtPosition
    public let lineNumber: Int
    public let column: Int
}

public struct MonacoCompletionInput: Decodable {
    let lastLetter: String
    let textUntilPosition: String
    let wordAtPosition: String
    let wordUntilPosition: String
    let lastWord: String
}

extension MonacoCompletionInput: Equatable {
    
}

public extension Array where Element == MonacoSuggestion {
    var jsonString: String {
        .init(data: (try? JSONEncoder().encode(self)) ?? .init(), encoding: .utf8) ?? ""
    }
    var jsonData: Data {
        (try? JSONEncoder().encode(self)) ?? .init()
    }
    
    func jsonObject() throws -> Any {
        try JSONSerialization.jsonObject(with: jsonData)
    }
}

public struct MonacoParameterInformation: Encodable {
    var label: String
    var documentation: String?
}

public struct MonacoSignatureInformation: Encodable {
    var label: String
    var activeParameter: Int?
    var documentation: String?
    var parameters: [MonacoParameterInformation]
    
}

public struct MonacoSignatureHelp: Encodable {
    var activeParameter: Int
    var activeSignature: Int
    var signatures: [MonacoSignatureInformation]
    
    var jsonData: Data {
        (try? JSONEncoder().encode(self)) ?? .init()
    }
    
    func jsonObject() throws -> Any {
        try JSONSerialization.jsonObject(with: jsonData)
    }
}

public struct MonacoSignatureHelpProvider: Encodable {
    var value: MonacoSignatureHelp
    
    
    var jsonData: Data {
        (try? JSONEncoder().encode(self)) ?? .init()
    }
    
    func jsonObject() throws -> Any {
        try JSONSerialization.jsonObject(with: jsonData)
    }
}
