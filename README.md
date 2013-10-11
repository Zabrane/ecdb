ecdb
====

cdb file reader in erlang

Reference
---------
D.J. Bernstein [cdb]
[cdb]: http://cr.yp.to/cdb.html "cdb"


Build
-----
```
./rebar compile
```

Example
-------
Data fed to `cdbmake` to produce `cdbfile` used in this example

	+3,5:one->Hello
	+3,5:two->Hello
	+3,5:two->World

1. Open cdb file

```erlang
Fd = ecdb:cdbopen("cdbfile").
```

2. Lookup

```erlang
[<<"Hello">>] = ecdb:cdbget(Fd, <<"one">>),
```

```erlang
[<<"Hello">>, <<"World">>] = ecdb:cdbget(Fd, <<"two">>).
```

```erlang
false = ecdb:cdbget(Fd, <<"non_exist">>).
```

3. Close cdb file

```erlang
ok = ecdb:cdbclose(Fd).
```

Test
----
```shell
./rebar eunit
```
