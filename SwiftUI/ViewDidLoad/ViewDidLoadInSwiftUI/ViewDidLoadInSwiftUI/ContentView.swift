//
//  ContentView.swift
//  ViewDidLoadInSwiftUI
//
//  Created by jiqinqiang on 2023/2/2.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("Push to Detail") {
                    Text("Detail")
                        .font(.largeTitle)
                }
                SpyView()
                    .onAppear {
                        print("onAppear")
                    }
                    .viewDidLoad {
                        print("viewDidLoad")
                    }
            }
            .font(.largeTitle)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
