TWRP installer: not written yet.

It will follow the Lomiri port installer: flash boot (7.1.13 #444), vendor_boot and dtbo-frag, grow system in the LP metadata,
write the root image from chunks, copy the proprietary firmware (modem, ADSP, GPU zap, IPA, Venus, Bluetooth, sensors) and the
Bluetooth address from the phone's own partitions (read only).
