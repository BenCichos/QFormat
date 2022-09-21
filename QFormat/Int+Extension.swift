//
//  Int+Extension.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Foundation

extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.hasThousandSeparators = true
        
        let number = NSNumber(integerLiteral: self)
        let formattedValue = formatter.string(from: number) ?? ""
        return formattedValue
    }
}
