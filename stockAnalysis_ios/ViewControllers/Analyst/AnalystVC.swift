//
//  AnalystVC.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/3.
//

import UIKit

class AnalystVC: UIViewController {

    /// 由 LoadingVC 載入後注入的股票分析資料。
    private var info: StockAnalysisInfo?

    class func instantiate(info: StockAnalysisInfo? = nil) -> AnalystVC {

        let viewController = AnalystVC()
        viewController.info = info
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
}
