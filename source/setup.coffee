# Use Jadelet lib if system is not already required
#
# This is so Prometheus can show the View demos for this package since we don't
# depend on ourselves for `!system`
# This file can go away if we set .jadelet compiler to use
# 'require("/lib/jadelet")' rather than system.ui.Jadelet
#
# TODO: Re-examine how we set template deps in Prometheus
global.system ?= {}
global.system.ui ?= {}
global.system.ui.Jadelet ?= require("./lib/jadelet")
