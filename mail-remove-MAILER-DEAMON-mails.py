#!/usr/bin/env python

import re
from commands import getoutput

i = 0
for e in re.split(r'\n\n', getoutput('mailq | sed -e \'1d\'')):
        if re.search(r'MAILER-DAEMON', e):
                m = re.match(r'\w+', e)
                i = i + 1
                print getoutput('postsuper -d ' + m.group())

print '\nRemoved ' + str(i) + ' messages'
