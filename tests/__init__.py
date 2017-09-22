# -*- coding: utf-8 -*-

# Pocket PiAP
# ..................................
# Copyright (c) 2017, Kendrick Walls
# ..................................
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# ..........................................
# http://www.apache.org/licenses/LICENSE-2.0
# ..........................................
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

try:
	try:
		import sys
		import os
		sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), str(".."))))
	except Exception as ImportErr:
		print(str(""))
		print(str(type(ImportErr)))
		print(str(ImportErr))
		print(str((ImportErr.args)))
		print(str(""))
		ImportErr = None
		del ImportErr
		raise ImportError(str("Test module failed completely."))
	try:
		from tests import test_basic
		if test_basic.__name__ is None:
			raise ImportError(str("Test module failed to import even the basic tests."))
	except Exception as impErr:
		print(str(""))
		print(str(type(impErr)))
		print(str(impErr))
		print(str((impErr.args)))
		print(str(""))
		impErr = None
		del impErr
		raise ImportError(str("Test module failed completely."))
except Exception as badErr:
	print(str(""))
	print(str(type(badErr)))
	print(str(badErr))
	print(str((badErr.args)))
	print(str(""))
	badErr = None
	del badErr
	exit(0)

