Bash script of making live iso for CoreOS
=========================================

Usage
-----

```zsh
# clone my repository
$ git clone https://github.com/nyarla/coreos-live-iso
$ cd coreos-live-iso

# if you need to edit configuration parameter
$ vim makeiso.sh

# iso file is outputs at the same directory as makeiso.sh
$ ./makeiso.sh
```

Requirements
------------

* `bash`
* `curl`
* `tar`
* `mkisofs` (ncludes cdrtools in major distributions)

Author
------

Naoki OKAMURA (Nyarla) *nyarla[ at ]thotep.net*

Unlicense
---------

`makeiso.sh` is under the public domain.



