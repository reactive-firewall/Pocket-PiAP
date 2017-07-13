# Pocket PiAP beta

## Status

![Pocket-PiAP](https://img.shields.io/badge/Pocket-PiAP-fc22be.svg)

[![Build Status](https://travis-ci.org/reactive-firewall/Pocket-PiAP.svg?branch=master)](https://travis-ci.org/reactive-firewall/Pocket-PiAP)
[![Code Coverage](https://codecov.io/gh/reactive-firewall/Pocket-PiAP/branch/stable/graph/badge.svg)](https://codecov.io/gh/reactive-firewall/Pocket-PiAP)


### Dependencies:

#### Python Tools

[![Build Status](https://travis-ci.org/reactive-firewall/PiAP-python-tools.svg?branch=stable)](https://travis-ci.org/reactive-firewall/PiAP-python-tools)
[![Dependency Status](https://www.versioneye.com/user/projects/5961fc36368b08002a056e48/badge.svg?style=flat-round)](https://www.versioneye.com/user/projects/5961fc36368b08002a056e48)
[![Code Coverage](https://codecov.io/gh/reactive-firewall/PiAP-python-tools/branch/stable/graph/badge.svg)](https://codecov.io/gh/reactive-firewall/PiAP-python-tools/branch/stable/)

#### Web UI

[![Build Status](https://travis-ci.org/reactive-firewall/PiAP-Webroot.svg?branch=stable)](https://travis-ci.org/reactive-firewall/PiAP-Webroot)

# Pocket PiAP is still in private beta. FOSS under heavy development, No production support at this time. USE AT OWN RISK.

### License

Copyright (c) 2017 Mr. Walls

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

### _Paranoia is a virtue_

In security perfection is rarely possible and almost certainly not practical. Defensive security comes down to risk management. `Pocket PiAP` is designed to _aspire_ to the following approach:

#### 1. `Pocket PiAP` aims to protect:

##### itself

###### * System Resources
_(Get your hand out of my `Pocket`)_
###### * System Connectivity
_(Wearing camo and serving human overlords does not mean registering for the bot-net draft)_
###### * System Data
_(Like a bag of water, `Pockets` are no good with lots of holes)_

##### Its clients

###### * Network Demarcation
_(Pay no attention to the system behind the `pocket`)_
###### * Network Trust
_(`pockets` should not set your pants on fire with lies)_
###### * Client Data
_(No one likes a pick-`pocket`)_

##### Their Interests

###### * User Dignity
_(Security should be ethical)_
###### * Entropy
_(Seriously how secure is your first guess?)_
###### * Usability
_(Security should be used)_

#### 2. `Pocket PiAP` is thus threatened:

##### Directly...

###### ...by threats to System Resources
 - loss of control of the `Pocket PiAP` (infection)
 - loss of use of the `Pocket PiAP` (dos)
 - loss of the `Pocket PiAP` (theft)
###### ...by threats to System Connectivity
 - loss of control of the `Pocket PiAP`'s connections (hijacking)
 - impersonation of the `Pocket PiAP`'s connections (spoofing)
 - loss of exclusive use of the `Pocket PiAP` (unauthorized access)
###### ...by threats to System Data
 - loss of exclusive use of data on the `Pocket PiAP` (data loss)
 - loss of data verification on the `Pocket PiAP` (data corruption)
 - exposure of data on the `Pocket PiAP` (data leak)

##### Indirectly...

###### ...by direct threats to the Clients
 - directly from by external adversaries (intrusion)
 - directly from by internal adversaries (treachery)
 - by hostile privileged users (abuse)
###### ...by indirect threats to the Clients
 - indirectly from by external adversaries (side-channel)
 - indirectly from by internal adversaries (broken clients)
 - indirectly from environmental factors (cas fortuit)
###### ...by threats to the Network
 - malicious control of network resources (rouge access points)
 - impersonation of indirect network resources (redirection)
 - impersonation of direct network resources (spoofing)
###### ...by threats to the Client Data
 - exposure of data in transit (data leak)
 - exposure of data at rest (data theft)
 - loss of data at rest (data loss)
 - loss of data in transit (data loss)

##### and by _Meta_ ...

###### ...by threats to meta-data
 - exposure of meta-Data (Connecting the dots)
 - persistent creation of meta-data (data mining)
 - exposure of data in protected form (meta-analysis)
 - loss of control of data (data mining)
 
###### ...by threats to assumptions
 - incorrect design for a given assumption (just covering all bases here?)
 - any external points of trust that are untrustworthy (no good options)
 - still in use after becoming obsolete (hardware failure)
 - any successful social engineering of clients (user failure)
 - the unenumerated unknown (that which is not known to be unknown)

#### 3. `Pocket PiAP` Risk assessment:

##### ... TO DO ...

##### 1. Cryptographic Algorithm choices:

##### this part is incomplete

1.1 `Curve25519` is the default Eliptic-curve algorithm to be used by `Pocket PiAP` to defeat integer factorization attacks.
 a. Due to findings that some Eliptic-curve algorithms are known to be insecure [SafeCurves] only likely secure algorithms shall be selected for use by `Pocket PiAP` to protect it's data in transit.
 b. diversity of use with regards to Eliptic-curve algorithms to promote defense in depth is still encouraged.
 c. Eliptic-curve algorithms used for cryptography or `ECC` must meet both ECDLP security and ECC security criteria to be considered theoreticly secure for use by `Pocket PiAP`.

[SafeCurves]: https://safecurves.cr.yp.to (Daniel J. Bernstein and Tanja Lange. SafeCurves: choosing safe curves for elliptic-curve cryptography. https://safecurves.cr.yp.to, accessed June 23 2017)

#### Known Issues and Possible Improvements

- see [Issues](https://github.com/reactive-firewall/Pocket-PiAP/issues)

#### Reporting Issues and Bugs

Please open an [Issue](https://github.com/reactive-firewall/Pocket-PiAP/issues) if one does not
exist.

When opening an issue at a minimum please include details on
 - how to reproduce the problem (if practical)
 - any possible workarounds (if known)

Additionally:
 - patches are welcome (please patch against latest `stable` branch)
 - test cases are helpful
 - please note submitted code should have a credit line if not intended to be released under `Pocket PiAP`'s license (a pen name can be used to remain anonymous if so desired)
 - submitted code is not guaranteed to be accepted

#### Reporting practical exploits and vulnerabilities

Be ethical, and be patient. `Pocket PiAP` IS STILL IN A PRIVATE BETA. If the security flaw is not fixed before the public beta more instructions are intended to be added here (at an indeterminate later time) to allow responsible discloser of such flaws.

 - due to lack of funding reporting rewards are limited only to placement on the ongoing hall of fame bug hunter list. (after a two week lead time)
 
# Ongoing hall of fame bug hunter list:
 1. Anonymous Researcher - (April 2017)
  - Reported first externaly discoveredbug.
  - found several bugs involving CWE-20
 2. Anonymous Researcher - (May 2017)
  - Found timing analysis bug that allowed enumeration of valid users on login page.
 
#### Joining the Private Beta

Please open an [Issue](https://github.com/reactive-firewall/Pocket-PiAP/issues) and request to join the private Beta.

 - Currently instructions to assemble a prototype system to run `Pocket AP` are constantly changing and thus are still a TO-DO item.


