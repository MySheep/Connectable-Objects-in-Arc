"Connectable" objects in Arc
============================

Connectable objects are like nodes in dependency graph.


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