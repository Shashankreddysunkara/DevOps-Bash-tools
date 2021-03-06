#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo namespace is now {namespace}
#
#  Author: Hari Sekhon
#  Date: 2020-09-08 19:20:40 +0100 (Tue, 08 Sep 2020)
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
Run a command against each Kubernetes namespace on the current cluster / kubectl context

Can chain with kubernetes_foreach_context.sh

DANGER: This is powerful so use carefully!

DANGER: Changes the kubectl context's default namespace - due to the way Kubectl works - this must not be run concurrently with any other kubectl based operations in any other scripts / terraform etc otherwise the Kubernetes changes may be sent to the wrong namespace! It's actually safer to script an operation to iterate on namespaces and instead of changing the default namespace in each iteration, pass the -n switch. See kubectl_rollout_history_all_deployments.sh for an example of this.

Requires 'kubectl' to be configured and available in \$PATH

All arguments become the command template

Sets the kubectl namespace on the current context in each iteration and then returns the context to the original namespace on any exit except kill -9

Replaces {namespace} if present in the command template with the namespace in each iteration, but often this isn't necessary to specify explicitly given the kubectl context's namespace is changed in each iteration for convenience running short commands local to the namespace

eg.
    ${0##*/} gcp_secrets_to_kubernetes.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

cmd_template="$*"

current_context="$(kubectl config current-context)"

# there is no -o jsonpath/namespace so must just get column
original_namespace="$(kubectl config get-contexts "$current_context" --no-headers | awk '{print $5}')"

set_namespace(){
    local namespace="$1"
    kubectl config set-context "$current_context" --namespace "$namespace"
}

while read -r namespace; do
    #if [[ "$context" =~ kube-system ]]; then
    #    echo "Skipping context '$context'..."
    #    echo
    #    continue
    #fi
    echo "# ============================================================================ #" >&2
    echo "# Kubernetest namespace = $namespace, content = $current_context" >&2
    echo "# ============================================================================ #" >&2
    # shellcheck disable=SC2064  # want interpolation now
    trap "echo; echo 'Reverting context to original namespace: $original_namespace' ; set_namespace '$original_namespace'" EXIT
    set_namespace "$namespace"
    cmd="${cmd_template//\{namespace\}/$namespace}"
    eval "$cmd"
    echo
#done < <(kubectl get namespaces -o name | sed 's,namespace/,,')
done < <(kubectl get namespaces -o 'jsonpath={range .items[*]}{.metadata.name}{"\n"}')
