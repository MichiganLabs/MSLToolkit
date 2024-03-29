#!/bin/sh

# swift format/linting
brew install swiftlint
brew install swiftformat
brew install --cask swiftformat-for-xcode
brew upgrade --cask swiftformat-for-xcode

# git hook setup
brew install pre-commit
pre-commit install --hook-type pre-commit --hook-type pre-push # creates the commit hook locally