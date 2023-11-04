//
//  ContentView.swift
//  WorldScramble
//
//  Created by Maks Winters on 03.11.2023.
//

import SwiftUI

struct ContentView: View {
    @State private var rootWord = ""
    @State private var newWord = ""
    @State private var usedWords = [String]()
    @State private var score = 0
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var isShown = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Input word") {
                    TextField("New world", text: $newWord)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("Score:") {
                    Text(String(score))
                }
                Section("Your words") {
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                    }
                }
            }
            .navigationTitle(rootWord)
            .onSubmit(addNewWord)
            .onAppear(perform: startGame)
            .alert(errorTitle, isPresented: $isShown) { } message: {
                Text(errorMessage)
            }
            .toolbar{
                Button("Restart", action: startGame)
            }
        }
    }
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard answer.count > 0 else { return }
        
        guard isNotRootWord(word: answer) else {
            wordError(title: "Not allowed!", message: "You cannot use a starting word!")
            return
        }
        
        guard isLongEnough(word: answer) else {
            wordError(title: "Too short!", message: "Your word is too short with \(answer.count) letter\(answer.count == 1 ? "" : "s")")
            return
        }
        
        guard isOriginal(word: answer) else {
            wordError(title: "Not a new word", message: "You have already typed this word before.")
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "What?", message: "Sorry, it seems like this word does not exist.")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Not possible", message: "You can't assemble this word from \(rootWord)!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        
        score += 25
        
        newWord = ""
    }
    
    func startGame() {
        score = 0
        newWord = ""
        usedWords.removeAll()
        if let startWorldURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWorldURL) {
                let allWords = startWords.components(separatedBy: "\n")
                rootWord = allWords.randomElement() ?? "memorial"
                return
            }
            
            fatalError("Could not load words from a bundle.")
            
        }
    }
    
    func isNotRootWord(word: String) -> Bool {
        word != rootWord ? true : false
    }
    
    func isLongEnough(word: String) -> Bool {
        word.count <= 3 ? false : true
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.count)
        let misspelleldRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelleldRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        
        isShown = true
    }
}

#Preview {
    ContentView()
}
