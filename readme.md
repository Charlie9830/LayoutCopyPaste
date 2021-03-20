## Layout Copy and Paste

Version 1.0


Created by Charlie Hall and Ellie Garnett


https://www.github.com/charlie9830


Last Updated March 2021



### DESCRIPTION

A plugin for MA Lighting GrandMA2 Lighting Consoles.
This plugin allows users to Copy and Paste regions from one layout to another, this includes all Text, Rectangle, Pool
and Fixture elements. Bitmap copy is not currently implemented.

### INSTRUCTIONS

- [1] Draw a rectangle on your layout around the objects you wish to Copy, set the text property on this rectangle to 'copy'


- [2] In the layout you wish to copy the elements into, draw a rectangle and set the text property to 'paste', This size of this 
rectangle does not matter, the plugin will only use its position to place this incoming elements.


- [3] Run the plugin by typing "Plugin X" into your command line, where x is the number of the plugin, or by touching the plugin
pool element in the Plugins window.

- [4] Enter the number of your source layout (The layout with the 'copy' rectangle)

- [5] Enter the number of your target layout (That layout with the 'paste' rectangle)

Your elements will be copied from the 'copy' rectangle to the 'paste' rectangle.
The plugin is very robust, validating all inputs before performing any possibly 'destructive' actions, however if you find that
your layout has been borked, you can 'oops' out of it. 'oops' back to the command "Import Layout at x /path="lcp_outputlayout.xml"...."

### IMPORTANT
For this plugin to work correctly, it calls "SelectDrive 1" each time it is run. This sets the target drive to internal. This means that if you have a USB Flash Drive plugged into the console and you have selected it in the Backup Tab, it will no longer be
selected. Pressing 'Backup Backup' will now direct saves to the internal drive instead of your Flash Drive until you reset it back
in the Backup menu.

### Pre Compiled Download
Download version1.lua from [HERE](https://github.com/Charlie9830/LayoutCopyPaste/releases)

### Development Instructions
#### Dependencies
- xml2lua (Modified already packaged with source code)

- luabundler [Github Repo](https://github.com/Benjamin-Dobell/luabundler)

- LUA [Link](http://www.lua.org/)

#### Overview
main.lua is the entry point. Whilst developing you can use your own devices LUA interpreter by running the following command in your terminal.

`lua main.lua`

The Mocks module provides Mocks of the GMA functions. When running in dev the script will expect to find the source and target layouts in the root project folder. The output layout will be directed to the root folder.


To bundle the modules together for single plugin use on an MA Console or OnPc. Install luabundler and run

`luabundler bundle main.lua -p \" ./?.lua \" -p \" ./xmlhandler/?.lua \" -o dist.lua`


A bundled LUA file will be emitted to dist.lua in the project root directory.

