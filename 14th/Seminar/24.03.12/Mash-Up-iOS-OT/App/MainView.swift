//
//  MainView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct MainView: View {
  @StateObject private var pathModel = PathModel()
  @State private var isEndedSplash: Bool = false
  
  var body: some View {
    if !isEndedSplash {
      SplashView(isEndedSplash: $isEndedSplash)
    } else {
      NavigationStack(path: $pathModel.paths) {
        IntroView()
          .navigationDestination(
            for: PathType.self,
            destination: { pathType in
              switch pathType {
              case .introView:
                IntroView()
                
              case .welcomeView:
                WelcomeView()
                
              case .indexView:
                IndexView()
                
              case .introduceView:
                IntroduceView()
                
              case .studyIntroduceView:
                StudyIntroduceView()
                
              case .teamView:
                TeamView()
                
              case .scheduleView:
                ScheduleView()
                
              case .additionalIntroduceView:
                AdditionalIntroduceView()
                
              case .thanksView:
                ThanksView()
                
              case .sangheeSeminar:
                SangheeSeminar()
                
              case .younggyunSeminar:
                YounggyunSeminar()
                
              case .endView:
                EndView()
              }
            }
          )
      }
      .environmentObject(pathModel)
    }
  }
}

private struct SplashView: View {
  @Binding var isEndedSplash: Bool
  @State private var textString = ""
  @State private var fadeOutImage = false
  private let title = Array("Mash-Up iOS")
  private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
  
  var body: some View {
    HStack {
      Image("logo")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(
          width: fadeOutImage ? UIScreen.main.bounds.width : 300,
          height: fadeOutImage ? UIScreen.main.bounds.height : 300
        )
        .offset(x: CGFloat(textString.count) * -5)
        .opacity(fadeOutImage ? 0 : 1)
        .animation(.easeInOut(duration: 2), value: fadeOutImage)
      
      Text(textString)
        .font(.system(size: 100))
        .bold()
        .foregroundStyle(.white)
    }
    .onReceive(timer) { _ in
      if textString.count < title.count {
        textString.append(title[textString.count])
      } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          withAnimation {
            self.fadeOutImage = true
          }
        }
      }
    }
    .onChange(of: fadeOutImage) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
        isEndedSplash = true
      }
    }
  }
}

#Preview {
  MainView()
}
