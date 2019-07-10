%%%-------------------------------------------------------------------
%%% @author's gihub username: @cmush
%%% @author's email address: collinsmucheru
%%% @copyright (C) 2019, @SafaricomAlpha
%%% @doc
%%%
%%% @end
%%% Created : 11. Jul 2019 01:49
%%%-------------------------------------------------------------------
-author("collinsmucheru@gmail.com").

-define(APP(NameAsAtom),
    begin
        (fun() ->
            NameAsAtom
         end)()
    end).


