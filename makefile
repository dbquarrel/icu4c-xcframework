# Author: dbquarrel
# Copyright: waived
# Disclaimer: use at your own risk however you want

# This will create an xcframework for the ICU project, containing
# universal builds for Mac, Catalyst, iOS and the iOS simulator
# on x86 and ARM64 architectures

##############################
##### requirements
##############################

# gmake, ginstall, you can install these with homebrew if you don't
# have them

##############################
##### what it does
##############################

#
# 1. clones a copy of ICU into the working directory
# 2. builds ICU for the current machine
# 3. iterates through mac-universal, catalyst-universal, ios, and
#    ios-simulator universal components, configures ICU, and builds libraries
#    for that component
# 4. assembles the components into an xcframework

##############################
##### usage
##############################

# 1. type 'make' in Terminal to build ICU.xcframework
# 2. Drag and drop ICU.xcframework into your
#    Target > Frameworks, Libraries and Embedded Content
# 3. Build your project as normal in Xcode

# ....
# 
# to clean up do:
#
## make clean (deletes component build stuff)
# -or-
## make deepclean (deletes build host, and icu source as well...)


##############################
##### customization
##############################

# This should be the only variable you may be concerned about 

IOS_min_version := 14.4

#######################################################################
#
# NOTE: some of these variables are touchy because of parallel building
#       and possible overlap with variables in the makefiles for ICU
#       so be careful about editing things... 
#
# ALSO: you can't build the tools on iOS since they use some system calls
#
#######################################################################

MASTER_root := $(shell pwd)

# .noindex stops spotlight from indexing as it builds which takes
# a ton of CPU on macos and is one of the stupid features apple
# won't let you turn off unless you use a .noindex suffix

# where we are going to be doing our work
BUILD_dir = build.noindex

# how many CPUs we can use to build in parallel
HOST_cpus := $(shell sysctl -n hw.ncpu)

# what architecture is this machine
HOST_arch := $(subst arm64,arm,$(shell arch))

# what os is this machine
HOST_os := $(shell uname -s | tr '[A-Z]' '[a-z]')

# munge it together
HOST_build := $(HOST_arch)-apple-$(HOST_os)

# where we will drop the host build of icu
HOST_dir := $(BUILD_dir)/host-$(HOST_build)
# why are they different formats? no good answer yet

HOST_arm = arm-apple-darwin
HOST_x86 = x86_64-apple-darwin
# not needed
#HOST_version := $(shell sw_vers -productVersion | awk -F. ' {print $$1 } ')

# icu requires gmake
MAKE = gmake

# when we want to do parallel building
MAKE_PARALLEL = $(MAKE) -j$(HOST_cpus)

# how much to optimize
OPT_cflags := -O3

# these flags will be passed to the icu configure script

CONFIG_flags = \
	--enable-static=yes \
	--enable-shared=no \
	--with-data-packaging=static 

CONFIG_ios_flags = \
	$(CONFIG_flags) \
	--enable-tests=no \
	--enable-tools=no

# where git is going to unload icu
ICU_clone := icu-clone.noindex

# where icu4c can be found
ICU_root := $(MASTER_root)/$(ICU_clone)/icu/icu4c

# where icu4c is going to install itself so we can grab headers
ICU_destination := $(MASTER_root)/$(BUILD_dir)/icu

# where the framework can snarf the built headers
ICU_cflags := -I$(ICU_destination)/include/

# where the icu configuration script is
ICU_configure := $(ICU_root)/source/configure

# what libraries we want to snarf out of ICU
ICU_libs := libicuuc.a libicui18n.a libicuio.a libicudata.a

CROSS := --with-cross-build=$(MASTER_root)/$(HOST_dir)

##########
########## Rules
##########

all: $(ICU_clone) clean build-host framework

##############################
##### host
##############################

build-host: $(HOST_dir)

$(HOST_dir):
	mkdir -p $@ && cd $@ ; \
	export OTHER_CONFIG=$(CONFIG_flags) ; \
	export CFLAGS=$(OPT_cflags) ; \
	export CXXFLAGS=-stdlib=libc++ -std=c++11 $(OPT_cflags) ; \
	$(ICU_configure) --prefix=$(ICU_destination) $${OTHER_CONFIG} ; \
	$(MAKE_PARALLEL) ; \
	$(MAKE_PARALLEL) install 

#	export OTHER_CONFIG=$(CONFIG_flags); 
# builds library for normal use on mac, doesn't go into iOS framework

##############################
##### macOS
##############################

mac: $(DIR)
	cd $(DIR) ; \
	export OTHER_CONFIG="$(CONFIG_flags)" ; \
	export CFLAGS="$(ARCHS) $(OPT_cflags)" ; \
	export CXXFLAGS="-stdlib=libc++ -std=c++11 $${CFLAGS} " ;\
	export LDFLAGS="-stdlib=libc++ -Wl,-dead_strip -lstdc++ $(ARCHS)" ; \
	$(ICU_configure) --host $(ICU_host) $${OTHER_CONFIG} $(CROSS) ; \
	$(MAKE_PARALLEL) 

# not used
$(BUILD_dir)/mac_x86_64:
	$(MAKE) mac \
		DIR=$@ \
		ARCHS="-arch x86_64" \
		ICU_host=$(HOST_x86)

# not used
$(BUILD_dir)/mac_arm64:
	$(MAKE) mac \
		DIR=$@ \
		ARCHS="-arch arm64" \
		ICU_host=$(HOST_arm)

# we only need universal
$(BUILD_dir)/mac_universal:
	$(MAKE) mac \
		DIR=$@ \
		ARCHS="-arch arm64 -arch x86_64" \
		ICU_host=$(HOST_build)


##############################
##### Catalyst
##############################

# Note: the line with sed Makefile is a hack
# as I can't get configure to include the datasubdir for catalyst
catalyst: $(DIR)
	cd $(DIR) ; \
	export OTHER_CONFIG="$(CONFIG_ios_flags)" ; \
	export CFLAGS="$(ARCH_cflags) -target $(TGT)-apple-ios$(IOS_min_version)-macabi $(ICU_cflags) $(OPT_cflags)" ; \
	export CXXFLAGS="-stdlib=libc++ -std=c++11 $${CFLAGS}" ; \
	export LDFLAGS="-stdlib=libc++ -Wl,-dead_strip -lstdc++ $(IOS_cflags) " ; \
	$(ICU_configure) --host=$(HOST_build) $${OTHER_CONFIG} $(CROSS) ; \
	sed 's/^#DATASUBDIR =/DATASUBDIR =/g' < Makefile > .tmp; mv .tmp Makefile ; \
	$(MAKE_PARALLEL) 

#	mlreplace '#DATASUBDIR = data' 'DATASUBDIR = data' Makefile ; \

$(BUILD_dir)/mac_catalyst_universal:
	$(MAKE) catalyst \
		DIR=$@ \
		ARCH_cflags="-arch x86_64 -arch arm64" \
		TGT=universal

$(BUILD_dir)/mac_catalyst_x86_64:
	$(eval ARCH := x86_64)
	$(MAKE) catalyst \
		DIR=$@ \
		TGT=$(ARCH) \
		ARCH_cflags="-arch $(ARCH)" 

$(BUILD_dir)/mac_catalyst_arm64:  build-host
	$(eval ARCH := arm64)
	$(MAKE) catalyst \
		DIR=$@ \
		TGT=$(ARCH) \
		ARCH_cflags="-arch $(ARCH)" 

##############################
##### iOS
##############################

IOS_developer := $(shell xcode-select --print-path)
IOS_cflags := -miphoneos-version-min=$(IOS_min_version)
SDK_sim := $(shell xcrun --sdk iphonesimulator --show-sdk-path)
SDK_dev := $(shell xcrun --sdk iphoneos --show-sdk-path)
CXX := $(IOS_developer)/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
CC := $(IOS_developer)/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang

# builds for iOS devices
$(BUILD_dir)/ios_arm64:
	$(eval ARCH := arm64)
	mkdir -p $@ && cd $@ ; \
	export OTHER_CONFIG="$(CONFIG_ios_flags)" ; \
	export CFLAGS="-isysroot $(SDK_dev) -I$(SDK_dev)/usr/include/ -I./include/ -arch $(ARCH) $(IOS_cflags) $(ICU_cflags) $(OPT_cflags)" ; \
	export CXXFLAGS="-stdlib=libc++ -std=c++11 $${CFLAGS}" ; \
	export LDFLAGS="-stdlib=libc++ -L$(SDK_dev)/usr/lib/ -isysroot $(SDK_dev) -Wl,-dead_strip $(IOS_cflags) -lstdc++" ; \
	$(ICU_configure) --host=$(HOST_arm) $${OTHER_CONFIG} $(CROSS) ; \
	$(MAKE_PARALLEL) 

simulator: $(DIR)
	cd $(DIR) ;\
	export OTHER_CONFIG="$(CONFIG_ios_flags)" ; \
	export CFLAGS="$(ARCH_cflags) -target $(TGT)-apple-ios$(IOS_min_version)-simulator -isysroot $(SDK_sim) -I$(SDK_sim)/usr/include/ -I./include/ $(ARCH_cflags) $(ICU_cflags) $(OPT_cflags)" ;\
	export CXXFLAGS="-stdlib=libc++ -std=c++11 $${CFLAGS}" ;\
	export LDFLAGS="-stdlib=libc++ -L$(SDK_sim)/usr/lib/ -isysroot $(SDK_sim) -Wl,-dead_strip $(IOS_cflags) -lstdc++" ;\
	$(ICU_configure) --host=$(CONFIG_HOST) $${OTHER_CONFIG} $(CROSS) ;\
	$(MAKE_PARALLEL)

$(BUILD_dir)/sim_x86_64:
	$(eval ARCH := x86_64)
	$(MAKE) simulator \
		DIR=$@ \
		ARCH_cflags="-arch $(ARCH)" \
		TGT="$(ARCH)" \
		CONFIG_HOST=i686-apple-darwin11

$(BUILD_dir)/sim_arm64:
	$(eval ARCH := arm64)
	$(MAKE) simulator \
		DIR=$@ \
		ARCH_cflags="-arch $(ARCH)" \
		TGT="$(ARCH)" \
		CONFIG_HOST=arm-apple-darwin11

$(BUILD_dir)/sim_universal:
	$(eval ARCH1 := arm64)
	$(eval ARCH2 := x86_64)
	$(MAKE) simulator \
		DIR=$@ \
		ARCH_cflags="-arch $(ARCH1) -arch $(ARCH2)" \
		TGT="universal" \
		CONFIG_HOST=arm-apple-darwin11

##############################
##### Framework
##############################

# uses all of the libraries above to create an XCFramework that can
# be dropped into your XCode project, this will allow you to target
# iOS devices, iOS simulator, Mac Catalyst as needed without libraries
# causing conflicts

FRAMEWORK := ICU.xcframework

FRAMEWORK_components := \
	mac_universal \
	mac_catalyst_universal \
	ios_arm64 \
	sim_universal

FRAMEWORK_dependencies := $(addprefix $(BUILD_dir)/,$(FRAMEWORK_components))

# for some reason, when we re-run a build in an existing build
# directory, we get link errors on the M1 chip, so we need to
# start fresh or figure out why ar is failing the second time

framework: $(FRAMEWORK_dependencies)
	$(MAKE) framework-only

framework-only:
	components=( $(FRAMEWORK_components) ) ;\
	flags="" ; \
	start=$(MASTER_root) ; \
	target=libICU.a ; \
	for component in "$${components[@]}" ; do \
		echo "-------------- $${component}" ;\
		src=$(BUILD_dir)/$${component}/lib ;\
		cd $${src} ;\
		libtool -static -o $${target} $(ICU_libs) ;\
		cd $${start} ;\
		flags="$${flags} -library $${src}/$${target} " ;\
		flags="$${flags} -headers $(ICU_destination)/include" ;\
	done ; \
	rm -rf $(FRAMEWORK) ;\
	echo xcodebuild -create-xcframework $${flags} -output $(FRAMEWORK) ;\
	xcodebuild -create-xcframework $${flags} -output $(FRAMEWORK)

##############################
##### general purpose
##############################

clean:
	rm -rf $(FRAMEWORK_dependencies)

deepclean: 
	rm -rf $(BUILD_dir)
	rm -rf $(ICU_clone)

$(DIR):
	mkdir -p $(DIR)

print-%  : ; @echo $* = $($*)

##
## Get a copy of ICU
##

$(ICU_clone):
	mkdir -p $@ && cd $@; \
	git clone https://github.com/unicode-org/icu.git



