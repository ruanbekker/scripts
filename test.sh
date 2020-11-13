#!/usr/bin/env bash
echo '#!/bin/bash' > /usr/local/bin/testing
echo 'echo hi' > /usr/local/bin/testing
chmod +x /usr/local/bin/testing 
