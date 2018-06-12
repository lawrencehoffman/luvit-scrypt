-------------------------------------------------------------------------------
-- File: scrypt.lua
-- Author: Lawrence Hoffman <0xb000dead@block-g.com>
--
-- Description: FFI interface to libscrypt for lua
-- 
-- Credits:
--   
--   * Credit for the scrypt algorithm goes to its authors, more information 
--     about scrypt can be found at http://http://www.tarsnap.com/scrypt.html
--
--   * Credit for the C libscrypt library goes to technion@lolware.net, at the
--     time of this writing the source code for libscrypt can be found at
--     https://github.com/technion/libscrypt
-------------------------------------------------------------------------------

local ffi = require 'ffi'
ffi.cdef[[

int libscrypt_scrypt(const uint8_t *, size_t, const uint8_t *, size_t, uint64_t,
    uint32_t, uint32_t, /*@out@*/ uint8_t *, size_t);

int libscrypt_mcf(uint32_t N, uint32_t r, uint32_t p, const char *salt,
	const char *hash, char *mcf);

int libscrypt_salt_gen(uint8_t *rand, size_t len);

int libscrypt_hash(char *dst, const char* passphrase, uint32_t N, uint8_t r,
  uint8_t p);

int libscrypt_check(char *mcf, const char *password);

]]

-- Load the local copy of libscrypt
local scrypt = ffi.load("scrypt")

-------------------------------------------------------------------------------
-- Function: hash
--
-- This is the most basic way to use this library. This sets N, r, and p to the 
-- "sane" constants described in libscrypt for those values. The returned value 
-- is in standard MCF form, and will include a 128 bit salt, N, r, and p 
-- values, as well as the BASE64 encoded hash.
--
-- TODO: Learn how to deal with errno in luajit-ffi, check for errors
-- 
-- Returns: 128b MCF string on success, nil on error
-------------------------------------------------------------------------------
local function hash(passphrase)
  local N, r, p = 16384, 8, 16
  local buf = ffi.new("char[?]", 128)
  local res = scrypt.libscrypt_hash(buf, passphrase, N, r, p)
  if res == 0 then return nil end
  return(ffi.string(buf, 128))
end

-------------------------------------------------------------------------------
-- Function: check
--
-- Part 2 of the most basic way to use the scrypt library. Given the MCF which
-- has been generated by this library's hash function, check to see if the 
-- passphrase handed in hashes equal.
--
-- Returns: true if the password matches, false if not, nil on error
-------------------------------------------------------------------------------
local function check(mcf, passphrase)
  local cmcf = ffi.new("char[?]", #mcf)
  ffi.copy(cmcf, mcf)
  local res = scrypt.libscrypt_check(cmcf, passphrase)
  if res == 0 then return false end
  if res > 0 then return true end
  return nil
end

return {
  check = check,
  hash = hash
}