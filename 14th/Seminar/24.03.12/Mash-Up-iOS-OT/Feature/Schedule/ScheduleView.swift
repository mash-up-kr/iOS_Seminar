//
//  ScheduleView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

enum MonthType: String {
  case empty
  case march = "3월"
  case april = "4월"
  case may = "5월"
  case june = "6월"
  case july = "7월"
  case august = "8월"
  case september = "9월"
  case october = "10월"
  case etc = "기타 활동"
}

struct ScheduleView: View {
  @EnvironmentObject var pathModel: PathModel
  let text = "🤔 7개월간 우리의 여정"
  @State private var revealedCharacters = 0
  @State private var isEndRevealedCharacters: Bool = false
  @State private var isAvailableDisplayNextView: Bool = false
  @State private var monthType: MonthType = .empty
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
        .onTapGesture(perform: {
          if isEndRevealedCharacters {
            switch monthType {
            case .empty:
              monthType = .march
            case .march:
              monthType = .april
            case .april:
              monthType = .may
            case .may:
              monthType = .june
            case .june:
              monthType = .july
            case .july:
              monthType = .august
            case .august:
              monthType = .september
            case .september:
              monthType = .october
            case .october:
              monthType = .etc
            case .etc:
              break
            }
          }
          if isAvailableDisplayNextView {
            pathModel.paths.append(.additionalIntroduceView)
          }
        })
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack {
        Spacer()
        
        switch monthType {
        case .empty:
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
          
        case .march:
          ScheduleComponentView(
            title: monthType.rawValue,
            schedules: [
              ("3월 12일 ", "오리엔테이션"),
              ("3월 19일", "1차 세미나 (온라인)"),
              ("3월 30일", "iOS MT")
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .april:
          ScheduleComponentView(
            title: monthType.rawValue,
            schedules: [
              ("4월 2일 ", "iOS 방학 - 버디미션 & 스터디 집중 주간"),
              ("4월 9일 ", "iOS 방학 - 버디미션 & 스터디 집중 주간"),
              ("4월 16일", "2차 세미나 (온라인)"),
              ("4월 23일", "3차 세미나 (오프라인) - 버디미션 발표"),
              ("4월 30일", "4차 세미나 (온라인)")
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .may:
          ScheduleComponentView(
            title: monthType.rawValue,
            schedules: [
              ("5월 7일 ", "5차 세미나 (오프라인) - 홈커밍데이"),
              ("5월 14일", "6차 세미나 (온라인)"),
              ("5월 21일", "iOS 방학"),
              ("5월 28일", "iOS 방학")
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .june:
          ScheduleComponentView(
            title: monthType.rawValue,
            schedules: [
              ("6월 4일 ", "iOS 방학"),
              ("6월 11일", "7차 세미나 (오프라인) - 스터디 발표"),
              ("6월 18일", "8차 세미나 (오프라인) - 스터디 발표"),
              ("6월 25일", "9차 세미나 (오프라인) - 스터디 발표"),
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .july:
          ScheduleComponentView(
            title: monthType.rawValue,
            schedules: []
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .august:
          ScheduleComponentView(
            title: monthType.rawValue,
            schedules: [
              ("8월 3주차", "iOS 여름 모임")
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .september:
          ScheduleComponentView(
            title: monthType.rawValue,
            schedules: []
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .october:
          ScheduleComponentView(
            title: monthType.rawValue,
            schedules: []
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          
        case .etc:
          ScheduleComponentView(
            title: monthType.rawValue,
            schedules: [
              ("3월", "iOS MT"),
              ("4월", "버디미션"),
              ("9월", "이별 MT"),
              ("상시", "깜짝 활동을 기대해주세요 🎁"),
            ]
          )
          .frame(width: UIScreen.main.bounds.width - 20)
          .onAppear {
            isAvailableDisplayNextView = true
          }
        }
        
        Spacer()
      }
      
      if monthType == .july || monthType == .september || monthType == .october {
        VStack {
          Spacer()
          
          HStack {
            Spacer()
            
            LottieView(animation: "empty")
              .frame(width: 200, height: 200)
          }
        }
          .onTapGesture(perform: {
            switch monthType {
            case .july:
              monthType = .august
            case .september:
              monthType = .october
            case .october:
              monthType = .etc
            default:
              break
            }
          })
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
