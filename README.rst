Pocket PiAP beta
======================

This is still in private beta. FOSS, No production support. USE AT OWN RISK.

.. image: https://img.shields.io/badge/Pocket-PiAP-fc22be.svg

.. image:: https://travis-ci.org/reactive-firewall/Pocket-PiAP.svg?branch=master
    :target: https://travis-ci.org/reactive-firewall/Pocket-PiAP

Dependencies:
-------------

.. image:: https://travis-ci.org/reactive-firewall/PiAP-python-tools.svg?branch=master
    :target: https://travis-ci.org/reactive-firewall/PiAP-python-tools

.. image:: https://travis-ci.org/reactive-firewall/PiAP-Webroot.svg?branch=master
    :target: https://travis-ci.org/reactive-firewall/PiAP-Webroot

License
-------

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

Known Issues
------------

- PS-0 -
.. image: https://img.shields.io/badge/PCWE-655-red.svg
	- User on-boarding MUST be easyer
- PS-1 -
.. image: https://img.shields.io/badge/PCWE-779-red.svg
	- logs cause data leak
- PS-2 -
.. image: https://img.shields.io/badge/PCWE-16-red.svg
	- Configuration hardening
- PS-3 -
.. image: https://img.shields.io/badge/PCWE-100-red.svg
	&
.. image: https://img.shields.io/badge/PCWE-149-red.svg
	- passwords with special charterers are courupted by input form
- PS-4 -
.. image: https://img.shields.io/badge/PCWE-654-red.svg
	- need MFA
- PS-5 -
.. image: https://img.shields.io/badge/PCWE-565-red.svg
	- need to harden cookies for surviving hostile environments
- PS-6 -
.. image: https://img.shields.io/badge/PCWE-310-red.svg
	- Need to enable proper TLS and encryption everywhere
- PS-7 -
.. image: https://img.shields.io/badge/PCWE-770-red.svg
	- need anti-brute force logic

CWE-657 - see above


Possible Improvements:
---------------------
- always more
- fix CVE-2007-6750 false positive
- fix normilization error
- harden ntp
- add encryption and file signing
- add more examples to docs
