---
title: Wallis formula Implementation in python
date: 2014-03-10 01:32:00
categories: python
tags: pi, pi value, wallis, wallis formula
---


```python
print 2 * reduce(lambda x, y : x * y,
	[ float((4 * (i ** 2))) / ((4 * (i ** 2)) -1) for i in range(1, 100000)])
```
<!--more-->