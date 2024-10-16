<p align="center">
  <img src="supports/icon.png" width="200" alt="Blossom">
</p>

# Blossom

Live wallpapers for non-jailbroken iOS 17.0 with TrollStore.

> Please note that this is for non-jailbroken TrollStore users only! If you have jailbreak, you are better off using an actual tweak, as this method relies on massive workarounds to work and has some drawbacks. They are listed below.

## How does it work?

This app replaces the live wallpaper from your camera roll with a custom video file.  Then in runs in the background, killing the `PhotosPosterProvider` process every few seconds to make the video play constantly.

### Drawbacks

1. The video cannot be too big (iOS seems to struggle loading videos larger than ~10 megabytes)
2. After 5 seconds, it becomes somehow buggy. It's best to loop the video every 5 seconds for the best result. But if you don't mind the homescreen animation being paused half the time, feel free to use a larger delay, as the lockscreen seems to work fine for about 15 seconds from my testing.
3. If you want the video to loop, there is a fade-in and fade-out animation present, which is somewhat annoying. This cannot be fixed without injecting into PosterBoard. If you do find it annoying, just replace the video and animation will play normally whenever you turn the screen on, which is already better than stock garbage playing for just one second.

### How to use?

1. Create a live wallpaper. It doesn't matter what photo you use as long as it's live.
2. Configure the widgets and other settings. **Note:** If you edit anything in the wallpaper after this step, it'll break and you'll have to do everything over again.
3. Open Blossom and click "Set Wallpaper", select your newly created wallpaper and configure the video. The device will respring and you'll see your video.
4. At this point, the video will play whenever you unlock the screen. If you want it to loop, toggle the "Loop" switch on.

### Does it consume battery?

This app just replaces the video file. It takes as much battery as a stock live wallpaper.

However, if you decide to loop the video, it might use some battery as the process will be constantly running in the background.

## Compiling

Use `./build.sh`

The .tipa file will be located in **/packages**.

## Credits

`TrollStore` for respring code.
`TrollSpeed` and `UIDaemon` for assistivetouch code, allowing this to work in background indefinitely.

#### Notes

<small>
This app is for TrollStore users only, however using `sparserestore` exploit, you are to replace the .mov file of a live wallpaper with your own.

Wallpaper could be looped without assistivetouch hack this app uses by creating an shortcut:

1. Make **two identical** wallpapers. You'll switch between them to replay the video.
2. Create an infinite loop action
3. Make the following actions inside the loop action: a delay of 5 seconds, switch the wallpaper, put another delay, and switch the wallpaper again.
4. Configure the shortcut to be launched with automations, like whenever you open some app.

The end result will look exactly the same, however it might be troublesome to have this shortcut running 24/7, but from my tests it works for a few hours before stopping.
</small>
