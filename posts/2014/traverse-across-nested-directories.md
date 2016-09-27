---
title: Traversing across nested directories and files
date: 2014-03-11 12:02:00
categories: python
tags: python, os.walk
comments: true
---

Instead of writing our own recursive loops for traversing between directories and sub-directories python give us one interesting function in `OS` module which makes our work very easy and in optimized way. `OS` module has many other useful functions which helps us to right less code for simple tasks.
<!--more-->

Below I have given a simple example for using `os.walk` function, here we are trying to find the `.mp3` files available in the specified directory.


```python
import os
def search_for_files(path_search, extention):
    for dirname, dirnames, filenames in os.walk(path_search):
        for filename in filenames:
            if filename.endswith(extention):
                print os.path.join(dirname, filename)
if __name__ == '__main__':
    search_for_files("/home/vinod/Music", ".mp3")
```