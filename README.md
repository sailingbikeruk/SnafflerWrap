# SnafflerWrap
A PowerShell wrapper for Snaffler to set the correct switches and provide the command line or launch the exe

Not all possible switches are currently included. This is a work in progress

Currently this will ask for the following:

1) confirm the working directory and give an option to change it
2) go though each of the following options:

-n supply a comma separated list of targets. NOTE: currently the script exits if this is not supplied - **ISSUE #1**

-o the default output path relative to the current working directory. this will be created if it doesn't exist.The filename is a simple datetimestamp

-v verbosity level as per the snaffler git hub. default is 1 (Info)

-x max threds. The default is 30.

-i path to perform file discovery. NOTE this is not currently working because of a conflict with -n - **ISSUE #2**

-p defines the use of custom rules with an option to use the default ruleset. it defaults to a folder in the current workign directory. the directory needs to exist and toml files need to be present.

It then gives a summary of the options selected with the command line it will use and gives the option to run or stop.

<img width="743" height="245" alt="image" src="https://github.com/user-attachments/assets/1fcf84c2-ed81-492c-9ae3-6e6e4cb4d83c" />



