//
//  TabView.swift
//  Runner
//
//  Created by Koichi Kishimoto on 2024/11/04.
//

import SwiftUI

struct HomeTabView: View {
    var body: some View {
        TabView {
            BookListView()
                .tabItem {
                    Text("Book List")
                }.tag(1)
            RecordListView()
                .tabItem {
                    Text("Record List")
                }
                .tag(2)
        }
    }
}
