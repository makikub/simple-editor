.PHONY: debug release build-debug build-release app-bundle release-pages clean

debug:
	swift run

release:
	swift run -c release

build-debug:
	swift build

build-release:
	swift build -c release

app-bundle:
	scripts/build_app_bundle.sh

release-pages:
	scripts/update_appcast.sh

clean:
	swift package clean
