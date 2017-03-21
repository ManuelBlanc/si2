#!/usr/bin/env bash

for dir in P1-*; do
	(
		cd "$dir"
		ant replegar; ant delete-pool-local
		if [[ "$dir" = "P1-base"]]; then
			ant delete-db
		else
			ant limpiar-todo
		fi
	)
done

