This is just a project to replicate an issue I encountered on a real one I cannot share, so I replicated the same structure:
- iOS App
- iOS Share Extension
- iOS Action Extension
- Mac App

CocoaPods seems to mess it when I add these lines in 'Podfile':
```
################################
# MAC APP
target 'MacApp' do
	platform :osx, '10.10'
	base_pods
end
```

![With Mac App Target](https://raw.githubusercontent.com/lluisgerard/cocoapods-issue-mac-target/master/images/mactarget.png)

Is like, sometimes you can build the iOS app, but sometimes Extensions don't compile. Other times is only the Mac App. Either case you rearely can compile both.

Everything is fine when you remove the 'MacApp' target from the 'Podfile' (that warning is just an unrelated thing on the extension rules):
![Withput Mac App Target](https://raw.githubusercontent.com/lluisgerard/cocoapods-issue-mac-target/master/images/nomactarget.png)