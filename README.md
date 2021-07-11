# lsp
#Language Server Protocol for Blitzmax NG
(c) Copyright Si Dunford, June 2021, All Rights Reserved
VERSION 0.02 Alpha

##CURRENT STATE:

    ALPHA
    Some features may be non-operational or contain bugs

##CHANGE LOG:
16 JUN 2021  0.00PA  Creation of Github Repository & Basic application structure
07 JUL 2021  0.01A   Application shell is operational

##FEATURES
* Support for VSCode
* initialize/initialized, shutdown/exit

* textDocument - Messages supported but not operational
    

##CONFIGURATION:

    The application does not have any configureable options.

##ADD TO VSCODE
```
    Navigate to File | Preferences | Settings
    Expand Extensions
    Click on BlitzMax

    @ext:hezkore.blitzmax
    
    Blitzmax > Lsp:Path
        ./bin/lsp
```
##DEBUGGING:
```
    Create an environment variable called LSP-DEBUG and set it to a file and the application will write debug information to that file.
    - NOT IMPLEMENTED

    In BlitzMax settings, Enable/disable LSP:Hot Reload
```
