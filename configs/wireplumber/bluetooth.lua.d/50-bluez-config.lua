# WirePlumber Bluetooth Configuration

monitor.bluez.rules = [
    {
        matches = [
            {
                ## This matches all bluetooth devices
                device.name = "~bluez_card.*"
            }
        ]
        actions = {
            update-props = {
                ## Auto-connect to previously paired devices
                bluez5.auto-connect = [ hfp_hf hsp_hs a2dp_sink hfp_ag hsp_ag a2dp_source ]
                
                ## Enable higher quality SBC codec
                bluez5.enable-sbc-xq = true
                
                ## Enable mSBC for better call quality
                bluez5.enable-msbc = true
                
                ## Enable hardware volume control
                bluez5.enable-hw-volume = true
                
                ## Use hardware volume for headset
                bluez5.headset-roles = [ hsp_hs hsp_ag hfp_hf hfp_ag ]
            }
        }
    }
]
