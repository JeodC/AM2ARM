/// @description  wrap(variable, min, max)
function wrap(argument0, argument1, argument2) {

	if (argument0 < argument1) return argument2;
	else if (argument0 > argument2) return argument1;
	else return argument0;



}
