<p align="center">
  <img src="supports/icon.png" width="200" alt="Blossom">
</p>

# Blossom

Live wallpapers for non-jailbroken iOS 17.0 with TrollStore.

![preview](https://github.com/user-attachments/assets/e60ce8d4-9da1-47a9-8b53-542db70efa56)

## How does it work

iOS 17.0 reintroduced live photos as wallpapers, but they aren't very good.

Blossom replaces the live photo with a video of your choice that can last for 5 seconds.

Live wallpapers can be looped by repeatedly crashing the `PhotosPosterProvider` process.

## How to use

Download the **.tipa** file from [Releases](https://github.com/inyourwalls/Blossom/releases) page and install it in TrollStore.

1. Crop your video to your phone screen resolution beforehand, and trim it to exactly 5 seconds. See the video guide below:

https://github.com/user-attachments/assets/361c9bbe-9788-44d6-b501-de690fff9144

2. Create a Live Photo wallpaper in iOS. Make sure to configure widgets, clock style, etc., now, as you **cannot** edit the wallpaper afterwards.
3. Open Blossom and click "Set Wallpaper", select your recently created wallpaper and any custom video.

> By default, live wallpapers play whenever you unlock the screen. You can make it loop by toggling the relevant setting in the app.

## FAQ

### I cannot create a new wallpaper

If it looks like a crash whenever you try to select a photo for the wallpaper, disable "Loop" in the app and then you'll be able to create wallpapers again.

### There are frame jumps or fade out to black

If you notice frame jumps on the last second of the video or if you notice the video fading to black for a second - you have to switch to another wallpaper, disable looping, switch back to your live wallpaper and wait for 5 seconds - and enable looping afterwards. It should fix itself.

### Does it consume battery?

It uses as much battery as a normal live photo.

However, if you decide to loop the video, it will consume some additional battery.

### Can the video be longer than 5 seconds?

No, that's a system limitation. This is not a tweak.

## Compiling

Use `./build.sh`.

The .tipa file will be located in **/packages**.

## Credits

[TrollStore](https://github.com/opa334/TrollStore) for the respring code.

[TrollSpeed](https://github.com/Lessica/TrollSpeed) and [UIDaemon](https://github.com/limneos/UIDaemon) for AssistiveTouch code, allowing this to work in the background indefinitely.
