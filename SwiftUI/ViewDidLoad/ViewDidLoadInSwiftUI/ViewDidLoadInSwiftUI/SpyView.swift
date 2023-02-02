//
//  SpyView.swift
//  ViewDidLoadInSwiftUI
//
//  Created by jiqinqiang on 2023/2/2.
//

import SwiftUI

struct ViewDidLoadModifier: ViewModifier {
    
    @State private var viewDidLoad = false
    
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if viewDidLoad == false {
                    viewDidLoad = true
                    action?()
                }
            }
    }
}

extension View {
    func viewDidLoad(perform action: (() -> Void)? = nil) -> some View {
        return modifier(ViewDidLoadModifier(action: action))
    }
}

struct SpyView: View {
    
    @State private var viewDidLoad = false
    
    var body: some View {
        Text("Spy")
    }
}

struct SpyView_Previews: PreviewProvider {
    static var previews: some View {
        SpyView()
    }
}
