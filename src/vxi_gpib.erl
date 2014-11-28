%@doc A VXI11.3 (GPIB) client.
-module(vxi_gpib).

-export([open/3, open/5, close/1, send/2, read/1]).

-include("vxi.hrl").

-define(CLIENT_ID, 16#00ABCDEF).
-define(DEFAULT_IO_TIMOUT, 10000).

-define(FLAG_WAIT_LOCK, 16#1).
-define(FLAG_END,       16#8).
-define(FLAG_TERMCHSET, 16#80).

-define(ERROR_NO_ERROR,  0).
-define(ERROR_IO_TIMOUT, 15).

-record(vxi_state, {
                        client :: pid(),
                        server :: pid(),
                        lid,
                        abortport,
                        max_recv
                   }).

%@doc Open vxi11.3 (GPIB) connection on Host
%     ServerPid is used for receiving strings from Host, if set as 'undefined', then io:format is used.
-spec open(Host :: string(), Name :: string(), ServerPid :: pid() | undefined) -> {ok, pid()} | {error, Reason :: any()}.
open(Host, Name, ServerPid) ->
    {Proto, Port} = find_port_proto(Host),
    open(Host, Name, Proto, Port, ServerPid).

%@doc Open vxi11.3 (GPIB) connection on Host:Port 
-spec open(Host :: string(), Name :: string(), Proto :: tcp | udp, Port :: integer(), 
           ServerPid :: pid() | undefined) -> {ok, pid()} | {error, Reason :: any()}.
open(Host, Name, Proto, Port, ServerPid) ->
    Ref = make_ref(),
    Self = self(),
    Pid = spawn_link(fun () ->
        process_flag(trap_exit, true),
        {ok, Clnt} = rpc_client:open(Host, ?DEVICE_CORE, ?DEVICE_CORE_VERSION, Proto, Port),
        {ok, {?ERROR_NO_ERROR, Lid, AbortPort, MaxRecvSize}} = vxi_clnt:create_link_1(Clnt, {?CLIENT_ID, false, 0, Name}),
        Self ! {ok, Ref},
        loop(#vxi_state{client = Clnt, server = ServerPid, lid = Lid, abortport = AbortPort, max_recv = MaxRecvSize})
    end),
    receive
        {ok, Ref} ->
            {ok, Pid}
    after
        5000 -> {error, econn}
    end.

close(Pid) -> Pid ! stop.

%@doc Write L to device.
send(Pid, L) ->
    Pid ! {send, L}.

%@doc Trigger reading from device.
% When something is got from device, {gpib_read, Client :: pid(), Data :: list()} is 
%   sent to ServerPid specified in open/3 or open/5.
read(Pid) ->
    Pid ! read.

%@doc Detect port and protocal on Host 
find_port_proto(Host) ->
    {ok, Pid} = pmap:open(Host),
    {ok, List} = pmap:dump(Pid),
    pmap:close(Pid),
    case find_prog_ver(tcp, List) of
        {Proto, Port} -> {Proto, Port};
        _ -> find_prog_ver(List)
    end.

find_prog_ver(Proto, [{?DEVICE_CORE, ?DEVICE_CORE_VERSION, Proto, Port} | _T]) ->
    {Proto, Port};
find_prog_ver(Proto, [_X | T]) ->
    find_prog_ver(Proto, T);
find_prog_ver(_Proto, []) -> error.

find_prog_ver([{?DEVICE_CORE, ?DEVICE_CORE_VERSION, Proto, Port} | _T]) ->
    {Proto, Port};
find_prog_ver([_X | T]) ->
    find_prog_ver(T);
find_prog_ver([]) -> error.

loop(#vxi_state{client = Clnt, server = ServerPid, lid = Lid, max_recv = MaxRecvSize} = State) ->
    receive
        {send, L} ->
            case length(L) > MaxRecvSize of
                true -> exit(too_long);
                _ -> ok
            end,
            {ok, {?ERROR_NO_ERROR, _Size}} = vxi_clnt:device_write_1(Clnt, {Lid, ?DEFAULT_IO_TIMOUT, 
                                                                            ?DEFAULT_IO_TIMOUT, ?FLAG_END, L}),
            loop(State);
        read ->
            case vxi_clnt:device_read_1(Clnt, {Lid, 16#10000, ?DEFAULT_IO_TIMOUT, ?DEFAULT_IO_TIMOUT, 0, 0}) of                
                {ok, {?ERROR_NO_ERROR, _Reason, Data}} ->
                    case is_pid(ServerPid) of
                       true -> gen_server:cast(ServerPid, {gpib_read, self(), binary_to_list(Data)});
                       _ -> io:format("~p~n", [Data])
                    end,
                    loop(State);
                {ok, {?ERROR_IO_TIMOUT, _Reason2, _Data2}} ->
                    io:format("timeout~n", []),
                    loop(State);
                _ ->
                    exit(vxi11)
            end;
        stop ->
            vxi_clnt:destroy_link_1(Clnt, Lid);            
        {'EXIT', _Pid, _Reason} ->
            exit(port_terminated);
        X ->
            io:format("~p: unknown message: ~p~n", [?MODULE, X]),
            exit(vxi11)
    end.

