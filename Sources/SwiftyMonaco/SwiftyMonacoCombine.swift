//
//  File.swift
//  
//
//  Created by MusicMaker on 01/08/2023.
//

import Foundation
import Combine

public class MonacoDataModelTemp: ObservableObject {
    
    
    
    @Published var text: String
    @Published var syntax: SyntaxHighlight?
    @Published var minimap: Bool = true
    @Published var scrollbar: Bool = true
    @Published var smoothCursor: Bool = false
    @Published var cursorBlink: CursorBlink = .blink
    @Published var fontSize: Int = 14
    
    init(text: String, syntax: SyntaxHighlight? = nil, minimap: Bool, scrollbar: Bool, smoothCursor: Bool, cursorBlink: CursorBlink, fontSize: Int) {
        self.text = text
        self.syntax = syntax
        self.minimap = minimap
        self.scrollbar = scrollbar
        self.smoothCursor = smoothCursor
        self.cursorBlink = cursorBlink
        self.fontSize = fontSize
    }
    
}
