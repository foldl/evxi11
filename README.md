evxi11
======

[VXI-11](http://www.vxi.org/specifications.html) implementation in Erlang.

vxi\_gpib.erl is a VXI-11.3 client (TCP/IP-IEEE 488.2 Intrument Interface).

### How to Build

Requirement:

* [erpcgen](https://github.com/msantos/erpcgen)
* [erpc](https://github.com/tonyrog/erpc)

cd to src directory, erpcgen:file(vxi, [client]) then make:all().

