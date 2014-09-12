# Vangogh

Vangogh is an iOS library for testing how well an application works for people with 
various kinds of color vision deficiencies.

It lets you interact with your app as you normally would while applying one of several color
transformations to the user interface in realtime.

Tested on Xcode 5 and iOS 7


## Example

The repo comes with a simple demo that opens Flickr in a webview:

[![An example video of the demo in this repo](http://giant.gfycat.com/HelpfulAchingCoati.gif)](http://gfycat.com/HelpfulAchingCoati)

([gfycat](http://gfycat.com/HelpfulAchingCoati) for slow connections)


## Usage

1. Clone the repo with `git clone https://github.com/shilgapira/Vangogh.git`
2. Copy and add `Vangogh.h` and `Vangogh.m` to your project
3. Replace your app's `UIWindow`-based key window with an instance of `VGWindow`
4. Add an import for the `Accelerate.framework` if needed
5. Run your app and shake the device (`Cmd-Ctrl-Z` on the Simulator) to activate filtering


## Details

Vangogh uses a `CADisplayLink` to periodically take a snapshot of the running application 
and then uses the `Accelerate.framework` to multiply the image with a filter matrix. The 
resulting image is displayed in a separate window that passes through any touch events. The
framerate is capped to 30 FPS by default.

While a filter is active a details view displays the current type of color blindness and how 
common it is for males and females. You can switch filters by tapping the arrow buttons and 
pause the current filter by tapping between them. You can also limit filtering to one side of 
the screen by panning from the middle of the view to the left or right.

You can dismiss the details view by swiping it downwards. Shake the device again to stop filtering completely.

The filters are based on values from this [archived colorjack.com page](http://web.archive.org/web/20080422231727/http://www.colorjack.com/labs/colormatrix/).


## Limitations

- The details view is always shown in portrait orientation
- There might be issues when running on iOS 8 beta devices


## License

All source code is licensed under the MIT License. See the LICENSE file for more info.
