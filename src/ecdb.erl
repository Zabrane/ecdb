-module(ecdb).

-export([cdbopen/1, cdbclose/1, cdbget/2]).

-define(BITS_32, 4294967295). %% ((1 bsl 32) - 1)).
-define(HASH_START, 5381).
-define(BITS_FORMAT, 32/unsigned-little-integer).

%% API
-spec cdbopen(file:filename()) -> file:io_device().
cdbopen(Filename) ->
  {ok, Fd} = file:open(Filename, [raw, read, binary]),
  Fd.

-spec cdbclose(file:io_device()) -> ok | {error, atom()}.
cdbclose(Fd) ->
  file:close(Fd).

-spec cdbget(file:io_device(), binary()) -> [binary()] | false.
cdbget(Fd, Key) ->
  try cdbget2(Fd, Key)
  catch throw:not_found -> false
  end.

%% Internal
cdbget2(Fd, Key) ->
  KeyHash = hash(binary_to_list(Key)),
  {HashTabPos, NCells} = hash_table(Fd, KeyHash),
  DataPtrs = data_ptrs(Fd, KeyHash, HashTabPos, NCells),
  read_data(Fd, Key, DataPtrs).

hash(Str) ->
  lists:foldl(fun hash/2, ?HASH_START, Str).

hash(C, Acc) ->
  ((Acc bsl 5 + Acc) bxor C) band ?BITS_32.

hash_table(Fd, KeyHash) ->
  {ok, <<HashTabPos:?BITS_FORMAT, NCells:?BITS_FORMAT>>}
    = pread(Fd, (KeyHash rem 256) * 8),
  assert_non_zero(not_found, NCells),
  {HashTabPos, NCells}.

data_ptrs(Fd, KeyHash, Base, NCells) ->
  CellStart = (KeyHash bsr 8) rem NCells,
  data_ptrs(Fd, KeyHash, Base, CellStart, NCells, 0, []).

data_ptrs(_Fd, _KeyHash, _Base, _CellStart, NCells, I, Acc)
  when I == (NCells-1) -> Acc;
data_ptrs(Fd, KeyHash, Base, CellStart, NCells, I, Acc) ->
  Pos = Base + ((CellStart+I) rem NCells) * 8,
  {ok, <<H:?BITS_FORMAT, P:?BITS_FORMAT>>} = pread(Fd, Pos),
  case {H, P} of
    {_, 0}        -> Acc;
    {KeyHash, P1} ->
      data_ptrs(Fd, KeyHash, Base, CellStart, NCells, I+1, [P1|Acc]);
    {_Other, _}   ->
      data_ptrs(Fd, KeyHash, Base, CellStart, NCells, I+1, Acc)
  end.

read_data(Fd, Key, DataPtrs) ->
  ReadData = fun(Ptr, Acc) -> read_data(Fd, Key, Ptr, Acc) end,
  lists:foldl(ReadData, [], DataPtrs).

read_data(Fd, Key, RecPtr, Acc) ->
  file:position(Fd, RecPtr),
  {ok, <<Klen:?BITS_FORMAT, Vlen:?BITS_FORMAT>>} = file:read(Fd, 8),
  {ok, <<K:Klen/bytes>>} = file:read(Fd, Klen),
  case K of
    Key -> {ok, <<V:Vlen/bytes>>} = file:read(Fd, Vlen),
           [V|Acc];
    _Other -> Acc
  end.

assert_non_zero(Name,  0) -> throw(Name);
assert_non_zero(_Name, _) -> ok.

pread(Fd, Pos) ->
  pread(Fd, Pos, 8).

pread(Fd, Pos, Size) ->
  file:pread(Fd, Pos, Size).
