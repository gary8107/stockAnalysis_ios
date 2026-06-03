# Uncomment the next line to define a global platform for your project
 platform :ios, '13.0'

target 'stockAnalysis_ios' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for stockAnalysis_ios

  pod 'Moya', '14.0.0'
  pod 'CryptoSwift', '~> 1.3.2'
  pod 'Alamofire', '~> 5.6.1'
  
  # Router
  pod 'URLNavigator', '2.3.0'
  
  # FRP
  pod 'RxSwift', '5.1.2'
  pod 'RxCocoa', '5.1.1'
  
  pod 'Moya/RxSwift', '14.0.0'
  
  # KeyChain
  pod 'KeychainAccess', '4.2.2'
  
  # Banner
  pod 'FSPagerView', '0.8.3'
  
  # textfiled
  pod "RAGTextField", '0.14.0'

  # Dialog
  pod 'SwiftMessages', '9.0.6'
  
  # PagerTab
  pod 'XLPagerTabStrip', '~> 9.0'
  
  # Image Cache
  pod 'Kingfisher', '~> 8.0'
  
  # Marquee
  pod 'MarqueeLabel', '4.3.0'
  
  # 輪播Banner
  pod 'FSPagerView', '0.8.3'

  # DropDown
  pod 'DropDown', '2.3.13'

  # IQKeyboardManager
  pod 'IQKeyboardManagerSwift', '6.5.5'
  
  # Pull-to-refresh
  pod 'MJRefresh', "3.7.5"
  
  # PopupMenu
  pod 'KxMenu', '1'
   
  #  websocket
  pod 'Starscream', '3.0.6'
  
  # Autolayout
  pod 'SnapKit', '5.6.0'

  # tabBar
  pod 'CYLTabBarController', '1.29.2'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
    end
  end
end
