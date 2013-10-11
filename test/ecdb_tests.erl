-module(ecdb_tests).
-include_lib("eunit/include/eunit.hrl").

cdbget_test() ->
  Fd = ecdb:cdbopen(test_file_path()),
  UTF8Key = unicode:characters_to_binary([16#0434]),
  UTF8Val = unicode:characters_to_binary([16#045a]),
  ?assertEqual([<<"Hello">>], ecdb:cdbget(Fd, <<"one">>)),
  ?assertEqual([<<"Hello">>, <<"World">>], ecdb:cdbget(Fd, <<"two">>)),
  ?assertEqual([<<"emptykey">>], ecdb:cdbget(Fd, <<>>)),
  ?assertEqual([UTF8Val], ecdb:cdbget(Fd, UTF8Key)),
  ?assertEqual([<<>>], ecdb:cdbget(Fd, <<"emptyvalue">>)),
  ?assertEqual(false, ecdb:cdbget(Fd, <<"key_not_exists">>)).
  

test_file_path() ->
  Files = [ "../test/test.cdb" %% in .eunit
          , "test/test.cdb"
          , "test.cdb"
          ],
  hd([F||F<-Files, filelib:is_regular(F)]).
