# WirePlumber Configuration for Anthonyware OS
# Audio session manager for PipeWire

monitor.alsa.properties = {
    alsa.reserve = true
}

monitor.alsa.rules = [
    {
        matches = [
            {
                node.name = "~alsa_input.*"
            }
        ]
        actions = {
            update-props = {
                node.pause-on-idle = false
                session.suspend-timeout-seconds = 0
            }
        }
    }
    {
        matches = [
            {
                node.name = "~alsa_output.*"
            }
        ]
        actions = {
            update-props = {
                node.pause-on-idle = false
                session.suspend-timeout-seconds = 0
            }
        }
    }
]

monitor.bluez.properties = {
    bluez5.enable-sbc-xq = true
    bluez5.enable-msbc = true
    bluez5.enable-hw-volume = true
    bluez5.roles = [ a2dp_sink a2dp_source bap_sink bap_source hsp_hs hsp_ag hfp_hf hfp_ag ]
}
