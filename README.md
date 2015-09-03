This is just a project to replicate an issue I encountered on a real one I cannot share.

CocoaPods seems to mess it when I add these lines:
```
################################
# MAC APP
target 'MacApp' do
	platform :osx, '10.10'
	base_pods
end
```

This is just a target for a Mac app. I added the platform because otherwise it complains about it.