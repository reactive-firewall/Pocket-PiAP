#!/usr/bin/python


import argparse
import hashlib
import hmac


def parseArgs():
	parser = argparse.ArgumentParser(description='Dangerously Simple Authentication')
	parser.add_argument(
		'-S', '--salt', default=None,
		required=False, help='The Salt. A unique secret.'
	)
	parser.add_argument(
		'-X', '--pepper', default=None,
		required=False, help='The Pepper. A global secret.'
	)
	parser.add_argument(
		'-P', '--password', default=None,
		required=False, help='The User password.'
	)
	parser.add_argument(
		'-U', '--username', default=None,
		required=False, help='The Username.'
	)
	parser.add_argument(
		'-u', '--user-id', default=None,
		required=False, help='The User ID.'
	)
	parser.add_argument(
		'-f', '--file', required=False,
		help='The database file.'
	)
	group_action = parser.add_mutually_exclusive_group()
	group_action.add_argument(
		'-A', '--add', default=False,
		action='store_true', help='add a new user'
	)
	group_action.add_argument(
		'-C', '--check', default=False,
		action='store_true', help='check for a value.'
	)
	group_action.add_argument(
		'-D', '--del', default=False,
		action='store_true', help='delete a user.'
	)
	return parser.parse_args()


def readFile(somefile):
	import os
	try:
		read_data = None
		theReadPath = str(somefile)
		with open(theReadPath, 'r') as f:
			read_data = f.read()
		f.close()
		return read_data
	except Exception:
		return None


def writeFile(somefile, somedata):
        import os
        theWritePath = str(somefile)
        try:
                with open(theWritePath, 'r+') as f:
                        read_data = f.write(somedata)
                f.close()
        except Exception:
                try:
                        f.close()
                except Exception:
                        return False
                return False
        return True


def extractRegexPattern(theInput_Str, theInputPattern):
	import re
	sourceStr = str(theInput_Str)
	prog = re.compile(theInputPattern)
	theList = prog.findall(sourceStr)
	return theList


def extractPassword(theInputID, theInputStr):
	lines = extractRawLine(theInputStr)
	for each_line in lines:
		if theInputID in each_line:
			return extractLine(str(each_line))[0][1]
	return None


def extractSalt(theInputID, theInputStr):
	lines = extractRawLine(theInputStr)
	for each_line in lines:
		if theInputID in each_line:
			return extractLine(str(each_line))[0][2]
	return None


def saltify(raw_msg, raw_salt):
	try:
		import piaplib as piaplib
		if piaplib.__name__ is None:
			raise ImportError("Failed to import native saltify from piaplib.")
		try:
			from piaplib import keyring as keyring
			if keyring.__name__ is None:
				raise ImportError("Failed to import native saltify from piaplib.")
			try:
				from keyring import saltify as saltify
				return saltify.saltify(raw_msg, raw_salt)
			except Exception as inner_import_error:
				inner_import_error = None
				del inner_import_error
		except Exception as outer_import_error:
			outer_import_error = None
			del outer_import_error
	except Exception as import_error:
		import_error = None
		del import_error
	return str(hmac.new(raw_salt, raw_msg, hashlib.sha512).hexdigest())


def extractUserID(username, pepper, theInputStr):
	target_id = str(saltify(username, pepper))
	# actualy check the database for user ID
	for each_line in extractRawLine(theInputStr):
		if str(target_id) in str(each_line):
			if str(target_id) in str(extractLine(each_line)[0][0]):
				return target_id
		continue
	return None
	

def extractLine(theInputStr):
	return extractRegexPattern(theInputStr, "(?:(?P<user_id>(?:[0-9a-fA-F]+){1})(?:[\s]{1}){1}(?P<password>(?:[0-9a-fA-F]+){1})(?:[\s]{1}){1}(?P<salt>(?:[-0-9a-zA-Z_#=\/.+]+){1})+)") # noqa


def extractRawLine(theInputStr):
	return extractRegexPattern(theInputStr, "(?P<line>(?:(?:[0-9a-fA-F]+){1})(?:[\s]{1}){1}(?:(?:[0-9a-fA-F]+){1})(?:[\s]{1}){1}(?:(?:[-0-9a-zA-Z_#=\/.+]+){1})+)") # noqa


def compactList(list, intern_func=None):
   if intern_func is None:
       def intern_func(x): return x
   seen = {}
   result = []
   for item in list:
       marker = intern_func(item)
       if marker in seen: continue
       seen[marker] = 1
       result.append(item)
   return result


def main():
	args = parseArgs()
	database_file = args.file
	if args.check:
		if args.user_id is not None and args.pepper is None:
			user_id = args.user_id
			try:
				print(extractPassword(str(user_id), str(readFile(database_file))))
			except Exception as err:
				print(str(err))
				print(str((err.args)))
				exit(1)
		elif args.user_id is not None and args.pepper is not None:
			user_id = args.user_id
			pepper = args.pepper
			try:
				print(extractSalt(str(user_id), str(readFile(database_file))))
			except Exception as err:
				print(str(err))
				print(str((err.args)))
				exit(1)
		elif args.pepper is not None and args.username is not None:
			username = args.username
			pepper = args.pepper
			try:
				print(extractUserID(str(username), str(pepper), str(readFile(database_file))))
			except Exception as err:
				print(str(err))
				print(str((err.args)))
				exit(1)
	elif args.add:
		check_input_a = ((args.username is not None) and (args.pepper is not None))
		check_input_b = ((args.salt is not None) and (args.password is not None))
		if check_input_a and check_input_b:
			try:
				user_id = saltify(args.username, args.pepper)
				password = saltify(saltify(args.password, args.salt), args.pepper)
				print(str(u'{} {} {}').format(user_id, password, args.salt))
			except Exception as err:
				print(str(err))
				print(str((err.args)))
				exit(1)
		else:
			try:
				print(str("ALL FIELDS ARE REQUIRED TO ADD USER"))
				if args.username is None:
					print(str("username is REQUIRED TO ADD USER"))
			except Exception as err:
				print(str(err))
				print(str((err.args)))
				exit(2)
	else:
		try:
			print(str("NOT IMPLEMENTED"))
		except Exception as err:
			print(str(err))
			print(str((err.args)))
			exit(2)
	exit(0)


if __name__ in '__main__':
	main()
else:
	exit(255)
