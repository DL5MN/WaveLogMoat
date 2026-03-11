.PHONY: build test clean run lint format check release release-build app archive changelog open

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
	swift format lint --strict -r -p Sources Tests

format:
	swift format -i -r -p Sources Tests

check: format lint test

release-build:
	xcodebuild -project WaveLogMoat.xcodeproj -scheme WaveLogMoat -configuration Release -destination 'platform=macOS' build

release:
ifndef VERSION
	$(error Usage: make release VERSION=0.1.0)
endif
	@if [ -n "$$(git status --porcelain)" ]; then echo "Error: working tree is dirty"; exit 1; fi
	@if git rev-parse "v$(VERSION)" >/dev/null 2>&1; then echo "Error: tag v$(VERSION) already exists"; exit 1; fi
	@sed -i '' '/CFBundleShortVersionString/{n;s|<string>.*</string>|<string>$(VERSION)</string>|;}' Sources/WaveLogMoat/Info.plist
	$(eval CURRENT_BUILD := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleVersion" Sources/WaveLogMoat/Info.plist))
	$(eval NEXT_BUILD := $(shell echo $$(( $(CURRENT_BUILD) + 1 ))))
	@sed -i '' '/CFBundleVersion/{n;s|<string>.*</string>|<string>$(NEXT_BUILD)</string>|;}' Sources/WaveLogMoat/Info.plist
	@sed -i '' 's|CFBundleShortVersionString: ".*"|CFBundleShortVersionString: "$(VERSION)"|' project.yml
	@sed -i '' 's|CFBundleVersion: ".*"|CFBundleVersion: "$(NEXT_BUILD)"|' project.yml
	@git-cliff --tag v$(VERSION) --output CHANGELOG.md
	@git add Sources/WaveLogMoat/Info.plist project.yml CHANGELOG.md
	@git commit -m "bump: version $(VERSION)"
	@git tag v$(VERSION)
	@git push && git push origin v$(VERSION)
	@echo "Released v$(VERSION)"

open:
	open "$$(xcodebuild -project WaveLogMoat.xcodeproj -scheme WaveLogMoat -configuration Debug -showBuildSettings 2>/dev/null | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $$NF}')/WaveLogMoat.app"

changelog:
	git-cliff --output CHANGELOG.md

.DEFAULT_GOAL := build
