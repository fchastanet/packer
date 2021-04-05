#!/bin/bash

# If not running interactively, don't do anything
# normally bash_profile should have been loaded
case $- in
    *i*) ;;
      *) return;;
esac

# .bashrc is executed for an interactive non-login shell
# Put the commands that should run every time you launch
# a new shell in the .bashrc file.
# This include your aliases and functions,
# custom prompts, history customizations , and so on.

source "${HOME}/.bashrc_default"
