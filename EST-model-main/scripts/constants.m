% Script defining constants, specifically the "units" dictionary.

global unit;
unit = containers.Map;

% time
unit("s")    = 1.;
unit("min")  = 60*unit("s");
unit("h")    = 60*unit("min");
unit("day")  = 24*unit("h");
unit("year") = 365*unit("day");

% energy
unit("J")  = 1.;
unit("kJ") = 1000*unit("J");
unit("MJ") = 1000*unit("kJ");
unit("GJ") = 1000*unit("MJ");

% power
unit("W")  = unit("J")/unit("s");
unit("kW") = 1000*unit("W");
unit("MW") = 1000*unit("kW");
unit("GW") = 1000*unit("MW");

% energy (Wh)
unit("Wh")  = unit("W") *unit("h");
unit("kWh") = unit("kW")*unit("h");
unit("MWh") = unit("MW")*unit("h");
unit("GWh") = unit("GW")*unit("h");

% pressure
unit("Pa")  = 1.;
unit("kPa") = 1000*unit("Pa");
unit("MPa") = 1000*unit("kPa");
unit("bar") = 1e5*unit("Pa");

% temperature
unit("K") = 1.;

% mass
unit("kg") = 1.;

% length, area, volume
unit("m")   = 1.;
unit("m^2") = 1.;
unit("m^3") = 1.;
unit("km") = 1000*unit("m");
%Electricity
unit("V") = 1.;
unit("kV") = 1000*unit("V");
unit("Ohm") = 1.;
unit("mOhm") = 1/1000*unit("Ohm");
