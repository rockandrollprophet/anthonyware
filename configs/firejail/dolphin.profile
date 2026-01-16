# Firejail profile for Dolphin File Manager
# Reduced restrictions for file manager functionality
#
# ============================================================
# SECURITY DISABLED FOR DEVELOPMENT/LEARNING
# ============================================================
# This Firejail profile is COMMENTED OUT to allow full system access
# during initial setup and learning phase.
#
# TO ENABLE: Uncomment all lines starting with ##
# TO USE: firejail --profile=dolphin.profile dolphin
#
# WARNING: Dolphin is currently UNSANDBOXED by Firejail!
# ============================================================

## FIREJAIL PROFILE DISABLED - UNCOMMENT TO ENABLE
##
## include dolphin.local
## include globals.local
##
## # Network access for KIO slaves
## netfilter
##
## # Filesystem access - file manager needs broad access
## noblacklist ${HOME}
## whitelist ${HOME}
## include whitelist-common.inc
## include whitelist-runuser-common.inc
## include whitelist-usr-share-common.inc
## include whitelist-var-common.inc
##
## # Allow removable media
## noblacklist /media
## noblacklist /mnt
## noblacklist /run/media
##
## # AppArmor
## apparmor
##
## # Capabilities - reduced restrictions
## caps.drop all
## ipc-namespace
## netfilter
## nodvd
## nonewprivs
## noroot
## notpm
## notv
## protocol unix,inet,inet6,netlink
## seccomp
## tracelog
##
## # Private directories
## private-cache
## private-tmp
##
## # D-Bus access for KDE integration
## dbus-user filter
## dbus-user.talk org.kde.*
## dbus-user.talk org.freedesktop.FileManager1
## dbus-user.talk org.freedesktop.Notifications
## dbus-system filter
##
## # Allow access to mounted devices
## ignore private-dev
##
## END FIREJAIL PROFILE
