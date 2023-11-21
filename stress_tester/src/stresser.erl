-module(stresser).
-export([start_all/2]).
-compile(export_all).

start_tracker()->
	Initial_time = os:system_time(millisecond),
	Tracker_pid = spawn(stresser,track_times,[{Initial_time,Initial_time,0}]),
	register(tracker,Tracker_pid).

transactions_per_second()->
	tracker ! {self(),get},
	receive
		{Initial_time,Last_time,Count}=Result -> io:format("~p transactions/second~n",[Count* 1000 / (Last_time - Initial_time)]);
		Oops->io:format("Error: got ~p~n",[Oops])
	end.

track_times({Initial_time,Stored_latest_time,Count}=State)->
	Next_state = receive
		update -> {Initial_time,os:system_time(millisecond),Count+1};
		{Pid,get} -> Pid ! State,%Count/(Stored_latest_time - Initial_time),
					 State %reuse the same state
	end,
	track_times(Next_state).



%%
%% Each package will go through 10 facility-to-vehicle changes.
%% Each of these 10 vehicles will go through 1,000 location changes.
%%
start_all(Package_count,Domain)->
	Tester_name = cool_guy,
	Http_info = {post %request type
	 ,string:concat("https://",Domain)%URL
     ,[]%Header
     ,"application/json"%Type
	,[]
    %  ,[{ssl, [{customize_hostname_check, 
    %             [{match_fun, public_key:pkix_verify_hostname_match_fun(https)}]}]}]%HttpOptions
     ,[]},%Options

	build_and_spawn_all(Domain,Tester_name,Package_count,Http_info).

build_and_spawn_all(Domain,Tester_name,Package_count,Http_info)->
	%build all the requests
	Package_uuids = [data:generate_UUID(Domain,Tester_name) || _ <- lists:seq(1,Package_count)],



	Package_updates = data:build_package_updates(Package_uuids,1000),
	Location_updates = data:build_location_updates(Package_uuids,1000),
	Package_location_requests = data:build_package_location_requests(Package_uuids,1000),
	Delivered_requests = data:build_mark_delivereds(Package_uuids,1000),
	
	%start the tracker
	start_tracker(),

	%spawn all the requests
	spawn_package_updates(Package_updates,Http_info),
	spawn_package_location_updates(Location_updates, Http_info),
	spawn_package_location_requests(Package_location_requests,Http_info),
	spawn_delivered_requests(Delivered_requests,Http_info).



spawn_package_updates(Package_updates,Http_info)->
	[spawn(fun()-> send(Update,Http_info,"/pkg_upd") end) || Update <- Package_updates].

spawn_package_location_updates(Location_reports,Http_info)->
	[spawn(fun()-> send(Report,Http_info,"/rpt_loc") end) || Report <- Location_reports].

spawn_package_location_requests(Package_location_requests,Http_info)->
	[spawn(fun()-> send(Request,Http_info,"/pkg_loc") end) || Request <- Package_location_requests].

spawn_delivered_requests(Delivered_requests,Http_info)->
	[spawn(fun()-> send(Request,Http_info,"/delivered") end) || Request <- Delivered_requests].





send(Body,{Method,URL,Header,Type,HTTPOptions,Options},URL_extension)->
	%make the request and ignore the response
    httpc:request(Method, {string:concat(URL,URL_extension), Header, Type, jsx:encode(Body)}, [{timeout, timer:seconds(60)}] ++ HTTPOptions, Options),
    %update the tracker when a response is received
    tracker ! update.



