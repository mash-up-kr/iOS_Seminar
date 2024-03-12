//
//  StudyIntroduceView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct StudyIntroduceView: View {
  @EnvironmentObject var pathModel: PathModel
  let text = "🧐 스터디란 무엇인가"
  @State private var revealedCharacters = 0
  @State private var isEndRevealedCharacters: Bool = false
  @State private var isDisplayCardView: Bool = false
  @State private var isAvailableDisplayNextView: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
        .onTapGesture(perform: {
          if isEndRevealedCharacters {
            isDisplayCardView = true
          }
          if isAvailableDisplayNextView {
            pathModel.paths.append(.teamView)
          }
        })
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack {
        Spacer()
        
        if !isDisplayCardView {
          HStack {
            Spacer()
            
            Text(String(text.prefix(revealedCharacters)))
              .font(.system(size: 100))
              .bold()
            
            Spacer()
          }
        } else {
          HStack(spacing: 20) {
            Spacer()
            
            Group {
              StudyCardView(
                title: "팀 스터디",
                description: "🏊🏻‍♂️ 스터디 팀끼리 기술에 대해 딥다이브"
              )
              
              StudyCardView(
                title: "주제",
                description: "🍣 오마카세"
              )
              
              StudyCardView(
                title: "방식",
                description:
                  """
                  무형식 자유
                  결과물 공유
                  아카이빙 필수
                  """
              )
              
              StudyCardView(
                title: "옵셔널 스터디",
                description: "🎉 자유롭게 스터디"
              )
            }
            .onAppear {
              isAvailableDisplayNextView = true
            }
            
            Spacer()
          }
        }
        
        Spacer()
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
