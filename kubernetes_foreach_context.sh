#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo context is now {context}
#
#  Author: Hari Sekhon
#  Date: 2020-08-26 16:18:30 +0100 (Wed, 26 Aug 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command against each configured Kubernetes kubectl context (cluster)

Can chain with kubernetes_foreach_namespace.sh

DANGER: This is powerful so use carefully!

DANGER: Changes the kubectl context - due to the way Kubectl works - this must not be run concurrently with any other kubectl based operations in any other scripts / terraform etc otherwise the Kubernetes changes may be sent to the wrong cluster! Discovered this the hard way by a colleague who write imperative Terraform with kubectl :-/

See Also: gke_kube_creds.sh to auto-create all your contexts for all clusters on Google Kubernetes Engine!

Requires 'kubectl' to be configured and available in \$PATH

All arguments become the command template

Sets the kubectl context in each iteration and then returns the context to the original context on any exit except kill -9

Replaces {context} if present in the command template with the current kubectl context name in each iteration, but often this isn't necessary to specify explicitly given the kubectl context is changed in each iteration for each context for convenience running short commands local to the context

eg.
    ${0##*/} kubectl get pods

Since lab contexts like Docker Desktop, Minikube etc are often offline and likely to hang, they are skipped. Deleted GKE clusters you'll need to remove from your kubeconfig yourself before calling this
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

cmd_template="$*"

original_context="$(kubectl config current-context)"

while read -r context; do
    if [[ "$context" =~ docker|minikube|minishift ]]; then
        echo "Skipping context '$context'..."
        echo
        continue
    fi
    echo "# ============================================================================ #" >&2
    echo "# Kubernetest context = $context" >&2
    echo "# ============================================================================ #" >&2
    # shellcheck disable=SC2064  # want interpolation now
    trap "echo; echo 'Reverting to original context:' ; kubectl config use-context '$original_context'" EXIT
    kubectl config use-context "$context"
    cmd="${cmd_template//\{context\}/$context}"
    eval "$cmd"
    echo
done < <(kubectl config get-contexts -o name)
