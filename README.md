# Copycfg #

Copies and and manages shares of host configuration data.

## Synopsis ##

    copycfg -c config [ -a share | unshare | copy ] [ -n netgroup ] [ --host hostname ]

## Examples ##

Copy all configurations from all hosts in a netgroup

    copycfg -c config.yaml -a copy -n all-sys

Copy all configurations from two netgroups and a host, then share them

    copycfg -c config.yaml -a copy -a share -n some-sys -n other-sys --host one-system

