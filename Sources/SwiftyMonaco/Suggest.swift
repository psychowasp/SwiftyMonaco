//
//  File.swift
//  
//
//  Created by MusicMaker on 14/11/2022.
//

import Foundation


public enum CompletionItemKind: Int, Codable {
    case Class = 5
    case Color = 19
    case Constant = 14
    case Constructor = 2
    case Function = 1
    case Interface = 7
    case Method = 0
    case Module = 8
    case Operator = 11
    case Property = 9
    case Value = 13
    case Variable = 4
    case Unit = 12
    case TypeParameter = 24
    case Text = 18
    case Issue = 26
    case Field = 3
    
}

public class IRange: Codable {
    
    var endColumn: Int
    var endLineNumber: Int
    var startColumn: Int
    var startLineNumber: Int
    
    enum CodingKeys: CodingKey {
        case endColumn
        case endLineNumber
        case startColumn
        case startLineNumber
    }
    
    public required init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<IRange.CodingKeys> = try decoder.container(keyedBy: IRange.CodingKeys.self)
        
        self.endColumn = try container.decode(Int.self, forKey: IRange.CodingKeys.endColumn)
        self.endLineNumber = try container.decode(Int.self, forKey: IRange.CodingKeys.endLineNumber)
        self.startColumn = try container.decode(Int.self, forKey: IRange.CodingKeys.startColumn)
        self.startLineNumber = try container.decode(Int.self, forKey: IRange.CodingKeys.startLineNumber)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<IRange.CodingKeys> = encoder.container(keyedBy: IRange.CodingKeys.self)
        
        try container.encode(self.endColumn, forKey: IRange.CodingKeys.endColumn)
        try container.encode(self.endLineNumber, forKey: IRange.CodingKeys.endLineNumber)
        try container.encode(self.startColumn, forKey: IRange.CodingKeys.startColumn)
        try container.encode(self.startLineNumber, forKey: IRange.CodingKeys.startLineNumber)
    }
    
    
    
}


public class CompletionItem: Codable {
    
    var label: String
    var kind:  CompletionItemKind
    var documentation: String
    var insertText: [String]
    var range: IRange
    
    enum CodingKeys: CodingKey {
        case label
        case kind
        case documentation
        case insertText
        case range
    }
    
    public required init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CompletionItem.CodingKeys> = try decoder.container(keyedBy: CompletionItem.CodingKeys.self)
        
        self.label = try container.decode(String.self, forKey: CompletionItem.CodingKeys.label)
        self.kind = try container.decode(CompletionItemKind.self, forKey: CompletionItem.CodingKeys.kind)
        self.documentation = try container.decode(String.self, forKey: CompletionItem.CodingKeys.documentation)
        self.insertText = try container.decode([String].self, forKey: CompletionItem.CodingKeys.insertText)
        self.range = try container.decode(IRange.self, forKey: CompletionItem.CodingKeys.range)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<CompletionItem.CodingKeys> = encoder.container(keyedBy: CompletionItem.CodingKeys.self)
        
        try container.encode(self.label, forKey: CompletionItem.CodingKeys.label)
        try container.encode(self.kind, forKey: CompletionItem.CodingKeys.kind)
        try container.encode(self.documentation, forKey: CompletionItem.CodingKeys.documentation)
        try container.encode(self.insertText, forKey: CompletionItem.CodingKeys.insertText)
        try container.encode(self.range, forKey: CompletionItem.CodingKeys.range)
    }
    
}


// and now its codable LOOOOL

