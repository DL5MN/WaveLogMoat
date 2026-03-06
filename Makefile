.PHONY: build test clean run lint format release app archive changelog open

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

open:
	open "$$(xcodebuild -project WaveLogMoat.xcodeproj -scheme WaveLogMoat -configuration Debug -showBuildSettings 2>/dev/null | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $$NF}')/WaveLogMoat.app"

changelog:
	git-cliff --output CHANGELOG.md

.DEFAULT_GOAL := build
