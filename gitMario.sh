#!/usr/bin/env bash

cat > ~/.gitconfig <<EOF
[user]
	name = Misterk12
	email = mario.pascualn@estudiante.uam.es
[push]
	default = current
[color]
	ui = true
	diff = auto
	status = auto
	branch = auto
[alias]
	# Log
	l = log --oneline
	ll = log --date=short --pretty=format:'%C(blue)%ad%Creset %C(yellow)%h%Creset %<(80,trunc)%s'
	lll = log --all --graph --pretty=format:'%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)<%an>%Creset %C(yellow)%d%Creset'
	fl = log --stat --oneline
	fll = log -p --oneline
	hist = log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short
	last = log -1 --pretty=fuller --stat
	# Rest
	aa = add .
	aaa = add -A .
	br = branch -vv
	bra = branch -vva
	ci = commit
	cim = commit -m
	cp = cherry-pick
	co = checkout
	cob = checkout -b
	df = diff
	dfc = diff --cached
	put = push --follow-tags
	re = remote -v
	rb = rebase -i
	rmc = rm --cached
	st = status -sb
	# Util
	lsu = ls-files --others --exclude-standard
	ii = ls-files --stage -t --full-name --abbrev=7
	type = cat-file -t
	dump = cat-file -p
[credential]
	helper = cache --timeout=14400
EOF

echo "It's me, Mario!"
