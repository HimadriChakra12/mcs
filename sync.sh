#!bin/bash

rm -rf $(pwd)/data/server.properties
rm -rf $(pwd)/data/mods

cp -rf $(pwd)/config/server.properties $(pwd)/data/server.properties
cp -rf $(pwd)/config/mods $(pwd)/data/mods

ls $(pwd)/data/server.properties
ls $(pwd)/data/mods
