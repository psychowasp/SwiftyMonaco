//
//  SwiftyMonaco.swift
//
//
//  Created by Pavel Kasila on 20.03.21.
//

import SwiftUI
import Combine
#if os(macOS)
typealias ViewControllerRepresentable = NSViewControllerRepresentable
#else
typealias ViewControllerRepresentable = UIViewControllerRepresentable
#endif

public struct SwiftyMonaco: ViewControllerRepresentable, MonacoViewControllerDelegate {
    public var global_suggestions: [MonacoSuggestion] = []
    

    var text: Binding<String>
    private var syntax: SyntaxHighlight?
    private var _minimap: Bool = true
    private var _scrollbar: Bool = true
    private var _smoothCursor: Bool = false
    private var _cursorBlink: CursorBlink = .blink
    private var _fontSize: Int = 14
    private let data: MonacoDataModel
	#if os(macOS)
	@State private var window: NSWindow?
	#endif
//    var gsuggestions: Binding<[MonacoSuggestion]>
//    
//    private var text_subscriptions: Set<AnyCancellable> = .init()
//    
//    public var global_suggestions: [MonacoSuggestion] {
//        
//        return gsuggestions.wrappedValue
//    }
    
    public init(text: Binding<String>, data: MonacoDataModel) {
        self.text = text
        self.data = data
    }
    
    #if os(macOS)
    public func makeNSViewController(context: Context) -> MonacoViewController {
        let vc = MonacoViewController()
        vc.delegate = self
        //vc.data_model = data
        vc.webConfiguration = data.webConfiguration
//		DispatchQueue.main.async {
//			window = vc.view.window
//		}
		
        return vc
    }
    
	
    public func updateNSViewController(_ nsViewController: MonacoViewController, context: Context) {
		
    }
    #endif
    
    #if os(iOS)
    public func makeUIViewController(context: Context) -> MonacoViewController {
        let vc = MonacoViewController()
        vc.delegate = self
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: MonacoViewController, context: Context) {
        
    }
    #endif
    
    public func monacoView(readText controller: MonacoViewController) -> String {
        return self.text.wrappedValue
    }
    
    public func monacoView(controller: MonacoViewController, textDidChange text: String) {
        self.text.wrappedValue = text
    }
    
    public func monacoView(getSyntax controller: MonacoViewController) -> SyntaxHighlight? {
        return syntax
    }
    
    public func monacoView(getMinimap controller: MonacoViewController) -> Bool {
        return _minimap
    }
    
    public func monacoView(getScrollbar controller: MonacoViewController) -> Bool {
        return _scrollbar
    }
    
    public func monacoView(getSmoothCursor controller: MonacoViewController) -> Bool {
        return _smoothCursor
    }
    
    public func monacoView(getCursorBlink controller: MonacoViewController) -> CursorBlink {
        return _cursorBlink
    }
    
    public func monacoView(getFontSize controller: MonacoViewController) -> Int {
        return _fontSize
    }
}

// MARK: - Modifiers
public extension SwiftyMonaco {
    func syntaxHighlight(_ syntax: SyntaxHighlight) -> Self {
        var m = self
        m.syntax = syntax
        return m
    }
}

public extension SwiftyMonaco {
    func minimap(_ enabled: Bool) -> Self {
        var m = self
        m._minimap = enabled
        return m
    }
}

public extension SwiftyMonaco {
    func scrollbar(_ enabled: Bool) -> Self {
        var m = self
        m._scrollbar = enabled
        return m
    }
}

public extension SwiftyMonaco {
    func smoothCursor(_ enabled: Bool) -> Self {
        var m = self
        m._smoothCursor = enabled
        return m
    }
}

public extension SwiftyMonaco {
    func cursorBlink(_ style: CursorBlink) -> Self {
        var m = self
        m._cursorBlink = style
        return m
    }
}

public extension SwiftyMonaco {
    func fontSize(_ size: Int) -> Self {
        var m = self
        m._fontSize = size
        return m
    }
}
