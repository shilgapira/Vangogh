Pod::Spec.new do |s|

  s.name         = "Vangogh"
  s.version      = "0.0.1"
  s.summary      = "Vangogh helps you test accessibility"

  s.description  = <<-DESC
                   Vangogh is an iOS library for testing how well an application works for people with various kinds of color vision deficiencies.
                   Vangogh uses a CADisplayLink to periodically take a snapshot of the running application and then uses the Accelerate.framework to multiply the image with a filter matrix. The resulting image is displayed in a separate window that passes through any touch events. The framerate is capped to 30 FPS by default.
                   DESC

  s.homepage     = "https://github.com/cocoaplayground/Vangogh"
  #s.screenshots  = "http://gfycat.com/HelpfulAchingCoati,gif"
  s.license      = "MIT"
  
  s.author       = { "Gil Shapira" => "http://gil.sh" }
 
  s.platform     = :ios
  s.platform     = :ios, "7.0"
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "git@github.com:shilgapira/Vangogh.git", :tag =>s.version.to_s }

  s.source_files  = "Sources/Vangogh", "Sources/Vangogh.{h,m}"
  s.public_header_files = "Classes/**/*.h"

  s.framework  = "Accelerate"
  s.requires_arc = true

end
