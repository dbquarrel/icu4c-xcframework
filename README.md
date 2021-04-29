# icu4c-xcframework
Universal binary macOS, iOS, iOS Simulator, and mac Catalyst xcode framework constructor for the ICU libraries

This will create an xcframework for the ICU project, containing
universal builds for Mac, Catalyst, iOS and the iOS simulator
on x86 and ARM64 architectures. Apple's version of ICU is not
complete and using this framework will allow you to use the 
ICU tokenizer in sqlite on iOS.

# Requirements

gmake, ginstall, you can install these with homebrew if you don't
have them

# What it does

1. clones a copy of ICU into the working directory
2. builds ICU for the current machine
3. iterates through mac-universal, catalyst-universal, ios, and
   ios-simulator universal components, configures ICU, and builds libraries
   for that component
4. assembles the components into an xcframework

# Usage

1. type 'make' in Terminal to build ICU.xcframework
2. Drag and drop ICU.xcframework into your
   Target > Frameworks, Libraries and Embedded Content
3. Build your project as normal in Xcode

....
 
to clean up do:

    make clean (deletes component build stuff)

-or-

    make deepclean (deletes build host, and icu source as well...)

