//
//  ContentView.swift
//  WorldScramble
//
//  Created by Maks Winters on 03.11.2023.
//

import SwiftUI

struct ContentView: View {
    let colors = [Color.yellow, 
                  Color.blue,
                  Color.purple,
                  Color.red,
                  Color.green
                 ]
    @AppStorage("SET_COLOR") private var setColor = "yellow"
    @State private var mainColor: Color
    
    @State private var rootWord = ""
    @State private var newWord = ""
    @State private var usedWords = [String]()
    @State private var score = 0
    @AppStorage("PREV_SCORE") private var bestScore = 0
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var isShown = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        HStack {
                            ZStack {
                                Image(imageForColor(color: mainColor))
                                    .resizable()
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                VStack {
                                    Text("Score")
                                        .font(.system(size: 25, weight: .heavy, design: .rounded))
                                    Text(score.description)
                                        .font(.system(size: 25, weight: .medium, design: .rounded))
                                        .contentTransition(.numericText())
                                }
                                .foregroundStyle(.white)
                                .shadow(color: .black, radius: 5)
                            }
                            .accessibilityElement()
                            .accessibilityLabel("Score, \(score)")
                            ZStack {
                                Image(imageForColor(color: mainColor))
                                    .resizable()
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .scaleEffect(x: -1, y: -1)
                                VStack {
                                    Text("Best score")
                                        .font(.system(size: 25, weight: .heavy, design: .rounded))
                                    Text(bestScore.description)
                                        .font(.system(size: 25, weight: .medium, design: .rounded))
                                        .contentTransition(.numericText())
                                }
                                .foregroundStyle(.white)
                                .shadow(color: .black, radius: 5)
                            }
                            .accessibilityElement()
                            .accessibilityLabel("Best score, \(score)")
                            .accessibilityValue("Double tap to reset")
                            .onTapGesture {
                                resetBest()
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .frame(height: 90)
                    Section {
                        VStack {
                            HStack {
                                Text("Your word is...")
                                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                                    .foregroundStyle(mainColor)
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                Text(rootWord)
                                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                            }
                        }
                        .accessibilityElement()
                        .accessibilityLabel("Your word is")
                        .accessibilityValue(rootWord)
                    }
                    .frame(height: 150)
                    Section("Input word") {
                        TextField("New world", text: $newWord)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Section("Your words") {
                        ForEach(usedWords, id: \.self) { word in
                            HStack {
                                Image(systemName: "\(word.count).circle")
                                    .foregroundStyle(mainColor)
                                    .shadow(radius: 1)
                                Text(word)
                            }
                            .accessibilityElement()
                            .accessibilityLabel(word)
                            .accessibilityHint("\(word.count) letters")
                        }
                    }
                }
                .animation(.linear, value: mainColor)
                .navigationTitle("WordScramble")
                .navigationBarTitleDisplayMode(.inline)
                .onSubmit(addNewWord)
                .onAppear(perform: startGame)
                .alert(errorTitle, isPresented: $isShown) { } message: {
                    Text(errorMessage)
                }
                .toolbar{
                    Picker("Color picker", selection: $mainColor) {
                        ForEach(colors, id: \.self) { color in
                            Text(color.description.capitalized)
                        }
                    }
                    .onChange(of: mainColor) { oldColor, color in
                        setColor = color.description
                        print(color.description)
                    }
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            startGame()
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 30))
                                .frame(width: 50, height: 50)
                        }
                        .accessibilityLabel("Start again")
                        .buttonStyle(.borderedProminent)
                        .tint(mainColor)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                        .padding()
                    }
                }
            }
        }
    }
    
    func resetBest() {
        bestScore = 0
    }
    
    func imageForColor(color: Color) -> String {
        switch color {
        case .red:
            "red"
        case .green:
            "green"
        case .blue:
            "blue"
        case .purple:
            "purple"
        case .yellow:
            "yellow"
        default:
            "red"
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
            wordError(title: "Not possible", message: "You can't put together this word from \(rootWord)!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        
        score += 25
        
        newWord = ""
        
        let best = bestScore
        score > best ? bestScore = score : nil
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
    
    init() {
        let defaults = UserDefaults.standard
        let savedColor = defaults.string(forKey: "SET_COLOR")
        
        let convertedColor: Color = switch savedColor {
        case "yellow": .yellow
        case "blue": .blue
        case "purple": .purple
        case "red": .red
        case "green": .green
        default: .yellow
    }
        self.mainColor = convertedColor
    }
}

#Preview {
    ContentView()
}
