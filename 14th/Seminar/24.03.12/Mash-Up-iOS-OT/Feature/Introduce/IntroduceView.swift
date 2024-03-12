//
//  IntroduceView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct IntroduceView: View {
  @EnvironmentObject private var pathModel: PathModel
  let text = "렛미인트로듀스마이셀프"
  let people = [
    "조찬우", "안상희", "김남수",
    "이재용", "김지인", "임리나", "김찬수",
    "최혜린", "박소현", "김영균",
  ]
  @State var shuffledPeople: [String] = []
  @State private var revealedCharacters = 0
  @State private var isEndRevealedCharacters: Bool = false
  @State private var isDisplayIndexComponentView: Bool = false
  @State private var isDisplayLoadingView: Bool = false
  @State private var isDisplayResultView: Bool = false
  @State private var isAvailableDisplayNextView: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
        .onTapGesture(perform: {
          if isEndRevealedCharacters {
            isDisplayIndexComponentView = true
          }
          if isAvailableDisplayNextView {
            pathModel.paths.append(.studyIntroduceView)
          }
        })
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack(spacing: 10) {
        Spacer()
        
        if !isDisplayIndexComponentView {
          HStack {
            Spacer()
            
            Text(String(text.prefix(revealedCharacters)))
              .font(.system(size: 100))
              .bold()
            
            Spacer()
          }
        } else if !isDisplayResultView {
          HStack {
            Spacer()
            
            Button(
              action: {
                shuffledPeople = self.shufflePeople()
                isDisplayLoadingView = true
              },
              label: {
                Text("🎲 누구부터 할래 ⁉️")
                  .font(.system(size: 100))
                  .bold()
                  .foregroundStyle(.white)
                  .padding(.all, 20)
                  .background(Color.init(red: 75/255, green: 58/255, blue: 255/255))
                  .cornerRadius(20)
              }
            )
            
            Spacer()
          }
        } else {
          HStack {
            Spacer()
            
            ScrollView(showsIndicators: false) {
              VStack(spacing: 70) {
                ForEach(shuffledPeople.indices, id: \.self) { index in
                  Text(shuffledPeople[index])
                    .font(.system(size: 50))
                    .bold()
                    .foregroundStyle(.white)
                    .opacity(isAvailableDisplayNextView ? 1 : 0)
                    .animation(.easeInOut(duration: 1).delay(0.5 * Double(index)), value: isAvailableDisplayNextView)
                    .onAppear {
                      isAvailableDisplayNextView = true
                    }
                }
              }
            }
            
            Spacer()
          }
          .onAppear {
            withAnimation {
              isAvailableDisplayNextView = true
            }
          }
        }
        
        Spacer()
      }
      
      if isDisplayLoadingView {
        ZStack {
          Color.black
            .contentShape(Rectangle())
            .edgesIgnoringSafeArea(.all)
          
          LottieView(animation: "loading")
            .frame(width: 200)
        }
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isDisplayLoadingView = false
            isDisplayResultView = true
          }
        }
      }
    }
    .toolbar(.hidden)
    .onAppear {
      animateText()
    }
  }
  
  func animateText() {
    guard revealedCharacters < text.count else {
      isEndRevealedCharacters = true
      return
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      revealedCharacters += 1
      animateText()
    }
  }
  
  func shufflePeople() -> [String] {
    var shuffledPeople = people
    shuffledPeople.shuffle()
    return shuffledPeople
  }
}
