.PHONY: debug release build-debug build-release clean

debug:
	swift run

release:
	swift run -c release

build-debug:
	swift build

build-release:
	swift build -c release

clean:
	swift package clean
