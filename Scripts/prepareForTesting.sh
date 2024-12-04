#!/bin/bash

file="Package.swift"

sed -i '' 's/let resolveDependenciesForTesting = false/let resolveDependenciesForTesting = true/' "$file"

echo "$file ready for tests"
