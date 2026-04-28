# SnafflerWrap

## Description
A PowerShell wrapper for Snaffler to set the correct switches and provide the command line or launch the exe

Not all possible switches are currently included, if you want something, raise an issue or make a pull request. 

### Steps
1) confirm the working directory and give an option to change it

<img width="589" height="188" alt="image" src="https://github.com/user-attachments/assets/fc92175a-0d67-4460-8b2f-6233165ff48b" />


2) go though each of the following options:
  1. enter nothing and let snaffler do its thing <br />
    a. enter a domain name and let snaffler find the DCs <br /> 
    b. enter a domain name and specify a DC <br />
  2. enter a comma separated list of hosts 
  3. enter a path to a CSV file with a list of hosts 
  4. enter a path to a folder on the local host 

<img width="535" height="164" alt="image" src="https://github.com/user-attachments/assets/28ee5d1b-0f22-4713-86bf-1315fac87b1c" />

<img width="846" height="269" alt="image" src="https://github.com/user-attachments/assets/5b31799a-2ea0-4b3d-a18c-b0ddf1a3dc64" /> <br />

-o the default output path relative to the current working directory. this will be created if it doesn't exist.The filename is a simple datetimestamp (.\Output\202603261315.txt)

<img width="558" height="109" alt="image" src="https://github.com/user-attachments/assets/2363d35b-db61-40c2-8304-dcc11c929495" /> <br />

-v verbosity level as per the snaffler git hub. default is 1 (Info)

<img width="528" height="113" alt="image" src="https://github.com/user-attachments/assets/7f9ff50a-14eb-4944-98cc-175c513adfa0" /> <br />

-x max threds. The default is 30.

<img width="355" height="70" alt="image" src="https://github.com/user-attachments/assets/aba56342-d33a-4147-90c0-3bbdff87d892" /> <br />

-p defines the use of custom rules with an option to use the default ruleset. it defaults to a folder named "rules" in the current working directory (.\rules). the directory needs to exist and toml files need to be present.

<img width="305" height="102" alt="image" src="https://github.com/user-attachments/assets/16eecdbb-a674-43d8-86e2-5f9f50101917" /> <br />


### Default Switches
It automatically adds 

-s output to stdout <br />
-y use TAB separated output (makes it compatble with Snaffler Parser https://github.com/zh54321/SnafflerParser)

It then gives a summary of the options selected with the command line it will use and gives the option to run or stop.

<img width="821" height="251" alt="image" src="https://github.com/user-attachments/assets/107ff1e3-612c-411f-a0ab-5334e1ac578a" />




