#!/bin/bash
rgName=$1
rgName=${rgName:="test"}
mkdir ../build

az bicep build -f ../infrastructure/main.bicep --outfile ../build/main.json

az deployment group validate -g ${rgName:-test} --template-file ../build/main.json -p ../infrastructure/main.parameters.json
