#!/bin/bash

# .bash_profile is read and executed when Bash is invoked
# as an interactive login shell, the first time you logged in.
# Use .bash_profile to run commands that should run only once,
# such as customizing the $PATH environment variable.

source "${HOME}/.bash_profile_default"

# add your own commands in it
export TIMEZONE="Europe/Paris"
