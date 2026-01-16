# Firejail profile for Zen Browser
# Seccomp sandbox for enhanced security
#
# ============================================================
# SECURITY DISABLED FOR DEVELOPMENT/LEARNING
# ============================================================
# This Firejail profile is COMMENTED OUT to allow full system access
# during initial setup and learning phase.
#
# TO ENABLE: Uncomment all lines starting with ##
# TO USE: firejail --profile=zen-browser.profile zen-browser
#
# WARNING: Zen Browser is currently UNSANDBOXED by Firejail!
# ============================================================

## FIREJAIL PROFILE DISABLED - UNCOMMENT TO ENABLE
##
## include zen-browser.local
## include globals.local
##
## # Network access required
## net none
## netfilter
##
## # Filesystem restrictions
## whitelist ${DOWNLOADS}
## whitelist ${HOME}/.zen
## whitelist ${HOME}/.cache/zen
## whitelist ${HOME}/.local/share/zen
## include whitelist-common.inc
## include whitelist-runuser-common.inc
## include whitelist-usr-share-common.inc
## include whitelist-var-common.inc
##
## # AppArmor
## apparmor
##
## # Capabilities
## caps.drop all
## ipc-namespace
## netfilter
## no3d
## nodvd
## nogroups
## noinput
## nonewprivs
## noprinters
## noroot
## nosound
## notpm
## notv
## nou2f
## novideo
## protocol unix,inet,inet6,netlink
## seccomp
## seccomp.block-secondary
## tracelog
##
## # Disable services
## disable-mnt
## private-bin zen-browser
## private-cache
## private-dev
## private-etc alternatives,ca-certificates,crypto-policies,fonts,ld.so.cache,ld.so.conf,ld.so.conf.d,ld.so.preload,localtime,machine-id,nsswitch.conf,pki,resolv.conf,ssl
## private-tmp
##
## dbus-user filter
## dbus-user.talk org.freedesktop.Notifications
## dbus-user.talk org.freedesktop.secrets
## dbus-system none
##
## memory-deny-write-execute
## restrict-namespaces
##
## END FIREJAIL PROFILE
