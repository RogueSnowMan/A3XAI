#define RADIO_ITEM "ItemRadio"
#define PLAYER_UNITS "Exile_Unit_Player"

private ["_unitGroup","_vehicle","_canCall"];
_unitGroup = _this select 0;

if (_unitGroup getVariable ["EnemiesIgnored",false]) then {[_unitGroup,"Behavior_Reset"] call A3XAI_forceBehavior};

_vehicle = _unitGroup getVariable ["assignedVehicle",objNull];
_canCall = true;

if (A3XAI_debugLevel > 1) then {diag_log format ["A3XAI Debug: Group %1 %2 detection start.",_unitGroup,(typeOf (_vehicle))];};

if ((diag_tickTime - (_unitGroup getVariable ["UVLastCall",-A3XAI_UGVCallReinforceCooldown])) > A3XAI_UGVCallReinforceCooldown) then {
	_detectStartPos = getPosATL _vehicle;
	
	while {!(_vehicle getVariable ["vehicle_disabled",false]) && {(_unitGroup getVariable ["GroupSize",-1]) > 0} && {local _unitGroup}} do {
		private ["_detected","_detectOrigin","_startPos","_vehPos","_nearNoAggroAreas","_playerPos","_canReveal"];
		_vehPos = getPosATL _vehicle;
		_startPos = getPosATL _vehicle;
		_canReveal = !((combatMode _unitGroup) isEqualTo "BLUE");
		_detectOrigin = [_startPos,0,getDir _vehicle,1] call SHK_pos;
		_detected = _detectOrigin nearEntities [[PLAYER_UNITS,"LandVehicle"],250];
		if ((count _detected) > 5) then {_detected resize 5};
		_nearNoAggroAreas = if (_detected isEqualTo []) then {[]} else {A3XAI_noAggroAreas};
		{
			_playerPos = getPosATL _x;
			if ((isPlayer _x) && {({if (_playerPos in _x) exitWith {1}} count _nearNoAggroAreas) isEqualTo 0}) then {
				if (((lineIntersectsSurfaces [(aimPos _vehicle),(eyePos _x),_vehicle,_x,true,1]) isEqualTo []) && {A3XAI_UGVDetectChance call A3XAI_chance}) then {
					if (_canCall) then {
						if (isDedicated) then {
							_nul = [_playerPos,_x,_unitGroup getVariable ["unitLevel",0]] spawn A3XAI_spawn_reinforcement;
						} else {
							A3XAI_spawnReinforcements_PVS = [_playerPos,_x,_unitGroup getVariable ["unitLevel",0]];
							publicVariableServer "A3XAI_spawnReinforcements_PVS";
						};
						_unitGroup setVariable ["UVLastCall",diag_tickTime];
						_canCall = false;
					};
					if (_canReveal && {(_unitGroup knowsAbout _x) < 2}) then {
						_unitGroup reveal [_x,2.5]; 
						if (({if (RADIO_ITEM in (assignedItems _x)) exitWith {1}} count (units (group _x))) > 0) then {
							[_x,[51+(floor (random 5)),[_unitGroup,[configFile >> "CfgVehicles" >> (typeOf _vehicle),"displayName",""] call BIS_fnc_returnConfigEntry]]] call A3XAI_radioSend;
						};
					};
				};
			};
			uiSleep 0.1;
		} forEach _detected;
		if (((_vehicle distance _detectStartPos) > 300) or {_vehicle getVariable ["vehicle_disabled",false]}) exitWith {};
		uiSleep 15;
	};
};

if (A3XAI_debugLevel > 1) then {diag_log format ["A3XAI Debug: Group %1 %2 detection end.",_unitGroup,(typeOf (_vehicle))];};
