# SAML21 baremetal cpp hello world makefile project

Here is an extended hello world project for SAML21 Cortex-M0+ controller by Atmel with full integration in VS Code like build, clean and program tasks are setup and debugging is configured without the need of an extension.
You only need a Windows 10 with WSL enabled as the makefile was intentionally created for unix like systems and has now been ported to Windows/WSL.

## Workflow after Setup has been done

1. Make the project via ```make all```
2. Start openocd via ```make server_start``` in a second shell or background however
4. Hook up a serial terminal and connect to processor
3. Flash the program via ```make program```
5. Type in ```led on``` and ```led off``` to toggle the userled on the sammyl21 board
6. Stop openocd via ```make server_stop```

## Prerequisites

1. [ARM Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm)
2. [Atmel/Advanced Software Framework (ASF)](https://www.microchip.com/mplab/avr-support/advanced-software-framework)
3. [OpenOCD](https://gnutoolchains.com/arm-eabi/openocd/)

## Setup

1. open makefile and change the path variables according to your installation

```makefile
#	ARM GCC installation path
ARM_GCC_PATH := /mnt/d/arm-dev/gcc-arm-none-eabi-8-2019-q3-update
#	OpenOCD installation path 
OPENOCD_PATH := /mnt/d/arm-dev/OpenOCD-20190715-0.10.0
#	ASF installation path
ASF_PATH := /mnt/d/arm-dev/xdk-asf-3.45.0
```

2. make sure you are in the projects directory with the current shell
```bash
$ cd [path to project]
```

3. Link project to the ASF

```bash
$ make links
```

4. In file xdk-asf/system_saml1.c add the *weak* attribute to the functions ```SystemInit``` and ```SystemCoreClockUpdate```
```cpp
void __attribute__((weak)) SystemInit(void){...}
void __attribute__((weak)) SystemCoreClockUpdate(void){...}
```
Adding this attribute to the functions let's us override them somewhere else without causing the gcc to raise a ```multiple definition of 'function'``` error.

5. build it

```bash
$ make build
```
Don't forget to multithread this with the argument ```-j [Number of concurrent jobs]```
```bash
$ make -j 4 all
```

## Flash and Debug

1. make sure you are in the projects directory
```bash
$ cd [path to project]
```

2. start openocd server
Either manually in a seperate shell (makes sense if the debugging/flashing fails)
```bash
$ openocd
```
or in the same shell but started in the background
```bash
$ make server_start
```

To kill it if run in the background run
```bash
$ make server_stop
```

3. run debug command (this automatically flashes the target but leaves open the gdb console)
```bash
$ make debug
```
or only for programming the target

```bash
$ make program
```

## Configure VS Code's C/C++ plugin for IntelliSense

Scan through the file ```.vscode/c_cpp_properties.json``` and change all paths to your installation.
In case you are using a different gcc version you can get the default includes by running

```bash
echo | [full path to your gcc]/bin/arm-none-eabi-gcc -Wp,-v -x c++ - -fsyntax-only
```


## Debugging in VS Code

Scan through the file ```.vscode/launch.json``` and configure all paths to your installation

## Changes to be made for similar processors

1. In the makefile you have to change the make links target in such a way that the files for your processor are linked.
2. In openocd.cfg you have to setup your processor and your debugger

## Improvements
With 84kB the binary is damn big for a microprocessor. This is caused by the use of std::string