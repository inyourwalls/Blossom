<p align="center">
  <img src="supports/icon.png" width="200" alt="Blossom">
</p>

# Update - March 2025

Come take a look at [this guide](https://gist.github.com/MWRevamped/9161837f2bda90d13c7d24e285226691); they did a good job reverse engineering PosterBoard(system wallpaper process) garbage and this method supports all iOS versions past iOS 17; not to mention you can have seamlessly looping animation.

# Blossom

Live wallpapers for non-jailbroken iOS 17.0 with TrollStore.

![preview](https://github.com/user-attachments/assets/e60ce8d4-9da1-47a9-8b53-542db70efa56)

## How does it work

iOS 17.0 reintroduced live photos as wallpapers, but they aren't very good.

Blossom replaces the live photo with a video of your choice that can last for 5 seconds.

Live wallpapers can be looped by repeatedly crashing the `PhotosPosterProvider` process.

## How to use

Download the **.tipa** file from [Releases](https://github.com/inyourwalls/Blossom/releases) page and install it in TrollStore.

1. Create a Live Photo wallpaper in iOS. Make sure to configure widgets, clock style, etc., now, as you **cannot** edit the wallpaper afterwards.

**Note:** If you encounter issues with setting a Live Photo as a wallpaper through camera roll or Photos app, you can use [apps like this one](https://apps.apple.com/de/app/video-to-live-photos-maker/id1596786737) to do so, because it's a bit bugged in iOS 17.0.

2. Open Blossom and click "Set Wallpaper", select your recently created wallpaper and any custom video.

## FAQ

### Why is this only for iOS 17.0?

The live photo as a wallpaper feature this app uses was introduced in iOS 17.0.

CoreTrust bug TrollStore uses was fixed on 17.0.1. This makes iOS 17.0 the only version this app is available on.

#### Is there no way to get custom live wallpapers on later versions?

Actually, there is. This app is just a convinient UI for replacing system files. You can replace the relevant files with `sparserestore` exploit (which was fixed too but the version range is way better).

Check [this file](https://github.com/inyourwalls/Blossom/blob/main/sources/UI/LiveWallpaperEditorView.swift) and [this file](https://github.com/inyourwalls/Blossom/blob/main/sources/Wallpaper/Wallpaper.m) to see the relevant system files and how they are edited.

To make wallpaper loop, crash the system `PhotosPosterProvider` process. That makes the "settling animation" replay itself.

This is a side project of mine and I don't have any other device to check things. I also don't really plan on making other app to do this, so if anyone else wants to tackle this task, feel free to do so.

I really don't understand why Apple made wallpapers suck so much as it's one of primary means of customization.

### I cannot create a new wallpaper

If it looks like a crash whenever you try to select a photo for the wallpaper, disable "Loop" in the app and then you'll be able to create wallpapers again.

### There are frame jumps or fade out to black

If you notice frame jumps on the last second of the video or if you notice the video fading to black for a second - you have to switch to another wallpaper, disable looping, switch back to your live wallpaper and wait for 5 seconds - and enable looping afterwards. It should fix itself.

### Does it consume battery?

It uses as much battery as a normal live photo.

However, if you decide to loop the video, it will consume some additional battery.

### My wallpaper is blank after respring

The recommended filesize for a wallpaper is 7 megabytes. If the file size is larger, iOS might not load the video for some reason.

### Can the video be longer than 5 seconds?

No, that's a system limitation. This is not a tweak.

## Compiling

Use `./build.sh`.

The .tipa file will be located in **/packages**.

## Credits

[TrollStore](https://github.com/opa334/TrollStore) for the respring code.

[TrollSpeed](https://github.com/Lessica/TrollSpeed) and [UIDaemon](https://github.com/limneos/UIDaemon) for AssistiveTouch code, allowing this to work in the background indefinitely.
