//
//  AddExpensesWidgetBundle.swift
//  AddExpensesWidget
//
//  Created by Adesh Hemwani on 15/02/26.
//

import WidgetKit
import SwiftUI

@main
struct AddExpensesWidgetBundle: WidgetBundle {
    var body: some Widget {
        AddExpensesWidget()
        AddExpensesWidgetControl()
        AddExpensesWidgetLiveActivity()
        MonthStatsWidget()
    }
}
