//
//  MonacoViewController.swift
//  
//
//  Created by Pavel Kasila on 20.03.21.
//

#if os(macOS)
import AppKit
public typealias ViewController = NSViewController
#else
import UIKit
public typealias ViewController = UIViewController
#endif
import WebKit




import Combine
public class MonacoViewController: ViewController, WKUIDelegate, WKNavigationDelegate {
    
    var delegate: MonacoViewControllerDelegate?
    
    weak var data_model: MonacoDataModel?
    
    let text: CurrentValueSubject<String, Never> = .init("")
    
    var webView: WKWebView!
    
    var subscriptions = Set<AnyCancellable>()
    
    var webConfiguration: WKWebViewConfiguration?
    
    public override func loadView() {
        
//        let webConfiguration = WKWebViewConfiguration()
        webConfiguration?.userContentController.add(UpdateTextScriptHandler(self), name: "updateText")
//        //webConfiguration.userContentController.add(text_update, name: "updateText")
//        //webConfiguration.userContentController.add(TestScript(), name: "suggestions")
//        //webConfiguration.userContentController.add(TestScript(), contentWorld: .page, name: "suggestions")
//        webConfiguration.userContentController.addScriptMessageHandler(PropertySuggestionsHandler(), contentWorld: .page, name: "get_object_properties")
//        webConfiguration.userContentController.addScriptMessageHandler(SuggestionScriptHandler(data: data_model), contentWorld: .page, name: "suggestions")
//        webConfiguration.userContentController.addScriptMessageHandler(SignatureHandler(), contentWorld: .page, name: "get_signatures")
//        //webConfiguration.userContentController.add(SuggestionsHandler(self), name: "suggestions2")
        webConfiguration?.userContentController.add(PrintObjectHandler(), name: "print_object")
        webView = WKWebView(frame: .zero, configuration: webConfiguration ?? .init() )
        webView.uiDelegate = self
        webView.navigationDelegate = self
        #if os(iOS)
        webView.backgroundColor = .black
        #else
        webView.layer?.backgroundColor = .black
        #endif
        view = webView
        #if os(macOS)
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(interfaceModeChanged(sender:)), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
        #endif
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMonaco()
    }
    
    private func loadMonaco() {
        let myURL = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "Resources")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    func testSuggest() {
        evaluateJavascript("""
        (function(){
            testSuggest('')
        })()
        """)
    }
    // MARK: - Dark Mode
    private func updateTheme() {
        evaluateJavascript("""
        (function(){
            monaco.editor.setTheme('\(detectTheme())')
        })()
        """)
    }
    
    #if os(macOS)
    @objc private func interfaceModeChanged(sender: NSNotification) {
        updateTheme()
    }
    #else
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTheme()
    }
    #endif
    
    private func detectTheme() -> String {
        #if os(macOS)
        if UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" {
            return "vs-dark"
        } else {
            return "vs"
        }
        #else
        switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                return "vs"
            case .dark:
                return "vs-dark"
            @unknown default:
                return "vs"
        }
        #endif
    }
    
    // MARK: - WKWebView
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Syntax Highlighting
        let syntax = self.delegate?.monacoView(getSyntax: self)
        
        let syntaxJS = syntax != nil ? """
        // Register a new language
        monaco.languages.register({ id: 'mySpecialLanguage' });

        // Register a tokens provider for the language
        monaco.languages.setMonarchTokensProvider('python', (function() {
            \(syntax!.configuration)
        })());
        

        
        
        """ : ""
        let syntaxJS2 = syntax != nil ? ", language: 'mySpecialLanguage'" : ""
        
        // Minimap
        let _minimap = self.delegate?.monacoView(getMinimap: self)
        let minimap = "minimap: { enabled: \(_minimap ?? true) }"
        
        // Scrollbar
        let _scrollbar = self.delegate?.monacoView(getScrollbar: self)
        let scrollbar = "scrollbar: { vertical: \(_scrollbar ?? true ? "\"visible\"" : "\"hidden\"") }"
        
        // Smooth Cursor
        let _smoothCursor = self.delegate?.monacoView(getSmoothCursor: self)
        let smoothCursor = "cursorSmoothCaretAnimation: \(_smoothCursor ?? false)"
        
        // Cursor Blinking
        let _cursorBlink = self.delegate?.monacoView(getCursorBlink: self)
        let cursorBlink = "cursorBlinking: \"\(_cursorBlink ?? .blink)\""
        
        // Font size
        let _fontSize = self.delegate?.monacoView(getFontSize: self)
        let fontSize = "fontSize: \(_fontSize ?? 12)"
        
        // Code itself
        let text = self.delegate?.monacoView(readText: self) ?? ""
        //let text = self.text.value
        let b64 = text.data(using: .utf8)?.base64EncodedString()
        let javascript =
        """
        (function() {
        \(syntaxJS)
        
        editor.create(
            {
                value: atob('\(b64 ?? "")'), 
                automaticLayout: true,
                language: "python",
                theme: "\(detectTheme())"\(syntaxJS2), 
                \(minimap), 
                \(scrollbar), 
                \(smoothCursor), 
                \(cursorBlink), 
                \(fontSize)
            }
        );
        var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);
        
        return true;
        })();
        
        
        """
        //print(javascript)
        evaluateJavascript(javascript)
        //addSuggest()
    }
    
    
    private func evaluateJavascript(_ javascript: String) {
        
        webView.evaluateJavaScript(javascript, in: nil, in: WKContentWorld.page) {
          result in
          switch result {
          case .failure(let error):
            #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Something went wrong while evaluating \(error.localizedDescription): \(javascript)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            #else
            let alert = UIAlertController(title: "Error", message: "Something went wrong while evaluating \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            #endif
            break
          case .success(_):
            break
          }
        }
    }
}

// MARK: - Handler
//let suggestions: [MonacoSuggestion] = (0...100).map({.init(label: "knob\($0)", kind: .class, documentation: "class BasicKnob", insertText: "knob\($0)", detail: "BasicKnob")}) + [
//    //.init(label: ".value", kind: .property, documentation: "Knob.value", insertText: "value")
//]
//let suggestionsJsonString = String(data: try! JSONEncoder().encode(suggestions), encoding: .utf8)!
let knobSuggestions: [MonacoSuggestion] = [
    .init(label: "value", kind: .property, documentation: .init(value: "float value", isTrusted: true), insertText: "value", detail: "float"),
    .init(label: "color", kind: .property, documentation: .init(value: "Color Property", isTrusted: true), insertText: "color", detail: "Color")
]
let knobsJsonString = String(data: try! JSONEncoder().encode(knobSuggestions), encoding: .utf8)!
private extension MonacoViewController {
    
 
    final class SignatureHandler: NSObject, WKScriptMessageHandlerWithReply {
        
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
            
//            let signatures = MonacoSignatureHelpProvider(
//                value: .init(
//                    activeParameter: 1,
//                    activeSignature: 0,
//                    signatures: [
//                        .init(label: "func_test", documentation: "func_test(arg0: float, arg1: int)", parameters: [
//                            .init(label: "arg0", documentation: "arg0: float"),
//                            .init(label: "arg1", documentation: "arg1: int")
//                        ])
//                    ]
//                )
//            )
            var signatures: [MonacoSignatureInformation]
            switch (message.body as? NSDictionary)?["word"] as? String {
            case "midi_out": signatures = [
                    .init(label: "midi_out", documentation: "midi_out(port: int, message: bytes)", parameters: [
                        .init(label: "arg0", documentation: "port: int"),
                        .init(label: "arg1", documentation: "message: bytes"),
                    ])
                ]
            case "sysex_out": signatures = [
                .init(label: "sysex_out", documentation: "sysex_out(port: int, sysex: list[int] | tuple[int]", parameters: [
                    .init(label: "port", documentation: "port: int"),
                    .init(label: "sysex", documentation: "sysex: list[int] | tuple[int]")
                ])
            ]
            default: signatures = []
            }
            let signatureHelp = MonacoSignatureHelp(
                    activeParameter: 0,
                    activeSignature: 0,
                    signatures: signatures
                )
            
            
            replyHandler(try! signatureHelp.jsonObject(), nil)
        }
    }
    
    final class PropertySuggestionsHandler: NSObject, WKScriptMessageHandlerWithReply {
        private weak var data_model: MonacoDataModel?
        
        init(data_model: MonacoDataModel? = nil) {
            self.data_model = data_model
        }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
            print("PropertySuggestionsHandler triggered")
            do {
                let jsonData = try! JSONSerialization.data(withJSONObject: message.body)
                let completion_input = try JSONDecoder().decode(MonacoCompletionContext.self, from: jsonData)
                print(completion_input)
//                let suggestions: [MonacoSuggestion] = [
//                    .init(label: "value", kind: .property, documentation: "float", insertText: "value", detail: "float"),
//                    .init(label: "color", kind: .property, documentation: "Color", insertText: "color", detail: "class Color"),
//                    .init(label: "name", kind: .property, documentation: "str", insertText: "name", detail: "str"),
//                    .init(label: "touched", kind: .property, documentation: "bool", insertText: "touched", detail: "bool")
//                ]
                Task(priority: .high) { [ weak self ] in
//                    let suggestions = await self?.data_model?.requestSuggestions(request: .properties, last_word: completion_input.lastWord)
//                    try await MainActor.run {
//                        replyHandler( try (suggestions ?? []).jsonObject() , nil)
//                    }
                    
                }
                
            } catch let err { print("SuggestionScriptHandler failed: \(err.localizedDescription)") }
        }
        
    }
    
    final class SuggestionScriptHandler: NSObject, WKScriptMessageHandlerWithReply {
     
        
        private weak var parent: MonacoViewController?
        private weak var data: MonacoDataModel?
        private var last_completion: MonacoCompletionInput?
        var last_type = "class"
        public init(data: MonacoDataModel? = nil) {
            self.data = data
        }
        //var global_suggestions: CurrentValueSubject<[MonacoSuggestion], Never> = .init([])
        //var global_suggestions: Binding<[MonacoSuggestion]>
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
            print("SuggestionScriptHandler triggered")
            let jsonData = try! JSONSerialization.data(withJSONObject: message.body)
//            Task(priority: .high) {
//                let completion_input = try JSONDecoder().decode(MonacoCompletionContext.self, from: jsonData)
//                print(completion_input)
//                let suggestions: [MonacoSuggestion] = (0...99).map({.init(label: "knob\($0)", kind: .class, documentation: .init(value: "class BasicKnob", isTrusted: true), insertText: "knob\($0)", detail: "BasicKnob")}) + [
//                    //.init(label: ".value", kind: .property, documentation: "Knob.value", insertText: "value")
//                ] + ( await data?.requestSuggestions(request: .globals, last_word: nil) ?? [] )
//                
//                //let suggestionsJsonString = String(data: try! JSONEncoder().encode(suggestions), encoding: .utf8)!
//                try await MainActor.run {
//                    replyHandler( try (suggestions + (parent?.delegate?.global_suggestions ?? []) ).jsonObject(), nil)
//                }
//            }
            return
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: message.body)//jsonString.data(using: .utf8),
                let completion_input = try JSONDecoder().decode(MonacoCompletionContext.self, from: jsonData)
                //print(completion_input)
                
                //print("last type: \(last_type)")
//                if last_type == "attribute" {
//
                if completion_input.triggerCharacter == "." {
                    switch completion_input.lastWord.word {
                    case let knob where knob.hasPrefix("knob"):
                        replyHandler( try (knobSuggestions ).jsonObject(), nil)
                        return
                    case "color":
                        let color_props: [MonacoSuggestion] = [
                            .init(label: "rgba", kind: .property, documentation: .init(value: "[red, green, blue, alpha]", isTrusted: true), insertText: "rgba", detail: "[float]"),
                            .init(label: "hsv", kind: .property, documentation: .init(value: "[hue, saturation, value]", isTrusted: true), insertText: "hsv", detail: "[float]")
                        ]
                        replyHandler( try color_props.jsonObject(), nil)
                        return
                    default:
                        replyHandler([], nil)
                        return
                    }
//                    
                }
                print(completion_input)
                let suggestions: [MonacoSuggestion] = (0...1).map({.init(label: "knob\($0)", kind: .class, documentation: .init(value: "class BasicKnob", isTrusted: true), insertText: "knob\($0)", detail: "BasicKnob")}) + [
                    //.init(label: ".value", kind: .property, documentation: "Knob.value", insertText: "value")
                ]
                //let suggestionsJsonString = String(data: try! JSONEncoder().encode(suggestions), encoding: .utf8)!
                replyHandler( try (suggestions + (parent?.delegate?.global_suggestions ?? []) ).jsonObject(), nil)
                
            } catch {
                replyHandler(nil,nil)
                return
            }
    
            
        }
    }
    
    final class PrintObjectHandler: NSObject, WKScriptMessageHandler {
  
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
//            guard let encodedText = message.body as? String else {
//                fatalError("Unexpected message body")
//            }
            
            print(message.body)
        }
    }
    
    final class UpdateTextScriptHandler: NSObject, WKScriptMessageHandler {
        private let parent: MonacoViewController

        init(_ parent: MonacoViewController) {
            self.parent = parent
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
            ) {
            guard let encodedText = message.body as? String,
            let data = Data(base64Encoded: encodedText),
            let text = String(data: data, encoding: .utf8) else {
                print("Unexpected message body")
                return
            }
                
            parent.delegate?.monacoView(controller: parent, textDidChange: text)
        }
    }
    
    final class UpdateTextScriptHandlerNew: NSObject, WKScriptMessageHandler {
        let output = PassthroughSubject<String, Never>()
        
//        init() {
//
//        }
        
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let encodedText = message.body as? String,
                  let data = Data(base64Encoded: encodedText),
                  let text = String(data: data, encoding: .utf8) else {
                fatalError("Unexpected message body")
            }
            output.send(text)
        }
    }
    

    

    
}

// MARK: - Delegate

public protocol MonacoViewControllerDelegate {
    func monacoView(readText controller: MonacoViewController) -> String
    func monacoView(getSyntax controller: MonacoViewController) -> SyntaxHighlight?
    func monacoView(getMinimap controller: MonacoViewController) -> Bool
    func monacoView(getScrollbar controller: MonacoViewController) -> Bool
    func monacoView(getSmoothCursor controller: MonacoViewController) -> Bool
    func monacoView(getCursorBlink controller: MonacoViewController) -> CursorBlink
    func monacoView(getFontSize controller: MonacoViewController) -> Int
    func monacoView(controller: MonacoViewController, textDidChange: String)
    
    var global_suggestions: [MonacoSuggestion] { get }
}
