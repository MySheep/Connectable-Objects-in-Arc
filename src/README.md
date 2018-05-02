"Connectable" objects in Arc
============================

Connectable objects are like nodes in a [dependency graph](https://en.wikipedia.org/wiki/Dependency_graph).
The idea is learning by watching the basics of [Maya's Dependency Graph](http://docs.autodesk.com/MAYAUL/2014/ENU/Maya-API-Documentation/index.html?url=files/GUID-AABB9BB4-816F-4C7C-A526-69B0568E1587.htm,topicNumber=d30e8919)

Example
-------

This example code create on object with 4 numeric attributes.
Where a,b are input and output attributes. Attributes c and d are depend of a and b.
If you set the input to a different value the output get "dirty" and they need
to be recalculated. Also every objects depent on this output is set dirty. 
This is called dirty propagation.

```
;; ----------------------------------------------------------------------------
;; Register type 'adder
;; ----------------------------------------------------------------------------
;;
;;     'adder
;;    --------
;;  -|> a 1   |>- 
;;  -|> b 2   |>-
;;   |  c 0 * |>-  (c = a + b)
;;   |  d 0 * |>-  (d = a - b)
;;    --------  
;;
;; ----------------------------------------------------------------------------
```

Here you see to "adder" nodes connected together.

```
;;     adder1
;;    --------
;;  -|> a 1   |>-       adder2
;;  -|> b 2   |>-      --------
;;   |  c 0 * |>------|> a 1   |>-     
;;   |  d 0 * |>      |> b 2   |>-     
;;    --------        |  c 0 * |>-----(get-value)
;;                    |  d 0 * |>   
;; 
```

Arc
---
Arc is a new dialect of Lisp we're working on. You can find an early release and ask questions at arclanguage.org. The Arc community is very newbie-friendly, because all the users are newbies to some extent.

http://www.paulgraham.com/arc.html

Install
-------

1. Install version *372* of MzScheme. (Don't use the latest version. Versions after 372 made lists immutable.) 

2. Get http://www.arclanguage.org/arc3.1.tar and untar it. 


Install Arc Plugin IntelliJ IDEA
---------------------------

Creates an environment for creating Arc code, including syntax highlighting, simple structure view, and a REPL. 

https://plugins.jetbrains.com/plugin/2043-arc

https://github.com/projectileboy/intelli-arc/tree/master/doc/

Folder structure
----------------

- Connect
  - arc3.1 
  - MzScheme372
  - Connect (this project)


Start
-----
Open project with intelliJ and run with

```
(load "../Connect/main.arc")
```
