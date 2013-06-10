# Crash symbolication that works

I had some problems a lot of times to symbolicate Apple crash-files so I wrote these scripts to help me out.
Because Xcode has the track record of not finding the correct dSYM-file for a crash you just threw at it I think it may be helpful to others.

This version of crash symbolication does not rely on spotlight to find the correct `dSYM`, you have to provide the correct binary/`dSYM` or `*.xcarchive` or you will get garbage values.

## Requrired software

###OS X:
- Xcode developer tools (we need `atos` here)
- A recent version of Ruby (tested on 1.9.3 and 2.0)

###Linux:
- A recent version of Ruby (tested on 1.9.3 and 2.0)
- LLVM in either Version 3.1 or 3.2 (I use the suffixed versioned binaries like `llvm-nm-3.2` and `llvm-dwarfdump-3.2`, the `dwarfdump` binary is part of the llvm distribution since 3.1)

## Usage

### OSX:
At first: make sure the `dSYM` is named exactly like your executable (if the executable had its symbols stripped, happens on release builds) and that the file is in the same directory as your APP-bundle.
If you have an executable with debugging-symbols enabled you don't need the `dSYM`.

    symbolicate-atos.rb -e /path/to/yourapp.app -c /path/to/crashlog.crash
or

    symbolicate-atos.rb -A /path/to/archive.xcarchive -c /path/to/crashlog.crash

#### Options:

      --executable, -e <s>:   Specify executable directly, heuristics employed if
                              app-bundle given
         --archive, -a <s>:   Specify path to *.xcarchive bundle
           --crash, -c <s>:   Specify crash file to symbolicate
            --arch, -r <s>:   Specify architecture to use (default: armv7)
                --help, -h:   Show this message

### Linux:
Choose the correct version of the script for your installed LLVM.

    symbolicate-llvm3.2.rb -d /path/to/symbols.dSYM -e /path/to/executable -c /path/to/crashlog.crash
or

    symbolicate-llvm3.2.rb -a /path/to/archive.xcarchive -c /path/to/crashlog.crash


#### Options:
            --dsym, -d <s>:   Specify DSYM filename directly
      --executable, -e <s>:   Specify executable directly
         --archive, -a <s>:   Specify path to *.xcarchive bundle
           --crash, -c <s>:   Specify crash file to symbolicate
                --help, -h:   Show this message