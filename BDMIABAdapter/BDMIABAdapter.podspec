Pod::Spec.new do |spec|
  sdkVersion        = "1.7.0.0-Beta"
  adapterVersion    = "1.7.0.0.0-Beta"
  networkVersion    = "1.1.0"
  sourceName        = "BDMIABAdapter"
  tag               = "#{sourceName}-#{adapterVersion}"

  spec.name         = "#{sourceName}"
  spec.version      = "#{adapterVersion}"
  spec.summary      = "Bidmachine adapter for IAB"
  spec.description  = <<-DESC
                      Appodeal’s supply-side platform is designed and built by veteran publishers,for publishers. Appodeal is not an ad network; it is a new approach to monetizing for publishers.
                      The platform is a large auction house, accompanied by a mediation layer, that exposes a publisher’s inventory to all available buyers on the market via relationships with every major ad network, RTB exchange, and DSP. Appodeal showcases publisher inventory to the advertiser, and offers the highest rate in real time.
                      Appodeal's goal is to cater to the needs of the publisher, not the advertiser, so you always know that you're in good hands.
                      DESC

  spec.homepage     = "https://bidmachine.io"
  spec.license      = { :type => 'GPL 3.0', :file => 'LICENSE' }
  spec.author       = { "Stack" => "https://explorestack.com/bidmachine/" }

  spec.platform     = :ios, "9.0"
  spec.source       = { :git => 'git@github.com:bidmachine/BidMachine-iOS-Adaptors.git', :tag => "v#{tag}" }


  spec.default_subspec = 'IAB'
  spec.subspec 'IAB' do |iab|
    iab.dependency "#{sourceName}/MRAID"
    iab.dependency "#{sourceName}/VAST"
    iab.dependency "#{sourceName}/NAST"
  end

  spec.subspec 'MRAID' do |mraid|
    mraid.dependency "BidMachine", "#{sdkVersion}"
    mraid.dependency "StackIAB/StackMRAIDKit", "~> #{networkVersion}"
    mraid.source_files = ["BDMIABAdapter/BDMMRAIDAdapter/*.{h,m}"]
  end

  spec.subspec 'VAST' do |vast|
    vast.dependency "BidMachine", "#{sdkVersion}"
    vast.dependency "StackIAB/StackVASTKit", "~> #{networkVersion}"
    vast.source_files = ["BDMIABAdapter/BDMVASTAdapter/*.{h,m}"]
  end

  spec.subspec 'NAST' do |nast|
    nast.dependency "BidMachine", "#{sdkVersion}"
    nast.dependency "StackIAB/StackNASTKit", "~> #{networkVersion}"
    nast.dependency "StackIAB/StackRichMedia", "~> #{networkVersion}"
    nast.source_files = ["BDMIABAdapter/BDMNASTAdapter/*.{h,m}"]
  end

  spec.static_framework         = true
  spec.pod_target_xcconfig      = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig     = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

end