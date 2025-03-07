-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- init script embedded at compile time.  executed in
-- zen_load_extensions(L) usually after zen_init()

-- -- remap fatal and error
function fatal(msg)
	  if type(msg) == "string" then warn(trim(msg),2) end
	  debug.traceback()
--	  if ZEN_traceback ~= "" then ZEN:debug() end
	  ZEN:debug()
	  msg = msg or "fatal error"
	  error(msg,2)
end

-- error = zen_error -- from zen_io

-- ZEN = { assert = assert } -- zencode shim when not loaded
require('zenroom_common')
INSIDE = require('inspect')
OCTET  = require('zenroom_octet')
JSON   = require('zenroom_json')
ECDH   = require('zenroom_ecdh')
BIG    = require('zenroom_big')
HASH   = require('zenroom_hash')
MACHINE = require('statemachine')

O   = OCTET  -- alias
INT = BIG    -- alias
H   = HASH   -- alias
I   = INSIDE -- alias
V   = require('semver')
VERSION = V(VERSION)

ZEN = require('zencode')

-- import/export schema helpers
require('zencode_schemas')
-- base data functions
require('zencode_data')

-- scenarios can only implement "When ..." steps
_G["Given"] = nil
_G["Then"]  = nil

-----------
-- defaults
_G["CONF"] = {
   -- goldilocks is our favorite ECDH/DSA curve
   curve = 'goldilocks',
   verbosity = 1
}
-- encoding base64url (RFC4648) is the fastest and most portable in zenroom
set_encoding('url64')
