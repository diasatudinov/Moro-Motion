//
//  ZZAchievementsViewModel.swift
//  Moro Motion
//
//  Created by Dias Atudinov on 25.10.2025.
//


import SwiftUI

class ZZAchievementsViewModel: ObservableObject {
    
    @Published var achievements: [NEGAchievement] = [
        NEGAchievement(image: "achieve1ImageMM", title: "achieve1TextMM", isAchieved: false),
        NEGAchievement(image: "achieve2ImageMM", title: "achieve2TextMM", isAchieved: false),
        NEGAchievement(image: "achieve3ImageMM", title: "achieve3TextMM", isAchieved: false),
        NEGAchievement(image: "achieve4ImageMM", title: "achieve4TextMM", isAchieved: false),
        NEGAchievement(image: "achieve5ImageMM", title: "achieve5TextMM", isAchieved: false),
    ] {
        didSet {
            saveAchievementsItem()
        }
    }
        
    init() {
        loadAchievementsItem()
    }
    
    private let userDefaultsAchievementsKey = "achievementsKeyMD"
    
    func achieveToggle(_ achive: NEGAchievement) {
        guard let index = achievements.firstIndex(where: { $0.id == achive.id })
        else {
            return
        }
        achievements[index].isAchieved.toggle()
        
    }
   
    
    
    func saveAchievementsItem() {
        if let encodedData = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsAchievementsKey)
        }
        
    }
    
    func loadAchievementsItem() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsAchievementsKey),
           let loadedItem = try? JSONDecoder().decode([NEGAchievement].self, from: savedData) {
            achievements = loadedItem
        } else {
            print("No saved data found")
        }
    }
}

struct NEGAchievement: Codable, Hashable, Identifiable {
    var id = UUID()
    var image: String
    var title: String
    var isAchieved: Bool
}
