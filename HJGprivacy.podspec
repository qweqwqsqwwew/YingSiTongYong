#
#  Be sure to run `pod spec lint hjgp.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

s.name         = "HJGprivacy"
s.version      = "1.0.2"
s.summary      = "自动集成隐私政策"
s.description  = <<-DESC
自动集成隐私政策。
DESC
s.homepage     = "https://github.com/huangjianguohjg/YingSiTongYong"
s.license      = { :type => "MIT", :file => "LICENSE" }
s.author             = { "xiaohuang" => "hjgguge@gmail.com" }
s.platform     = :ios, "8.0"
s.source       = { :git => "https://github.com/huangjianguohjg/YingSiTongYong.git", :tag => s.version }
s.source_files  = "Classes", "YinSi"
s.resource_bundles = {
  'HJGprivacy' => ['YinSi/*.html']
}
s.requires_arc = true

end
