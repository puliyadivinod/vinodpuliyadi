---
title: useful linux command snippets
date: 2014-03-13 12:46:00
categories: programming
tags: linux, seq, grep, screen
---

I have to process daily with lot of numbers and files, below are few usefull commands which helps to make me more prodcutive.
<!--more-->

```bash
$ # How to print sequence of number quickly from shell?
$ seq 0 10
0
1
2
3
4
5
6
7
8
9
10

$ # Can we print the number with `0` like 00, 01, 02...
$ seq -w 0 10
00
01
02
03
04
05
06
07
08
09
10

$ # How can we loop over lines available in file?
$ for line in `cat readfile.txt`; do echo $line; done
Hello
World!
Shell

$ # How can quickly search in file?
$ grep "World" readfile.txt
World!

$ # Can we get inverse results?
$ grep -v "World" readfile.txt
Hello
Shell

$ # Can we get count of results?
$ grep -cv "World" readfile.txt
2

$ # How to protect long processing scripts in server from terminating, if your internet goes unavailable?
$ # Before executing any long processing script make sure to run on `screen`
$ screen -S "mytempscreen"
$ python runyourscript.py
$ # taking long time, internet goes down... disconnected from server
$ # Login again and run below command to attach the last screen.
$ screen -x
$ # Yippy!!!
$ # script was running even after internet disconnection.
$ python runyourscript.py
```