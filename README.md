# icu4c-xcframework
Universal binary macOS, iOS, iOS Simulator, and mac Catalyst xcode framework constructor for the ICU libraries.

This will create an xcframework for the ICU project, containing
universal builds for Mac, Catalyst, iOS and the iOS simulator
on Intel x86 and ARM64 (ARM / Apple Silicon A and M series) architectures. Apple's version of ICU is not
complete and using this framework will allow you to use the 
ICU tokenizer in sqlite on iOS.

# Requirements

gmake, ginstall, you can install these with [homebrew](https://docs.brew.sh/Installation) if you don't
have them. First install [homebrew](https://docs.brew.sh/Installation) by following the link, then:

    brew install make
    brew install coreutils
    
Apple's git doesn't come with git-lfs by default, and if you receive a complaint from git about this, you
can install git-lfs via homebrew as well.

    brew install git-lfs
    
And execute the suggested commands on installation.

# What this makefile does

1. clones a copy of ICU into the working directory
2. builds ICU for the current machine
3. iterates through mac-universal, catalyst-universal, ios, and
   ios-simulator universal components, configures ICU, and builds libraries
   for that component
4. assembles the components into an xcframework

# Usage

1. Clone this repository.
2. Enter your local directory in Terminal and type 'make', nothing more is needed.
2. When the build is finished, Drag and drop ICU.xcframework into your
   Target > Frameworks, Libraries and Embedded Content. 
3. Build your project as normal in Xcode

....
 
to clean up do:

    make clean (deletes component build stuff)

-or-

    make deepclean (deletes build host, and icu source as well...)

# See also:

ICU project: https://unicode-org.github.io/icu/

Original inspirations for this framework: 

https://github.com/zhm/icu-ios 

https://github.com/sunkehappy/icu-ios
