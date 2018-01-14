#### jump-util-base

jump-util-base repo is a systemd utility container with personal
security credentials using ssh keys for secure access and assumes some
form of LoadBalancer and LoadBalancerIP or routing into the cluster to
make simplest use of this allowing the service to be accessed directly
from outside of the cluster.

The image does not contain any keys. Keys are injected at runtime via
the kubernetes secret to mount a secret volume to the runtime user's
home directory in the container in `${HOME}/${JUMP_USER}/ssh/` which
is used to populate the container users `.ssh/` with
`authorized_key`. The permissions are updated by the startup script
run.sh

The jump container uses the userid specified in the environment
variable `JUMP_USER` in templates called by `make  deploy` target in the
Makefile

The configuration assumes that the current user owns the container and
wants to restrict access using ssh key only login with the user named
by `JUMP_USER` and the private key `.ssh/id_rsa`. For a shared login,
selecting a shared key `.pub` file should be configured in the secrets
file template `authorized_keys`.

The current configuration requires setting 2 environment variables:

- JUMP_USER
- PUBLIC_KEY_FILE


This project uses a golang template processing utility to update the
configuration and depends on environment variables `PUBLIC_KEY_FILE`
and `JUMP_USER`

Environment variables are referenced as camel case in template double
curly braces like `PUBLIC_KEY_FILE` referenced as `{{ .PublicKeyFile
}}` and `JUMP_USER` referenced as `{{ .JumpUser }}`

The golang template text processing utility used is
`github.com/davidwalter0/applytmpl`

```
authorized_keys: '{{ file2string .PublicKeyFile  | base64Encode }}'
```

JUMP_USER environment variable should be set in the Makefile or with
export JUMP_USER. The template systemd/daemonset.yaml.tmpl
systemd/deploy.yaml.tmpl create secret using an authorized_keys file
from the user's home directory

example template use:

```
authorized_keys: '{{ file2string .PublicKeyFile  | base64Encode }}'
```

example environment variable setup:

```
export DOCKER_USER=hub.docker.com-uid
export JUMP_USER=jump-user
export PUBLIC_KEY_FILE=${HOME}/.ssh/id_rsa.pub
make image push tag-push deploy push
```

---
### TCP connection support

Running a jump server in cluster for debugging with ssh can be done as
well, like `github.com/davidwalter0/jump-base-systemd` and running an
instance.


```
host jump
     hostname 192.168.0.222
     user jump-user
     port 2222
     IdentityFile ~/.ssh/id_rsa
```
