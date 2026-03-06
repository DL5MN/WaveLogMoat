.PHONY: build test clean run lint format release app archive changelog

build:
	swift build

app:
	xcodebuild -project WaveLogMoat.xcodeproj -scheme WaveLogMoat -configuration Debug -destination 'platform=macOS' build

archive:
	xcodebuild -project WaveLogMoat.xcodeproj -scheme WaveLogMoat -configuration Release -archivePath build/WaveLogMoat.xcarchive archive

test:
	swift test

clean:
	swift package clean

lint:
	swiftlint

format:
	swiftformat Sources Tests

release:
	xcodebuild -project WaveLogMoat.xcodeproj -scheme WaveLogMoat -configuration Release -destination 'platform=macOS' build

changelog:
	git-cliff --output CHANGELOG.md

.DEFAULT_GOAL := build
