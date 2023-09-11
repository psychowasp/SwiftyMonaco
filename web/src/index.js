import * as monaco from 'monaco-editor';
import './styles.css';


class CompletionItemProvider {
    async provideCompletionItems(model, position, token, context) {
        //await new Promise((resolve) => setTimeout(resolve, 5000));
        //return new Promise((resolve) => {
            
            var textUntilPosition = model.getValueInRange({
                startLineNumber: position.lineNumber,
                startColumn: 1,
                endLineNumber: position.lineNumber,
                endColumn: position.column > 2 ? position.column - 2 : 0,
            });
    
            // if (context.triggerCharacter == "." || lastLetter == ".") {
            //     return {suggestions: []};
            // }
            var word = model.getWordUntilPosition(position);
            var lastLetterBeforeWord = "";
            // if (word) {
            //     lastLetterBeforeWord = model.getValueInRange({
            //         startLineNumber: position.lineNumber,
            //         startColumn: word.startColumn > 1 ? word.startColumn - 1 : 0,
            //         endLineNumber: position.lineNumber,
            //         endColumn: word.startColumn,
            //     });
            // }
            window.webkit.messageHandlers.print_object.postMessage("lastLetterBeforeWord: " + lastLetterBeforeWord);
            // if (lastLetterBeforeWord == ".") {
            //     return {suggestions: []};
            // }
            var word2 = model.getWordAtPosition(position);
            var last_before_dot = "";
            var startColumn = word2.startColumn;
            var endColumn = word2.endColumn;
            //var splitted_words = textUntilPosition.split(".");
            //var splitted_length = splitted_words.length;
            if (startColumn > 1) {
                var new_pos = position.clone()
                new_pos.column -= 2;
                last_before_dot = model.getWordUntilPosition(new_pos).word;
                //last_before_dot = textUntilPosition.substring(0, startColumn - 2);
            }
            return {
                suggestions: await window.webkit.messageHandlers.suggestions.postMessage({
                    "textUntilPosition": textUntilPosition, 
                    "wordUntilPosition": word.word,
                    "wordAtPosition": word2.word,
                    "lastLetter": lastLetter,
                    "lastWord": last_before_dot,
                }),
                
            };
                // .then((result) => {
                //     resolve({suggestions: result });
                // })
     
        //});
    }
    resolveCompletionItem(item,text) {}
}



(function() {
    class MonacoEditorHost {
        globalsProvider = window.webkit.messageHandlers.globals_provider;
        currentSpaceProvider = window.webkit.messageHandlers.current_space_provider;
        propertiesProvider = window.webkit.messageHandlers.properties_provider;
        signatureProvider = window.webkit.messageHandlers.signature_provider;
        print_object = window.webkit.messageHandlers.print_object;
        updateText = window.webkit.messageHandlers.updateText;
        constructor() {
            this.contextKeys = {};
            this.testProtosals = [];
            this.last_word = "";
            this.globals = undefined;
        }
        async global_objects() {
            if (this.globals == undefined) {
                this.globals = await this.globalsProvider.postMessage("all");
                this.print_object(this.globals);
            }
            return this.globals;
        };
        create(options) {
            const hostElement = document.createElement('div');
            hostElement.id = 'editor';
            document.body.appendChild(hostElement);
            
            let editor = monaco.editor.create(hostElement, options);
            this.editor = editor;
            this.editor.focus();
            this.editor.onDidChangeModelContent((event) => {
                var text = this.editor.getValue();
                this.updateText.postMessage(btoa(text));
            });
            let {widget} = editor.getContribution('editor.contrib.suggestController');
            if (widget) {
                const suggestWidget = widget.value;
                if (suggestWidget && suggestWidget._setDetailsVisible) {
                // This will default to visible details. But when user switches it off
                // they will remain switched off:
                // window.webkit.messageHandlers.print_object.postMessage(suggestWidget._details);
                // window.webkit.messageHandlers.print_object.postMessage(Object.getOwnPropertyNames(suggestWidget._details._editor));
                suggestWidget._setDetailsVisible(true);
                if (suggestWidget && suggestWidget._persistedSize) {
                suggestWidget._persistedSize.store({width: 400, height: 512});
                }
                }
            }
     
            monaco.languages.registerCompletionItemProvider("python", {
                provideCompletionItems: async (model, position, context, token) => {
                    
                    //var lastLetterBeforeWord = "";
                    var word = model.getWordUntilPosition(position);
                    let pos_line = position.lineNumber;
                    let pos_column = position.column;
                    let word_start = word.startColumn
                    let lastLetterBeforeWord = model.getValueInRange({
                        startLineNumber: pos_line,
                        endLineNumber: pos_line,
                        startColumn: word_start > 1 ? word_start - 1 : 0,
                        endColumn: word_start
                    })
                    //var word2 = model.getWordAtPosition(position);
                    if (lastLetterBeforeWord == ".") {
                        return { suggestions: [] };
                    }
                    
                    this.print_object.postMessage("requesting current space items......")
                    return {
                        suggestions: await this.currentSpaceProvider.postMessage({
                            triggerCharacter: context.triggerCharacter, 
                            triggerKind: context.triggerKind,
                            lastWord: word.word,
                            lastLetterBeforeWord: lastLetterBeforeWord,
                            currentLetters: word,
                            lineNumber: pos_line,
                            column: pos_column
                        }),
                        
                    };
                }
            });
            monaco.languages.registerCompletionItemProvider("python", {
                triggerCharacters: ["."],
                provideCompletionItems: async (model, position, context, token) => {
          
                    if (position.column == 2) {
                        return {suggestions: []};
                    }
                    var word = model.getWordUntilPosition(position);

                    var last_word_pos = position.clone();
                    last_word_pos.column -= 1;
                    let last_word = model.getWordUntilPosition(last_word_pos);
                    return {
                        suggestions: await this.propertiesProvider.postMessage({
                            triggerCharacter: context.triggerCharacter, 
                            triggerKind: context.triggerKind,
                            lastWord: last_word,
                            lastLetterBeforeWord: ".",
                            currentLetters: word,
                            lineNumber: position.lineNumber,
                            column: position.column
                        })
                    };
                }
            });
            monaco.languages.registerSignatureHelpProvider("python", {
                signatureHelpTriggerCharacters: ["("],
                signatureHelpRetriggerCharacters: [","],
                provideSignatureHelp: async (model, position, token, context) => {
                    
                    //this.print_object.postMessage("registerSignatureHelpProvider");
                    if (context.isRetrigger) {
                        //
                        if (context.triggerCharacter == ",") { context.activeSignatureHelp.activeParameter += 1; }
                        let retrigger_context = {value: context.activeSignatureHelp, dispose: () => {}}
                        return retrigger_context
                    }
                    //this.print_object.postMessage(context);
                    let new_pos = position.clone();
                    new_pos.column -= 1;
                    let func = model.getWordUntilPosition(new_pos);
                    return {value: await this.signatureProvider.postMessage(func), dispose: () => {}};
             
                    
                }
            });
        }


        addAction(fn) {
            fn(monaco, this.editor);
        }

        addCommand(fn) {
            fn(monaco, this.editor);
        }

        createContextKey(key, defaultValue) {
            const contextKey = this.editor.createContextKey(key, defaultValue);
            this.contextKeys[key] = contextKey;
        }

        focus() {
            this.editor.focus();
        }

        getContextKey(key) {
            return this.contextKeys[key].get();
        }

        resetContextKey(key) {
            this.contextKeys[key].reset();
        }

        setContextKey(key, value) {
            this.contextKeys[key].set(value);
        }

        setText(text) {
            this.editor.setValue(text);
        }

        updateOptions(options) {
            this.editor.updateOptions(options);
        }
    }

    function main() {
        window.editor = new MonacoEditorHost();
    }

    document.addEventListener('DOMContentLoaded', main);
})();
