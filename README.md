Introduction
============

Hiera is a configuration data store with pluggable back ends; hiera-roleprofile is a yaml backend that build a dynamic hierarchy based on the profile and role classes assigned to the node.

The node-classes information is obtained with a puppetdb query.

The basic idea is to be able to link the code/data separation and the role/profile design patterns.

I wrote this module since I wanted to be able to use the merge functionality of Hiera and set module parameters at different levels: for example, linux kernel parameter net.ipv4_forward (in sysctl.conf) may be set from all hosts (in hiera global.yamli file) while kernel parameters net.core.[rw]mem_max may need to be setup differently based on profile (e.g. for a web server).

The backend code is based on original yaml backend code and few lines of code from puppetdbquery module.


Configuration
=============
Here is a sample hiera.yaml file that will work with hiera_roleprofile

<pre>
---
    :backends:
      - roleprofile
    :hierarchy:
      - defaults
      - "%{clientcert}"
      - "%{environment}"
      - global
    
    :roleprofile:
    # datadir is empty here, so hiera uses its defaults:
    # - /var/lib/hiera on *nix
    # - %CommonAppData%\PuppetLabs\hiera\var on Windows
    # When specifying a datadir, make sure the directory exists.
      :datadir: "/etc/puppet/hiera/%{environment}/hieradata"
    
    :merge_behavior: deeper
</pre>


Example
========

If we have a node with the following puppet class attached via ENC: role::webserver and if the role::webserver class has the following code:

<pre>
class role::webserver {
  include profile::apache
  include profile::php
  include profile::mysql
}

the dynamic generated hierarchy will be : ["role/webserver", "profile/apache", "profile/mysql", "profile/php", "defaults", "%{clientcert}", "%{environment}", "global"]


Limitations
============

It is not possible at this moment to alterate the order of items in the hierarchy: right now, the hierarchy is constructed with dynamically generated role yamls first (in /etc/puppet/hiera/%{environment}/hieradata/role dir), profile yamls (in /etc/puppet/hiera/%{environment}/hieradata/profile), followed by items in the standard hierarchy in the configuration file.

The backend was tested with remote puppetdb

Contact
=======

* Author: Virgil Chereches
* Email: virgil.chereches@gmx.net

Credit
=======



License
=======
Apache License, Version 2.0
