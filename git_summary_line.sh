#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-31 19:29:38 +0100 (Tue, 31 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Prints concise git log for $PWD repo - used by all repos headers to signify their release in CI logs

set -eu #o pipefail
[ -n "${DEBUG:-}" ] && set -x

# --no-pager works around breakage in CircleCI, hangs with 'WARNING: terminal is not fully functional' (press RETURN)
git --no-pager log -n 1 --pretty=format:"%m %h  %ai  (%an)  %s"
