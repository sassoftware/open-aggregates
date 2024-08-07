-- ================================================================================================================
-- Copyright © 2024, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
--
-- Description: Declaration of helper functions and aggregates for calculating m3 and m4
-- ================================================================================================================

-- Declaration for aggregate that calculates m3 and accompanying helper functions
delimiter //
create or replace function sas_m_three_init()
returns record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint) as
declare
  COPYRIGHT VARCHAR(255) = "Copyright 2024, SAS Institute Inc., Cary, NC, USA.";
begin
  return row(0, 0, 0, 0, 0, 0, 0);
end //
delimiter ;

delimiter //
create or replace function sas_m_three_iter (
  r record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint),
  value double
)
returns record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint) as
declare
  COPYRIGHT VARCHAR(255) = "Copyright 2024, SAS Institute Inc., Cary, NC, USA.";
  distance double;
begin
  if value is null then
    return r;
  end if;
  if r.c = 0 then
  -- Moments are all 0 because they are themselves the center
    return row(value, 1, 0, 0, 0, value, 0);
  end if;
  distance = value - r.center;
  return row (
    r.s + value,
    r.c + 1,
    r.m1 + distance,
    r.m2 + (distance * distance),
    r.m3 + (distance * distance * distance),
    r.center,
    0);
end //
delimiter ;

delimiter //
create or replace function sas_m_three_merge (
  state1 record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint),
  state2 record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint)
)
returns record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint) as
declare
  COPYRIGHT VARCHAR(255) = "Copyright 2024, SAS Institute Inc., Cary, NC, USA.";
  new_mean double;
  diff double;
  new_src_m1 double;
  new_src_m2 double;
  new_src_m3 double;
  new_dst_m1 double;  
  new_dst_m2 double;
  new_dst_m3 double;
  state1_copy record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint) = state1;
  state2_copy record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint) = state2;
begin
  -- Finalize state1 
  if state1_copy.final = 0 and state1_copy.c > 1 then
    new_mean = state1_copy.s / state1_copy.c;
    diff = state1_copy.center - new_mean;
    state1_copy.center = new_mean;
    state1_copy.m3 = state1_copy.m3 + diff * (3.0 * state1_copy.m2 + diff * ((3.0 * state1_copy.m1) + (diff * state1_copy.c)));
    state1_copy.m2 = state1_copy.m2 + diff * ((2.0 * state1_copy.m1) + (diff * state1_copy.c));
    state1_copy.m1 = state1_copy.m1 + diff * state1_copy.c;
  end if;
  -- Finalize state2
  if state2_copy.final = 0 and state2_copy.c > 1 then
    new_mean = state2_copy.s / state2_copy.c;
    diff = state2_copy.center - new_mean;
    state2_copy.center = new_mean;
    state2_copy.m3 = state2_copy.m3 + diff * (3.0 * state2_copy.m2 + diff * ((3.0 * state2_copy.m1)+ (diff * state2_copy.c)));
    state2_copy.m2 = state2_copy.m2 + diff * ((2.0 * state2_copy.m1 )+ (diff * state2_copy.c));
    state2_copy.m1 = state2_copy.m1 + diff * state2_copy.c;
  end if;
  state2_copy.final = 1;
  state1_copy.final = 1;
  -- Return early if either count is 0
  if state1_copy.c = 0 then
    return state2_copy;
  elsif state2_copy.c = 0 then
    return state1_copy;
  end if;
  -- Merge the two inputs
  new_mean = (state1_copy.s + state2_copy.s) / (state1_copy.c + state2_copy.c);
  diff = (state1_copy.s / state1_copy.c) - new_mean;
  new_src_m1 = state1_copy.m1 + (diff * state1_copy.c);
  new_src_m2 = state1_copy.m2 + (diff * (2.0 * state1_copy.m1 + diff * state1_copy.c));
  new_src_m3 = state1_copy.m3 + (diff * (3.0 * state1_copy.m2 + diff * ((3.0 * state1_copy.m1) + (diff * state1_copy.c))));
  diff = (state2_copy.s / state2_copy.c) - new_mean;
  new_dst_m1 = state2_copy.m1 + (diff * state2_copy.c);
  new_dst_m2 = state2_copy.m2 + (diff * (2.0 * state2_copy.m1 + diff * state2_copy.c));
  new_dst_m3 = state2_copy.m3 + (diff * (3.0 * state2_copy.m2 + diff * ((3.0 * state2_copy.m1 ) + (diff * state2_copy.c))));
  return row (
    state1_copy.s + state2_copy.s,
    state1_copy.c + state2_copy.c,
    new_src_m1 + new_dst_m1,
    new_src_m2 + new_dst_m2,
    new_src_m3 + new_dst_m3,
    new_mean,
    1);
end //
delimiter ;

delimiter //
create or replace function sas_m_three_term (
  r record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint)
)
returns  DOUBLE as
declare
  COPYRIGHT VARCHAR(255) = "Copyright 2024, SAS Institute Inc., Cary, NC, USA.";
  new_mean double;
  diff double;
  m3 double = r.m3;
begin
  -- Finalize state -- Note that if r.c == 1, m3 == r.m3 because diff == 0
  if r.final = 0 and r.c > 1 then
    new_mean = r.s / r.c;
    diff = r.center - new_mean;
    m3 = m3 + diff * (3.0 * r.m2 + diff * ((3.0 * r.m1) + (diff * r.c)));
  end if;
  return m3;
end //
delimiter ;

create or replace aggregate sas_m_three_udaf(double) returns DOUBLE
  with state record(s double, c bigint, m1 double, m2 double, m3 double, center double, final smallint)
  initialize with sas_m_three_init
  iterate with sas_m_three_iter
  merge with sas_m_three_merge
  terminate with sas_m_three_term;
  
-- Declaration for aggregate that calculates both m3 and m4 and accompanying helper functions

delimiter //
create or replace function sas_m_three_m_four_init()
returns record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint) as
declare
  COPYRIGHT VARCHAR(255) = "Copyright 2024, SAS Institute Inc., Cary, NC, USA.";
begin
  return row(0, 0, 0, 0, 0, 0, 0, 0);
end //
delimiter ;

delimiter //
create or replace function sas_m_three_m_four_iter (
  r record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint),
  value double
)
returns record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint) as
declare
  COPYRIGHT VARCHAR(255) = "Copyright 2024, SAS Institute Inc., Cary, NC, USA.";
  distance double;
begin
  if value is null then
    return r;
  end if;
  if r.c = 0 then
    -- Distance from center of the first value will always be 0 because it is the initial center estimate
    return row(value, 1, 0, 0, 0, 0, value, 0);
  end if;
  distance = (value - r.center);
  return row (
    r.s + value,
    r.c + 1,
    r.m1 + distance,
    r.m2 + (distance * distance),
    r.m3 + (distance * distance * distance),
    r.m4 + (distance * distance * distance * distance),
    r.center,
    0);
end //
delimiter ;

delimiter //
create or replace function sas_m_three_m_four_merge (
  state1 record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint),
  state2 record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint)
)
returns record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint) as
declare
  COPYRIGHT VARCHAR(255) = "Copyright 2024, SAS Institute Inc., Cary, NC, USA.";
  new_mean double;
  diff double;
  new_src_m1 double;
  new_src_m2 double;
  new_src_m3 double;
  new_src_m4 double;
  new_dst_m1 double;  
  new_dst_m2 double;
  new_dst_m3 double;
  new_dst_m4 double;
  state1_copy record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint) = state1;
  state2_copy record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint) = state2;
begin
  -- Finalize state1
  if state1_copy.final = 0 and state1_copy.c > 1 then
    new_mean = state1_copy.s / state1_copy.c;
    diff = state1_copy.center - new_mean;
    state1_copy.center = new_mean;
    state1_copy.m4 = state1_copy.m4 + diff * (4.0 * state1_copy.m3 + diff * (6.0 * state1_copy.m2 + diff * (4.0 * state1_copy.m1 + diff * state1_copy.c)));
    state1_copy.m3 = state1_copy.m3 + diff * (3.0 * state1_copy.m2 + diff * (3.0 * state1_copy.m1 + diff * state1_copy.c));
    state1_copy.m2 = state1_copy.m2 + diff * (2.0 * state1_copy.m1 + diff * state1_copy.c);
    state1_copy.m1 = state1_copy.m1 + diff * state1_copy.c;
  end if;
  -- Finalize state2
  if state2_copy.final = 0 and state2_copy.c > 1 then
    new_mean = state2_copy.s / state2_copy.c;
    diff = state2_copy.center - new_mean;
    state2_copy.center = new_mean;
    state2_copy.m4 = state2_copy.m4 + diff * (4.0 * state2_copy.m3 + diff * (6.0 * state2_copy.m2 + diff * (4.0 * state2_copy.m1 + diff * state2_copy.c)));
    state2_copy.m3 = state2_copy.m3 + diff * (3.0 * state2_copy.m2 + diff * (3.0 * state2_copy.m1 + diff * state2_copy.c));
    state2_copy.m2 = state2_copy.m2 + diff * (2.0 * state2_copy.m1 + diff * state2_copy.c);
    state2_copy.m1 = state2_copy.m1 + diff * state2_copy.c;
  end if;
  state2_copy.final = 1;
  state1_copy.final = 1;
  -- Return early if either count is 0
  if state1_copy.c = 0 then
    return state2_copy;
  elsif state2_copy.c = 0 then
    return state1_copy;
  end if;
  -- Merge the two inputs
  new_mean = (state1_copy.s + state2_copy.s) / (state1_copy.c + state2_copy.c);
  diff = (state1_copy.s / state1_copy.c) - new_mean;
  new_src_m1 = state1_copy.m1 + (diff * state1_copy.c);
  new_src_m2 = state1_copy.m2 + (diff * (2.0 * state1_copy.m1 + diff * state1_copy.c));
  new_src_m3 = state1_copy.m3 + (diff * (3.0 * state1_copy.m2 + diff * (3 * state1_copy.m1 + diff * state1_copy.c)));
  new_src_m4 = state1_copy.m4 + (diff * (4.0 * state1_copy.m3 + diff * (6 * state1_copy.m2 + diff * (4 * state1_copy.m1 + diff * state1_copy.c))));
  
  diff = (state2_copy.s / state2_copy.c) - new_mean;
  new_dst_m1 = state2_copy.m1 + (diff * state2_copy.c);
  new_dst_m2 = state2_copy.m2 + (diff * (2.0 * state2_copy.m1 + diff * state2_copy.c));
  new_dst_m3 = state2_copy.m3 + (diff * (3.0 * state2_copy.m2 + diff * (3 * state2_copy.m1 + diff * state2_copy.c)));
  new_dst_m4 = state2_copy.m4 + (diff * (4.0 * state2_copy.m3 + diff * (6 * state2_copy.m2 + diff * (4 * state2_copy.m1 + diff * state2_copy.c))));
  
  return row (
    state1_copy.s + state2_copy.s,
    state1_copy.c + state2_copy.c,
    new_src_m1 + new_dst_m1,
    new_src_m2 + new_dst_m2,
    new_src_m3 + new_dst_m3,
    new_src_m4 + new_dst_m4,
    new_mean,
    1);
end //
delimiter ;

delimiter //
create or replace function sas_m_three_m_four_term (
  r record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint)
)
returns JSON as
declare
  COPYRIGHT VARCHAR(255) = "Copyright 2024, SAS Institute Inc., Cary, NC, USA.";
  new_mean double;
  diff double;
  m4 double = r.m4;
  m3 double = r.m3;
begin
   -- Finalize state -- Note that if r.c == 1, m3 == r.m3 because diff == 0
  if r.final = 0 and r.c > 1 then
    new_mean = r.s / r.c;
    diff = r.center - new_mean;
    m4 = m4 + diff * (4.0 * m3 + diff * (6.0 * r.m2 + diff * (4.0 * r.m1 + diff * r.c)));
    m3 = m3 + diff * (3.0 * r.m2 + diff * (3.0 * r.m1 + diff * r.c));
  end if;
  return TO_JSON(ROW(m3, m4):>RECORD(m3 double, m4 double)) AS RowOutput;
end //
delimiter ;

create or replace aggregate sas_m_three_m_four_udaf(double) returns JSON
  with state record(s double, c bigint, m1 double, m2 double, m3 double, m4 double, center double, final smallint)
  initialize with sas_m_three_m_four_init
  iterate with sas_m_three_m_four_iter
  merge with sas_m_three_m_four_merge
  terminate with sas_m_three_m_four_term;

-- Small snippet to verify aggregates were added and run

show aggregates;

select sas_m_three_udaf(1), sas_m_three_m_four_udaf(1) from dual;