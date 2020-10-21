Pod::Spec.new do |spec|
  sdkVersion        = "1.6.1"
  adapterVersion    = "0"
  networkVersion    = "0.6.0"
  sourceName        = "BDMVASTAdapter"
  tag               = "#{sourceName}-#{sdkVersion}.#{adapterVersion}"

  spec.name         = "#{sourceName}"
  spec.version      = "#{sdkVersion}.#{adapterVersion}"
  spec.summary      = "Bidmachine adapter for VAST"
  spec.description  = <<-DESC
                      Appodeal’s supply-side platform is designed and built by veteran publishers,for publishers. Appodeal is not an ad network; it is a new approach to monetizing for publishers.
                      The platform is a large auction house, accompanied by a mediation layer, that exposes a publisher’s inventory to all available buyers on the market via relationships with every major ad network, RTB exchange, and DSP. Appodeal showcases publisher inventory to the advertiser, and offers the highest rate in real time.
                      Appodeal's goal is to cater to the needs of the publisher, not the advertiser, so you always know that you're in good hands.
                      DESC

  spec.homepage     = "https://bidmachine.io"
  spec.license      = { :type => 'GPL 3.0', :file => 'LICENSE' }
  spec.author       = { "Stack" => "https://explorestack.com/bidmachine/" }

  spec.platform     = :ios, "9.0"
  spec.source       = { :git => 'git@github.com:bidmachine/BidMachine-iOS-Adaptors.git', :tag => "#{tag}" }
  spec.source_files = "#{sourceName}/*.{h,m}"

  spec.dependency "BidMachine", "#{sdkVersion}"
  spec.dependency "StackIAB/StackVASTKit", "~> #{networkVersion}"

end