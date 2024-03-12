//
//  YounggyunSeminar.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/30.
//

import SwiftUI

struct YounggyunSeminar: View {
  @EnvironmentObject var pathModel: PathModel
  let text = "영균's 세미나"
  @State private var revealedCharacters = 0
  @State private var isEndRevealedCharacters: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture(perform: {
          if isEndRevealedCharacters {
            pathModel.paths.append(.endView)
          }
        })
        .edgesIgnoringSafeArea(.all)
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack {
        Spacer()
        
        HStack {
          Spacer()
          
          Text(String(text.prefix(revealedCharacters)))
            .font(.system(size: 100))
            .bold()
          
          Spacer()
        }
        
        Spacer()
      }
      
      VStack {
        HStack {
          LottieView(animation: "welcome")
            .frame(width: 400)
          
          Spacer()
        }
        
        Spacer()
        
        HStack {
          Spacer()
          
          LottieView(animation: "welcome")
            .frame(width: 400)
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
}
