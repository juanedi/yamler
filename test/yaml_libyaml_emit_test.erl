-module(yaml_libyaml_emit_test).
-include_lib("eunit/include/eunit.hrl").

-define(DOC_PRE, [{stream_start, {}}, {document_start, {}}]).
-define(DOC_POST, [{document_end, {}}, {stream_end, {}}]).
-define(DOC(Elements), ?DOC_PRE ++ Elements ++ ?DOC_POST).
-define(SEQ(Elements), [{sequence_start, {null, null, any}}] ++ Elements ++ [{sequence_end}]).
-define(MAP(Elements), [{mapping_start, {null, null, any}}] ++ Elements ++ [{mapping_end}]).

scalar_test_() ->
  [
    fun() ->
      Yaml = yaml_libyaml:libyaml_emit(?DOC([Scalar])),
      ?assertEqual(Expected, Yaml)
    end ||
    {Scalar, Expected} <- [
      {{scalar, {null, null, <<"foo">>, any}}, <<"--- foo\n...\n">>},
      {{scalar, {null, null, <<"123">>, single_quoted}}, <<"--- '123'\n...\n">>},
      {{scalar, {null, <<"!foo">>, <<"foo">>, any}}, <<"--- !foo foo\n...\n">>}
    ]
  ].

sequence_test_() ->
  [
    fun() ->
      Yaml = yaml_libyaml:libyaml_emit(?DOC(?SEQ(Elements))),
      ?assertEqual(Expected, Yaml)
    end ||
    {Elements, Expected} <- [
      {[], <<"--- []\n...\n">>},
      {[
        {scalar, {null, null, <<"foo">>, any}},
        {scalar, {null, null, <<"bar">>, any}}
      ], <<"---\n- foo\n- bar\n...\n">>},
      {?SEQ(?SEQ([{scalar, {null, null, <<"foo">>}}])), <<"---\n- - - foo\n...\n">>}
    ]
  ].

map_test_() ->
  [
    fun() ->
      Yaml = yaml_libyaml:libyaml_emit(?DOC(?MAP(Elements))),
      ?assertEqual(Expected, Yaml)
    end ||
    {Elements, Expected} <- [
      {[], <<"--- {}\n...\n">>},
      {[
        {scalar, {null, null, <<"foo">>, any}},
        {scalar, {null, null, <<"bar">>, any}}
      ], <<"---\nfoo: bar\n...\n">>},
      {?MAP([]) ++ ?MAP([]), <<"---\n{}: {}\n...\n">>}
    ]
  ].