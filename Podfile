source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

# Shared pods
def base_pods

	# Autolayout
	pod 'SnapKit'

	# Coding and debugging
	pod 'XCGLogger'

end

################################
# iOS App

target 'appWithExtensions' do
	platform :ios, '8.0'
	base_pods
	# Extra for this extension:
	pod 'FontAwesome.swift'
end

################################
# APP Extensions

# iOS SHARE EXTENSION
target 'ShareExtension' do
	platform :ios, '8.0'	
	base_pods
end

# iOS ACTION EXTENSION
target 'ActionExtension' do
	platform :ios, '8.0'	
	base_pods
end

################################
# MAC APP
target 'MacApp' do
	platform :osx, '10.10'
	base_pods
end