//
//  SnailGameView.swift
//  snailGame
//
//  Created by GREEN on 2024/03/12.
//

import SwiftUI
import AVFoundation

struct SnailGameView: View {
  @State private var textColor: Color = .white
  let colors: [Color] = [.red, .green, .blue, .orange, .pink, .purple, .yellow, .white]
  @State private var colorIndex = 0
  @State private var snailOffset: [CGFloat] = [0, 0, 0, 0]
  @State private var speed: [CGFloat] = [1.0, 1.0, 1.0, 1.0]
  @State private var timer: Timer? = nil
  private var startOrStopButtonTitle: String {
    timer == nil ? "달팽이 출발!" : "달팽이 정지!"
  }
  private var startOrStopButtonBackground: Color {
    timer == nil ? .green : .red
  }
  @State private var audioPlayer: AVAudioPlayer?
  @State private var firstStart: Bool = true
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Spacer()
            
            Text("Mash-Up iOS배 달팽이 경주 🐌")
              .foregroundColor(textColor)
              .font(.largeTitle)
            
            Spacer()
          }
          .padding(.top, 10)
          
          Spacer()
          
          SnailView(name: "snail", snailOffset: $snailOffset[0])
          
          SnailView(name: "snail2", snailOffset: $snailOffset[1])
          
          SnailView(name: "snail3", snailOffset: $snailOffset[2])
          
          SnailView(name: "snail4", snailOffset: $snailOffset[3])
          
          Spacer()
          
          HStack {
            Spacer()
            
            Button(action: startMoving) {
              Text(startOrStopButtonTitle)
                .padding()
                .background(startOrStopButtonBackground)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: reset) {
              Text("리셋")
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Spacer()
          }
        }
      }
      
      HStack {
        Spacer()
        
        Rectangle()
          .fill(.red)
          .frame(width: 3, height: UIScreen.main.bounds.size.height)
      }
    }
  }
  
  private func startMoving() {
    if timer == nil {
      timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
        colorIndex = (colorIndex + 1) % colors.count
        textColor = colors[colorIndex]
        
        changeSpeed()
      }
      
      let path = Bundle.main.path(forResource: "background", ofType: "mp3")!
      let url = URL(fileURLWithPath: path)
      
      do {
        if firstStart {
          audioPlayer = try AVAudioPlayer(contentsOf: url)
          audioPlayer?.play()
          audioPlayer?.numberOfLoops = -1
          firstStart.toggle()
        } else {
          audioPlayer?.play()
        }
      } catch {
        print(error.localizedDescription)
      }
    } else {
      timer?.invalidate()
      timer = nil
      audioPlayer?.pause()
    }
  }
  
  private func changeSpeed() {
    self.snailOffset[0] += speed[0]
    self.snailOffset[1] += speed[1]
    self.snailOffset[2] += speed[2]
    self.snailOffset[3] += speed[3]
    
    self.speed[0] = CGFloat.random(in: -3.0...7.0)
    self.speed[1] = CGFloat.random(in: -2.0...6.0)
    self.speed[2] = CGFloat.random(in: -1.0...5.0)
    self.speed[3] = CGFloat.random(in: -4.0...8.0)
  }
  
  private func reset() {
    self.snailOffset[0] = 1.0
    self.snailOffset[1] = 1.0
    self.snailOffset[2] = 1.0
    self.snailOffset[3] = 1.0
    
    self.snailOffset[0] = 0
    self.snailOffset[1] = 0
    self.snailOffset[2] = 0
    self.snailOffset[3] = 0
    
    audioPlayer?.stop()
    firstStart.toggle()
  }
}

private struct SnailView: View {
  private var name: String
  @Binding private var snailOffset: CGFloat
  @State private var owner: String
  @State private var isShowingNameInput = false
  
  fileprivate init(
    name: String,
    snailOffset: Binding<CGFloat>,
    owner: String = ""
  ) {
    self.name = name
    self._snailOffset = snailOffset
    self.owner = owner
  }
  
  fileprivate var body: some View {
    VStack(spacing: 5) {
      Text(owner)
        .foregroundStyle(.white)
        .font(.title)
      
      Image(name)
        .resizable()
        .frame(width: 150, height: 150)
        .onTapGesture {
          isShowingNameInput = true
        }
    }
    .offset(x: snailOffset, y: 0)
    .popover(isPresented: $isShowingNameInput) {
      NameInputView(owner: $owner)
    }
  }
}

private struct NameInputView: View {
  @Binding private var owner: String
  @Environment(\.dismiss) private var dismiss
  
  fileprivate init(owner: Binding<String>) {
    self._owner = owner
  }
  
  fileprivate var body: some View {
    VStack {
      TextField("대표자 이름을 써주세요!", text: $owner)
        .foregroundStyle(.white)
        .padding()
      
      Button("저장!") {
        dismiss()
      }
    }
    .padding(.all, 20)
  }
}
