%%
%% @author Daniel Goertzen <daniel.goertzen@gmail.com>
%% @copyright 2012 Daniel Goertzen
%% %@license See file /LICENSE
%%
%% @doc Minimal schema implementing the Failsafe Schema as per Yaml 1.2 section 10.1.
%%
%% Schemas perform 2 tasks; tag resolution and value construction.
%%
%% For tag resolution the schema module produces a fully resolved tag for every node in the document.
%% This is typically done by examining the tag provided in the yaml document, or when no tag is present, by
%% inferring the tag based on the value of the node.
%%
%% For value construction the schema module produces an erlang term given the value and previously
%% resolved tag.
%%
%% All tags and values provided as parameters are utf8 binaries regardless of the actual encoding of
%% the yaml file.  The parser will automatically convert tags of the form "!!xxx" to
%% "tag:yaml.org,2002:xxx".
%%

-module(yaml_schema_failsafe).

-behaviour(yaml_schema).

-export([init/1, destroy/1]).
-export([resolve_mapping_tag/3, resolve_sequence_tag/3, resolve_scalar_tag/4]).
-export([construct_mapping/3, construct_sequence/3, construct_scalar/3]).
-export([marshal/2]).

%% @doc Initialize state that will be made available to all schema calls.
%% Put things like precompiled regular expressions and settings gleaned from the proplist.
%% Use of this state variable is optional; you may just return a dummy value if your schema is simple.
-spec init(Opts::proplists:proplist()) -> term().
init(_Opts) -> no_state.

%% @doc Destroy the schema's state.
-spec destroy(term()) -> term().
destroy(_State) -> ok.

%% @doc Resolve a mapping tag.  Return nomatch if the tag is invalid.
-spec resolve_mapping_tag( Tag::null | binary(), Value::binary(), State::term() ) ->
		  {ok, ResolvedTag::term()} | nomatch.
resolve_mapping_tag(Tag, _Value, _State) -> resolve_mapping_tag(Tag).

resolve_mapping_tag(<<"!">>)                     -> {ok, 'tag:yaml.org,2002:map'};
resolve_mapping_tag(<<"tag:yaml.org,2002:map">>) -> {ok, 'tag:yaml.org,2002:map'};
resolve_mapping_tag(null)                        -> {ok, 'tag:yaml.org,2002:map'};
resolve_mapping_tag(_)                           -> nomatch.

%% @doc Construct a mapping.  Return nomatch if the tag is invalid.
-spec construct_mapping(ResolvedTag::term(), Value::binary(), State::term()) ->
		  {ok, ConstructedValue::term()} | nomatch.
construct_mapping('tag:yaml.org,2002:map', Value, _State) -> {ok, Value};
construct_mapping(_, _, _State) -> nomatch.


%% @doc Resolve a sequence tag.  Return nomatch if the tag is invalid.
-spec resolve_sequence_tag( Tag::null | binary(), Value::binary(), State::term() ) ->
		  {ok, ResolvedTag::term()} | nomatch.
resolve_sequence_tag(Tag, _Value, _State) -> resolve_sequence_tag(Tag).
resolve_sequence_tag(<<"!">>)                     -> {ok, 'tag:yaml.org,2002:seq'};
resolve_sequence_tag(<<"tag:yaml.org,2002:seq">>) -> {ok, 'tag:yaml.org,2002:seq'};
resolve_sequence_tag(null)                        -> {ok, 'tag:yaml.org,2002:seq'};
resolve_sequence_tag(_)                           -> nomatch.

%% @doc Construct a sequence.  Return nomatch if the tag is invalid.
-spec construct_sequence(ResolvedTag::term(), Value::binary(), State::term()) ->
		  {ok, ConstructedValue::term()} | nomatch.
construct_sequence('tag:yaml.org,2002:seq', Value, _State) -> {ok, Value};
construct_sequence(_, _, _State) -> nomatch.

%% @doc Resolve a scalar tag.  Return nomatch if the tag is invalid.
-spec resolve_scalar_tag( Tag::null | binary(), Value::binary(), Style::yaml_libyaml:scalar_style(), State::term() ) ->
		  {ok, ResolvedTag::term()} | nomatch.
resolve_scalar_tag(Tag, _Value, _Style, _State) -> resolve_scalar_tag(Tag).
resolve_scalar_tag(<<"!">>)                     -> {ok, 'tag:yaml.org,2002:str'};
resolve_scalar_tag(<<"tag:yaml.org,2002:str">>) -> {ok, 'tag:yaml.org,2002:str'};
resolve_scalar_tag(null)                        -> {ok, 'tag:yaml.org,2002:str'};
resolve_scalar_tag(_)                           -> nomatch.

%% @doc Construct a scalar.  Return nomatch if the tag is invalid.
-spec construct_scalar(ResolvedTag::term(), Value::binary(), State::term()) ->
		  {ok, ConstructedValue::term()} | nomatch.
construct_scalar('tag:yaml.org,2002:str', Value, _State) -> {ok, Value};
construct_scalar(_, _, _State) -> nomatch.

marshal(List, State) when is_list(List) ->
  case io_lib:printable_list(List) of
    true -> marshal_scalar(List, State);
    _ -> case is_map_list(List) of
      true -> {map, List, null};
      _ -> {sequence, List, null}
    end
  end;
marshal(Object, State) -> marshal_scalar(Object, State).

marshal_scalar(Binary, _State) when is_binary(Binary) -> {scalar, Binary, null, any};
marshal_scalar(List, State) when is_list(List) -> marshal_scalar(list_to_binary(List), State);
marshal_scalar(Integer, State) when is_integer(Integer) -> marshal_scalar(integer_to_list(Integer), State);
marshal_scalar(Float, State) when is_float(Float) -> marshal_scalar(io_lib:format("~p", [Float]), State).

is_map_list(List) ->
  lists:all(fun
    ({_, _}) -> true;
    (_) -> false
  end, List).
