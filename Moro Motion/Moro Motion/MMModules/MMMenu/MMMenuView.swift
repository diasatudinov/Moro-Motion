//
//  MMMenuView.swift
//  Moro Motion
//
//

import SwiftUI

struct MMMenuView: View {
    @State private var showGame = false
    @State private var showAchievement = false
    @State private var showSettings = false
    @State private var showCalendar = false
    @State private var showDailyReward = false
    
    var body: some View {
        
        ZStack {
            
            
            VStack(spacing: 0) {
                
                HStack {
                    Button {
                        showSettings = true
                    } label: {
                        Image(.settingsIconMM)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:55)
                    }
                    Spacer()
                    
                    ZZCoinBg()
                    
                    
                }.padding(20).padding(.bottom, 5)
                Spacer()
            }
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    Image(.personImgMM)
                        .resizable()
                        .scaledToFit()
                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:280)
                    
                    Spacer()
                    
                    Image(.personImg2MM)
                        .resizable()
                        .scaledToFit()
                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:280)
                    
                }
            }.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                Image(.loaderViewLogoMM)
                    .resizable()
                    .scaledToFit()
                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:90)
                    .cornerRadius(12)
                    .padding(.top, 20)
                Spacer()
                VStack(spacing: 10) {
                    
                    Button {
                        showGame = true
                    } label: {
                        Image(.playIconMM)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:63)
                    }
                    
                    Button {
                        showDailyReward = true
                    } label: {
                        Image(.dailyIconMM)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:63)
                    }
                    
                    Button {
                        showAchievement = true
                    } label: {
                        Image(.achievementsIconMM)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:63)
                    }
                }
                Spacer()
            }
            
            
            
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Image(.appBgMM)
                        .resizable()
                        .edgesIgnoringSafeArea(.all)
                        .scaledToFill()
                }
            )
            .fullScreenCover(isPresented: $showGame) {
//                GameView()
            }
            .fullScreenCover(isPresented: $showAchievement) {
                MMAchievementsView()
            }
            .fullScreenCover(isPresented: $showSettings) {
                MMSettingsView()
            }
            .fullScreenCover(isPresented: $showDailyReward) {
                MMDailyView()
            }
    }
}

#Preview {
    MMMenuView()
}
