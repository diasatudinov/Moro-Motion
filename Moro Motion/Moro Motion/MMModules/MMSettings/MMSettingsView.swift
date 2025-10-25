//
//  MMSettingsView.swift
//  Moro Motion
//
//  Created by Dias Atudinov on 25.10.2025.
//

import SwiftUI

struct MMSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var settingsVM = CPSettingsViewModel()
    var body: some View {
        ZStack {
            
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    Image(.personImg3MM)
                        .resizable()
                        .scaledToFit()
                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:280)
                    
                    Spacer()
                    
                }
            }.ignoresSafeArea()
            
            VStack {
                
                
                ZStack {
                    
                    Image(.settingsBgMM)
                        .resizable()
                        .scaledToFit()
                    
                    
                    VStack(alignment: .leading, spacing: 10) {
                        
                        HStack(spacing: 40) {
                            
                            Image(.soundsTextMM)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:25)
                            
                            Button {
                                withAnimation {
                                    settingsVM.soundEnabled.toggle()
                                }
                            } label: {
                                Image(settingsVM.soundEnabled ? .onMM:.offMM)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:40)
                            }
                        }
                        
                        HStack(spacing: 20) {
                            
                            Image(.vibraTextMM)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:25)
                            
                            Button {
                                withAnimation {
                                    settingsVM.vibraEnabled.toggle()
                                }
                            } label: {
                                Image(settingsVM.vibraEnabled ? .onMM:.offMM)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:40)
                            }
                        }
                        
                        Image(.languageTextMM)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:35)
                        
                        
                    }.padding(.top, 30)
                }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 88:300)
                
            }.padding(.top, 50)
            
            VStack {
                ZStack {
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconMM)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:55)
                        }
                        
                        Spacer()
                        
                        ZZCoinBg()
                        
                    }.padding()
                }
                Spacer()
                
            }
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Image(.appBgMM)
                        .resizable()
                        .ignoresSafeArea()
                        .scaledToFill()
                }
            )
    }
}


#Preview {
    MMSettingsView()
}
