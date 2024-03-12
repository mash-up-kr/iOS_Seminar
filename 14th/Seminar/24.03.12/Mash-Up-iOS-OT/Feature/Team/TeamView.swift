//
//  TeamView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

private enum TeamType {
  case empty
  case branding
  case sanghee
  case chansoo
  case younggyun
}

struct TeamView: View {
  @EnvironmentObject var pathModel: PathModel
  let text = "⁉️ 나는 누구랑 팀"
  @State private var revealedCharacters = 0
  @State private var isEndRevealedCharacters: Bool = false
  @State private var isAvailableDisplayNextView: Bool = false
  @State private var teamType: TeamType = .empty
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
        .onTapGesture(perform: {
          if isEndRevealedCharacters {
            switch teamType {
            case .empty:
              teamType = .branding
            case .branding:
              teamType = .sanghee
            case .sanghee:
              teamType = .chansoo
            case .chansoo:
              teamType = .younggyun
            case .younggyun:
              break
            }
          }
          if isAvailableDisplayNextView {
            pathModel.paths.append(.scheduleView)
          }
        })
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack {
        Spacer()
        
        switch teamType {
        case .empty:
          HStack {
            Spacer()
            
            Text(String(text.prefix(revealedCharacters)))
              .font(.system(size: 100))
              .bold()
            
            Spacer()
          }
          
        case .branding:
          TeamComponentView(
            title: "브랜딩🤖",
            members: [
              .init(order: 1, image: "namsoo", name: "김남수"),
              .init(order: 2, image: "jaeyong", name: "이재용"),
              .init(order: 3, image: "jiin", name: "김지인")
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .sanghee:
          TeamComponentView(
            title: "상희네🚀",
            members: [
              .init(order: 1, image: "sanghee", name: "안상희"),
              .init(order: 2, image: "sohyun", name: "박소현"),
              .init(order: 3, image: "younggyun", name: "김영균")
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .chansoo:
          TeamComponentView(
            title: "찬수네🤭",
            members: [
              .init(order: 1, image: "chansoo", name: "김찬수"),
              .init(order: 2, image: "lina", name: "임리나"),
              .init(order: 3, image: "jongyoon", name: "김종윤"),
              .init(order: 4, image: "hyeryeong", name: "장혜령")
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .younggyun:
          TeamComponentView(
            title: "혜린네🧐",
            members: [
              .init(order: 1, image: "hyerin", name: "최혜린"),
              .init(order: 2, image: "chanwoo", name: "조찬우"),
              .init(order: 3, image: "junhyuk", name: "양준혁"),
              .init(order: 4, image: "hyuna", name: "송현아")
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          .onAppear {
            isAvailableDisplayNextView = true
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
