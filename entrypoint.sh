#!/bin/sh
mix local.hex --force 
mix deps.get
exec "$@"
