%%%-------------------------------------------------------------------
%%% @author's gihub username: @DenysGonchar
%%% @author's email address: denys.gonchar@erlang-solutions.com
%%% @copyright (C) 2019, @SafaricomAlpha
%%% @doc
%%%   helper module, contains functions required for config file
%%%   pre-processing
%%% @end
%%%-------------------------------------------------------------------
-module(config_parser).
-author("denys.gonchar@erlang-solutions.com").

%% API
-export([get_env/2,
         get_env/3,
         process_config/1,
         get_config/0,
         get_config/1,
         priv_file/2,
         ssl_verify_fun/0]).

%%====================================================================
%% API
%%====================================================================
-type(key() :: atom()).
-type(property() :: key() | {key(), term()}). %% Proplists
-spec(get_config() -> property()).
get_config() ->
    {ok, App} = application:get_application(),
    AppName = atom_to_list(App),
    EnvConfigVariable = string:uppercase(AppName) ++ "_CONFIG",
    DefaultConfigFile1 = AppName ++ ".cfg",
    DefaultConfigFile2 = application:get_env(App, config_file, DefaultConfigFile1),
    ConfigFile = os:getenv(EnvConfigVariable, DefaultConfigFile2),
    get_config(ConfigFile).

-spec(get_config(ConfigFile :: any()) -> any()).
get_config(ConfigFile) ->
    {ok, App} = application:get_application(),
    PrivDir = code:priv_dir(App),
    ConfigFilePath = filename:absname(ConfigFile, PrivDir),
    {ok, Config} = file:consult(ConfigFilePath),
    process_config(Config).


%%====================================================================
%% API pre-processing helpers
%%====================================================================

-type(env_val() :: integer()| atom() | list() | bitstring()).
-spec(get_env(Env :: any(), integer) -> env_val();
             (Env :: any(), list) -> env_val();
             (Env :: any(), atom) -> env_val();
             (Env :: any(), binary) -> env_val()).
get_env(Env, integer) ->
    get_env(Env, integer, 0);
get_env(Env, list) ->
    get_env(Env, list, "");
get_env(Env, atom) ->
    get_env(Env, atom, undefined);
get_env(Env, binary) ->
    get_env(Env, binary, <<"">>).

-spec(get_env(Env :: any(), Type :: atom(), DefaultValue :: any()) -> env_val()).
get_env(Env, Type, DefaultValue) ->
    case os:getenv(Env) of
        false -> DefaultValue;
        Value -> convert_env(Value, Type)
    end.

-spec(convert_env(Value :: any(), binary) -> bitstring();
                 (Value :: any(), integer) -> integer();
                 (Value :: any(), atom) -> atom();
                 (Value :: any(), list) -> list()).
convert_env(Value, binary) ->
    list_to_binary(Value);
convert_env(Value, integer) ->
    list_to_integer(Value);
convert_env(Value, atom) ->
    list_to_existing_atom(Value);
convert_env(Value, list) ->
    Value.

%% ?APP(AppNameNameAsAtom) from ./include/config_parser.hrl
priv_file(AppNameNameAsAtom, File) ->
    code:priv_dir(AppNameNameAsAtom) ++ "/" ++ File.

-spec(process_config(Config :: any()) -> any()).
process_config(Config) when is_list(Config) ->
    process_config_elements(Config).

%%certificate, event, user_state
ssl_verify_fun() ->
    {fun(_, {bad_cert, _} = _Event, UserState) ->
        {valid, UserState};
        (_, {extension, _}, UserState) ->
            {unknown, UserState};
        (_, valid, UserState) ->
            {valid, UserState};
        (_, valid_peer, UserState) ->
            {valid, UserState}
     end, []}.

%%====================================================================
%% Internal functions
%%====================================================================
-spec(process_config_elements({{M :: atom(), F :: atom(), A :: list()}}) -> any();
                             (Tuple :: tuple()) -> any();
                             (Map :: map()) -> any();
                             (List :: list()) -> any();
                             (Element :: any()) -> any()).
process_config_elements({{M, F, A}}) when is_atom(M), is_atom(F), is_list(A) ->
    erlang:apply(M, F, process_config_elements(A));
process_config_elements(Tuple) when is_tuple(Tuple) ->
    list_to_tuple(process_config_elements(tuple_to_list(Tuple)));
process_config_elements(Map) when is_map(Map) ->
    maps:from_list(process_config_elements(maps:to_list(Map)));
process_config_elements(List) when is_list(List) ->
    [process_config_elements(Element) || Element <- List];
process_config_elements(Element) -> Element.
