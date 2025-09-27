# Using the Raspberry Pi Zero W as an USB Audio device

## Intro
According to this post: https://www.audiosciencereview.com/forum/index.php?threads/raspberry-pi-as-usb-to-i2s-adapter.8567/ it is possible to configure the pi into an USB audio device.
Essentially making it into a DAC/AMP.

## Configuration on the Pi
To make the Pi into an Audio device, the following steps have been performed:

```
echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
echo "dwc2" | sudo tee -a /etc/modules
echo "g_audio" | sudo tee -a /etc/modules
```

After a reboot the kernel module was configured:
`sudo modprobe g_audio c_srate=192000 c_ssize=4 p_srate=48000 p_ssize=4`

We now see the USB Audio device: `aplay -l`
```
card 1: UAC2Gadget [UAC2_Gadget], device 0: UAC2 PCM [UAC2 PCM]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```


## Problems
I have followed the post and made some progress. The Pi shows the availability of the 'UAC2Gadget' audio device. So far, so good. 
However I am not seeing the Pi as an USB device on the host machine.
