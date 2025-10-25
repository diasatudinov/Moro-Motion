//
//  CPSettingsViewModel.swift
//  Moro Motion
//
//  Created by Dias Atudinov on 25.10.2025.
//


import SwiftUI

class CPSettingsViewModel: ObservableObject {
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("vibraEnabled") var vibraEnabled: Bool = true
}
