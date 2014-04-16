Introduction
============

Hiera is a configuration data store with pluggable back ends; hiera-pprofile is a yaml backend that build a dynamic hierarchy based on the profile classed the node has assigned.

The node-classes information is obtained with a puppetdb query.

The basic idea is to be able to link the code/data separation and the role/profile design patterns.

I wrote this module since I wanted to be able to use the merge functionality of Hiera and set module parameters at different levels: for example, linux kernel parameter net.ipv4_forward (in sysctl.conf) may be set from all hosts (in hiera global.yamli file) while kernel parameters net.core.[rw]mem_max may need to be setup differently based on profile (e.g. for a web server).

The backend code is based on original yaml backend code and few lines of code from puppetdbquery module.


Configuration
=============
Here is a sample hiera.yaml file that will work with hiera_pprofile

<pre>
---
    :backends:
      - pprofile
    :hierarchy:
      - defaults
    #  - "%{clientcert}"
      - "%{environment}"
      - global
    
    :yaml:
    # datadir is empty here, so hiera uses its defaults:
    # - /var/lib/hiera on *nix
    # - %CommonAppData%\PuppetLabs\hiera\var on Windows
    # When specifying a datadir, make sure the directory exists.
      :datadir: "/etc/puppet/hiera/%{environment}/hieradata"
    
    :pprofile:
    # datadir is empty here, so hiera uses its defaults:
    # - /var/lib/hiera on *nix
    # - %CommonAppData%\PuppetLabs\hiera\var on Windows
    # When specifying a datadir, make sure the directory exists.
      :datadir: "/etc/puppet/hiera/%{environment}/hieradata"
    
    :merge_behavior: deeper
</pre>



Limitations
============

It is not possible at this moment to alterate the order of items in the hierarchy: right now, the hierarchy is constructed with items in configuration file, followed by dynamically generated profiles in literal order.

The backend was not tested with remote puppetdb

Contact
=======

* Author: Virgil Chereches
* Email: virgil.chereches@gmx.net

Credit
=======



License
=======
Apache License, Version 2.0
