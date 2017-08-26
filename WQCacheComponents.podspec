

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name         = "WQCacheComponents"
  s.version      = "0.0.1"
  s.summary      = "数据库缓存工具"

  s.description  = <<-DESC 
                      平常自己使用一些频率比较高得工具、控件的封装,后期使用的时候也不断维护、更新 
                    DESC

  s.homepage     = "https://github.com/wang68543/WQBaseUIComponents"

  s.license      = "MIT"
  s.author             = { "王强" => "wang68543@163.com" }
  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.platform     = :ios, "8.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source       = { :git => "https://github.com/wang68543/WQBaseUIComponents.git", :tag => "#{s.version}" }
  s.requires_arc = true
  # s.prefix_header_contents = '#import <UIKit/UIKit.h>', '#import <Foundation/Foundation.h>'
  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source_files  = "WQCacheComponents/**.{h,m}"

  s.dependency 'FMDB','~>2.7.2'
end
