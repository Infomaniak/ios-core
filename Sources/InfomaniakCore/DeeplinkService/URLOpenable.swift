//
//  File.swift
//  
//
//  Created by Ambroise Decouttere on 28/12/2023.
//

import Foundation

public protocol URLOpenable {
    func canOpen(url: URL) -> Bool
    
    func openUrl(_ url: URL)
}
