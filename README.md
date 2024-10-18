<p align="center">
  <img src="supports/icon.png" width="200" alt="Blossom">
</p>

# Blossom

Live wallpapers for non-jailbroken iOS 17.0 with TrollStore.

## How does it work?

iOS 17.0 reintroduced live photos as wallpapers, but they aren't very good.

Blossom replaces the live photo with a video of your choice that can last for 5 seconds.

Live wallpapers can be looped by repeatedly crashing the `PhotosPosterProvider` process.

### How to use

1. Create a Live Photo wallpaper in iOS. Make sure to configure widgets, clock style, etc., now, as you **cannot** edit the wallpaper afterwards.
2. Open Blossom and click "Set Wallpaper", select your recently created wallpaper and any custom video.

By default, live wallpapers play whenever you unlock the screen. You can make it loop by toggling the relevant setting in the app.

### Does it consume battery?

It uses as much battery as a normal live photo.

However, if you decide to loop the video, it`ll consume some additional battery.

### Can the video be longer than 5 seconds?

No, that's a system limitation. This is not a tweak.

## Compiling

Use `./build.sh`.

The .tipa file will be located in **/packages**.

## Credits

[TrollStore](https://github.com/opa334/TrollStore) for the respring code.

[TrollSpeed](https://github.com/Lessica/TrollSpeed) and [UIDaemon](https://github.com/limneos/UIDaemon) for AssistiveTouch code, allowing this to work in the background indefinitely.
