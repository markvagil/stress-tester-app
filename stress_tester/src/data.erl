-module(data).
-export([build_mark_delivereds/2,build_package_location_requests/2,build_package_updates/2,
	build_location_updates/2,
	generate_UUID/2]).


time_in_millis() ->
  {Mega, Sec, Micro} = os:timestamp(),
  (Mega*1000000 + Sec)*1000 + round(Micro/1000).

 

generate_UUID(Domain,Tester_name)->
	uuid:to_string(uuid:uuid5(dns,Domain++atom_to_list(Tester_name)++integer_to_list(erlang:monotonic_time()))).




build_mark_delivereds(Package_UUIDs,Count) ->
	lists:flatten([[#{uuid => list_to_binary(Package_UUID),time => list_to_binary(integer_to_list(time_in_millis())),
										lat => list_to_binary(integer_to_list(round(rand:uniform_real()*360))),
										long => list_to_binary(integer_to_list(round(rand:uniform_real()*360)))} || Package_UUID <- Package_UUIDs]
		|| _ <- lists:seq(1,Count)]).

build_package_location_requests(Package_UUIDs,Count)->
	lists:flatten([[#{uuid => UUID}
								|| UUID <- Package_UUIDs] || _ <- lists:seq(1,Count)]).


build_package_updates(Package_UUIDs,Count)->
	lists:flatten([[#{pkg_uuid => list_to_binary(Package_UUID),
		 	loc_uuid => list_to_binary(generate_UUID("someLocation.blah",not_real_location)),
			time => list_to_binary(integer_to_list(round((rand:uniform_real()*1_000_000))))}
		|| Package_UUID <- Package_UUIDs] || _ <- lists:seq(1,Count)]).

build_location_updates(Package_UUIDs,Count) ->
	lists:flatten([[#{
										loc_uuid => list_to_binary(generate_UUID("someLocation.blah",not_real_location)),
										lat => list_to_binary(integer_to_list(round(rand:uniform_real()*360))),
										long => list_to_binary(integer_to_list(round(rand:uniform_real()*360))),
										time => list_to_binary(integer_to_list(round((rand:uniform_real()*1_000_000))))} || Package_UUID <- Package_UUIDs]
		|| _ <- lists:seq(1,Count)]).







	

